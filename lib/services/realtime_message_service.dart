import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class RealtimeMessageService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 실시간 메시지 스트림 컨트롤러
  final Map<String, StreamController<List<MessageModel>>> _messageStreams = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};
  
  // 타이핑 상태 스트림 컨트롤러
  final Map<String, StreamController<Map<String, bool>>> _typingStreams = {};
  final Map<String, StreamSubscription<DocumentSnapshot>> _typingSubscriptions = {};
  
  // 메시지 캐시
  final Map<String, List<MessageModel>> _messageCache = {};
  final int _maxCacheSize = 100;

  @override
  void onInit() {
    super.onInit();
    _initializeAuthListener();
  }

  @override
  void onClose() {
    _disposeAllStreams();
    super.onClose();
  }

  // 인증 상태 리스너 초기화
  void _initializeAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _disposeAllStreams();
        _clearCache();
      }
    });
  }

  // 모든 스트림 정리
  void _disposeAllStreams() {
    for (final controller in _messageStreams.values) {
      controller.close();
    }
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _typingStreams.values) {
      controller.close();
    }
    for (final subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    
    _messageStreams.clear();
    _messageSubscriptions.clear();
    _typingStreams.clear();
    _typingSubscriptions.clear();
  }

  // 캐시 정리
  void _clearCache() {
    _messageCache.clear();
  }

  // 메시지 스트림 시작
  Stream<List<MessageModel>> startMessageStream(String chatRoomId) {
    if (_messageStreams.containsKey(chatRoomId)) {
      return _messageStreams[chatRoomId]!.stream;
    }

    final controller = StreamController<List<MessageModel>>.broadcast();
    _messageStreams[chatRoomId] = controller;

    // Firestore 실시간 리스너 설정
    final subscription = _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatRoomId)
        .orderBy('createdAt', descending: true)
        .limit(_maxCacheSize)
        .snapshots()
        .listen((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList();
          
          // 캐시 업데이트
          _messageCache[chatRoomId] = messages;
          
          // 스트림에 메시지 전송
          controller.add(messages);
        });

    _messageSubscriptions[chatRoomId] = subscription;
    
    // 캐시된 메시지가 있으면 즉시 전송
    if (_messageCache.containsKey(chatRoomId)) {
      controller.add(_messageCache[chatRoomId]!);
    }

    return controller.stream;
  }

  // 메시지 스트림 중지
  void stopMessageStream(String chatRoomId) {
    final controller = _messageStreams.remove(chatRoomId);
    final subscription = _messageSubscriptions.remove(chatRoomId);
    
    controller?.close();
    subscription?.cancel();
  }

  // 타이핑 상태 스트림 시작
  Stream<Map<String, bool>> startTypingStream(String chatRoomId) {
    if (_typingStreams.containsKey(chatRoomId)) {
      return _typingStreams[chatRoomId]!.stream;
    }

    final controller = StreamController<Map<String, bool>>.broadcast();
    _typingStreams[chatRoomId] = controller;

    // 타이핑 상태 실시간 리스너 설정
    final subscription = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final typingUsers = Map<String, bool>.from(data?['typingUsers'] ?? {});
            controller.add(typingUsers);
          }
        });

    _typingSubscriptions[chatRoomId] = subscription;
    return controller.stream;
  }

  // 타이핑 상태 스트림 중지
  void stopTypingStream(String chatRoomId) {
    final controller = _typingStreams.remove(chatRoomId);
    final subscription = _typingSubscriptions.remove(chatRoomId);
    
    controller?.close();
    subscription?.cancel();
  }

  // 메시지 전송
  Future<MessageModel> sendMessage({
    required String chatRoomId,
    required String content,
    String type = 'text',
    MessageMedia? media,
    MessageReply? replyTo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      // 메시지 생성
      final message = MessageCreationHelper.createTextMessage(
        chatId: chatRoomId,
        senderId: user.uid,
        senderName: user.displayName ?? '알 수 없음',
        senderMBTI: null, // TODO: 사용자 MBTI 정보 가져오기
        content: content,
        replyTo: replyTo,
      );

      // 미디어가 있는 경우 메시지 타입과 미디어 정보 설정
      MessageModel finalMessage = message;
      if (media != null) {
        finalMessage = message.copyWith(
          type: type,
          media: media,
        );
      }

      // Firestore에 메시지 저장
      await _firestore
          .collection('messages')
          .doc(message.messageId)
          .set(finalMessage.toMap());

      // 채팅방의 마지막 메시지 업데이트
      await _updateChatRoomLastMessage(chatRoomId, finalMessage);

      // 안읽은 메시지 수 증가
      await _incrementUnreadCount(chatRoomId, user.uid);

      return finalMessage;
    } catch (e) {
      throw Exception('메시지 전송 실패: $e');
    }
  }

  // 채팅방 마지막 메시지 업데이트
  Future<void> _updateChatRoomLastMessage(String chatRoomId, MessageModel message) async {
    try {
      final lastMessage = {
        'messageId': message.messageId,
        'content': message.content,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'timestamp': message.createdAt,
        'type': message.type,
        'mediaUrl': message.media?.url,
      };

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .update({
            'lastMessage': lastMessage,
            'updatedAt': FieldValue.serverTimestamp(),
            'stats.messageCount': FieldValue.increment(1),
            'stats.lastActivity': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // 마지막 메시지 업데이트 실패는 치명적이지 않음
      print('마지막 메시지 업데이트 실패: $e');
    }
  }

  // 안읽은 메시지 수 증가
  Future<void> _incrementUnreadCount(String chatRoomId, String senderId) async {
    try {
      final chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (chatRoomDoc.exists) {
        final data = chatRoomDoc.data()!;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});

        // 발신자를 제외한 모든 참여자의 안읽은 메시지 수 증가
        for (final participantId in participantIds) {
          if (participantId != senderId) {
            unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
          }
        }

        await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .update({
              'unreadCounts': unreadCounts,
            });
      }
    } catch (e) {
      // 안읽은 메시지 수 업데이트 실패는 치명적이지 않음
      print('안읽은 메시지 수 업데이트 실패: $e');
    }
  }

  // 메시지 읽음 표시
  Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({
            'status.readBy': FieldValue.arrayUnion([user.uid]),
          });

      // 채팅방의 읽음 상태도 업데이트
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .update({
            'unreadCounts.${user.uid}': 0,
            'lastReadAt.${user.uid}': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('메시지 읽음 표시 실패: $e');
    }
  }

  // 메시지 편집
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      // 메시지 소유자 확인
      final messageDoc = await _firestore
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('메시지를 찾을 수 없습니다.');
      }

      final messageData = messageDoc.data()!;
      if (messageData['senderId'] != user.uid) {
        throw Exception('자신의 메시지만 편집할 수 있습니다.');
      }

      // 메시지 업데이트
      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({
            'content': newContent,
            'updatedAt': FieldValue.serverTimestamp(),
            'status.isEdited': true,
          });

      // 채팅방의 마지막 메시지도 업데이트
      final chatId = messageData['chatId'];
      if (chatId != null) {
        await _firestore
            .collection('chatRooms')
            .doc(chatId)
            .update({
              'lastMessage.content': newContent,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      throw Exception('메시지 편집 실패: $e');
    }
  }

  // 메시지 삭제
  Future<void> deleteMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      // 메시지 소유자 확인
      final messageDoc = await _firestore
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('메시지를 찾을 수 없습니다.');
      }

      final messageData = messageDoc.data()!;
      if (messageData['senderId'] != user.uid) {
        throw Exception('자신의 메시지만 삭제할 수 있습니다.');
      }

      // 메시지 내용을 삭제된 메시지로 변경
      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({
            'content': '삭제된 메시지입니다.',
            'updatedAt': FieldValue.serverTimestamp(),
            'status.isDeleted': true,
          });

      // 채팅방의 마지막 메시지도 업데이트
      final chatId = messageData['chatId'];
      if (chatId != null) {
        await _firestore
            .collection('chatRooms')
            .doc(chatId)
            .update({
              'lastMessage.content': '삭제된 메시지입니다.',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      throw Exception('메시지 삭제 실패: $e');
    }
  }

  // 메시지 반응 추가/제거
  Future<void> toggleMessageReaction(String messageId, String emoji) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final messageDoc = await _firestore
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) return;

      final messageData = messageDoc.data()!;
      final reactions = Map<String, List<String>>.from(messageData['reactions'] ?? {});

      if (reactions.containsKey(emoji)) {
        final users = List<String>.from(reactions[emoji]!);
        if (users.contains(user.uid)) {
          // 반응 제거
          users.remove(user.uid);
          if (users.isEmpty) {
            reactions.remove(emoji);
          } else {
            reactions[emoji] = users;
          }
        } else {
          // 반응 추가
          users.add(user.uid);
          reactions[emoji] = users;
        }
      } else {
        // 새로운 반응 추가
        reactions[emoji] = [user.uid];
      }

      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({
            'reactions': reactions,
          });
    } catch (e) {
      print('메시지 반응 처리 실패: $e');
    }
  }

  // 타이핑 상태 시작
  Future<void> startTyping(String chatRoomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .update({
            'typingUsers.${user.uid}': true,
            'typingUsers.${user.uid}_startedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('타이핑 상태 시작 실패: $e');
    }
  }

  // 타이핑 상태 종료
  Future<void> stopTyping(String chatRoomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .update({
            'typingUsers.${user.uid}': false,
            'typingUsers.${user.uid}_startedAt': FieldValue.delete(),
          });
    } catch (e) {
      print('타이핑 상태 종료 실패: $e');
    }
  }

  // 채팅방 메시지 조회
  Future<List<MessageModel>> getChatMessages({
    required String chatRoomId,
    int limit = 50,
    String? lastMessageId,
  }) async {
    try {
      List<Map<String, dynamic>> whereConditions = [
        {'field': 'chatId', 'isEqualTo': chatRoomId},
      ];

      if (lastMessageId != null) {
        final lastMessageDoc = await _firestore
            .collection('messages')
            .doc(lastMessageId)
            .get();
        
        if (lastMessageDoc.exists) {
          final lastMessage = MessageModel.fromMap(lastMessageDoc.data()!);
          whereConditions.add({
            'field': 'createdAt',
            'isLessThan': lastMessage.createdAt,
          });
        }
      }

      final query = _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatRoomId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('메시지 조회 실패: $e');
      return [];
    }
  }

  // 메시지 검색
  Future<List<MessageModel>> searchMessages({
    required String chatRoomId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatRoomId)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: query + '\uf8ff')
          .orderBy('content')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('메시지 검색 실패: $e');
      return [];
    }
  }

  // 메시지 통계 조회
  Future<Map<String, dynamic>> getMessageStats(String chatRoomId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatRoomId)
          .get();

      final messages = messagesSnapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();

      final stats = {
        'totalMessages': messages.length,
        'textMessages': messages.where((m) => m.type == 'text').length,
        'mediaMessages': messages.where((m) => m.type != 'text').length,
        'editedMessages': messages.where((m) => m.isEdited).length,
        'deletedMessages': messages.where((m) => m.isDeleted).length,
        'messagesWithReactions': messages.where((m) => m.hasReactions).length,
        'averageMessageLength': messages.isEmpty 
            ? 0.0 
            : messages.map((m) => m.content.length).reduce((a, b) => a + b) / messages.length,
      };

      return stats;
    } catch (e) {
      print('메시지 통계 조회 실패: $e');
      return {};
    }
  }

  // 오래된 메시지 정리 (자동 삭제)
  Future<void> cleanupOldMessages(String chatRoomId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final oldMessagesSnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatRoomId)
          .where('createdAt', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldMessagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('오래된 메시지 ${oldMessagesSnapshot.docs.length}개 정리 완료');
    } catch (e) {
      print('오래된 메시지 정리 실패: $e');
    }
  }
} 