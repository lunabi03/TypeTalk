import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/services/real_firebase_service.dart';
import 'package:typetalk/services/chat_invite_service.dart';
import 'package:typetalk/routes/app_routes.dart';

/// 채팅 화면 컨트롤러
/// 실시간 메시지 전송/수신 및 채팅방 관리를 담당합니다.
class ChatController extends GetxController {
  static ChatController get instance => Get.find<ChatController>();

  final AuthController authController = Get.find<AuthController>();
  final RealUserRepository _userRepository = Get.find<RealUserRepository>();
  final RealFirebaseService _firestore = Get.find<RealFirebaseService>();
  ChatInviteService? get _inviteService => Get.isRegistered<ChatInviteService>() ? Get.find<ChatInviteService>() : null;

  // 현재 채팅방 정보
  Rx<ChatModel?> currentChat = Rx<ChatModel?>(null);
  RxString chatId = ''.obs;
  
  // 내 채팅방 목록 및 검색/정렬 상태
  RxList<ChatModel> chatList = <ChatModel>[].obs;
  RxString searchQuery = ''.obs;
  RxBool sortByRecentDesc = true.obs;
  final Map<String, DateTime> _lastReadAt = {};
  
  // 메시지 목록
  RxList<MessageModel> messages = <MessageModel>[].obs;
  
  // UI 상태
  RxBool isLoading = false.obs;
  RxBool isSending = false.obs;
  
  // 텍스트 입력 컨트롤러
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadChatList();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// 현재 사용자 채팅방 목록 로드 (실제 Firestore 기준)
  Future<void> loadChatList() async {
    try {
      isLoading.value = true;
      final myId = authController.userId ?? 'current-user';
      final snapshots = await _firestore.queryDocuments(
        'chats',
        field: 'participants',
        arrayContains: myId,
        orderByField: 'stats.lastActivity',
        descending: true,
      );
      var loaded = snapshots.docs
          .map((s) => ChatModel.fromSnapshot(s))
          .toList();
      // 기본 정렬: 최근 활동 내림차순
      loaded.sort((a, b) => b.stats.lastActivity.compareTo(a.stats.lastActivity));
      chatList.assignAll(loaded);
    } catch (e) {
      print('채팅방 목록 로드 실패: $e');
      chatList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 검색/정렬 적용된 채팅 목록
  List<ChatModel> get visibleChats {
    var list = chatList.toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) =>
        c.title.toLowerCase().contains(q) ||
        (c.description?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    list.sort((a, b) => sortByRecentDesc.value
        ? b.stats.lastActivity.compareTo(a.stats.lastActivity)
        : a.stats.lastActivity.compareTo(b.stats.lastActivity));
    return list;
  }

  /// 채팅 열기
  Future<void> openChat(ChatModel chat) async {
    currentChat.value = chat;
    chatId.value = chat.chatId;
    await loadMessagesForChat(chat.chatId);
    _lastReadAt[chat.chatId] = DateTime.now();
    _scrollToBottom();
  }

  /// 메시지 목록 로드 (실제 Firestore)
  Future<void> loadMessagesForChat(String id) async {
    try {
      isLoading.value = true;
      final snapshots = await _firestore.queryDocuments(
        'messages',
        field: 'chatId',
        isEqualTo: id,
        orderByField: 'createdAt',
        descending: false,
      );
      final loaded = snapshots.docs.map((s) => MessageModel.fromSnapshot(s)).toList();
      messages.assignAll(loaded);
    } catch (e) {
      print('메시지 목록 로드 실패: $e');
      messages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 채팅별 안 읽은 개수 (데모: 마지막 메시지 시간과 마지막 읽은 시간 비교, 내 메시지는 제외)
  int getUnreadCount(ChatModel chat) {
    final lastRead = _lastReadAt[chat.chatId] ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (chat.lastMessage != null && chat.lastMessage!.timestamp.isAfter(lastRead)) {
      final myId = authController.userId ?? 'current-user';
      if (chat.lastMessage!.senderId != myId) {
        return 1;
      }
    }
    return 0;
  }

  /// 데모 채팅방 초기화 (더미데이터 제거됨)
  void _initializeDemoChat() {
    // 데모 채팅방 초기화 기능 비활성화
    // 실제 사용자와의 채팅에서는 이 기능을 사용하지 않음
    return;
  }

  /// 데모 메시지 초기화 (더미데이터 제거됨)
  void _initializeDemoMessages() {
    // 데모 메시지 초기화 기능 비활성화
    // 실제 사용자와의 채팅에서는 이 기능을 사용하지 않음
    return;
  }

  /// 선택한 사용자와 개인 채팅 시작 (초대 시스템 사용)
  Future<void> startPrivateChatWith(UserModel otherUser) async {
    final currentUserId = authController.userId ?? 'current-user';
    final otherUserId = otherUser.uid;

    try {
      // 기존 채팅방이 있는지 확인
      final existingChat = await _findExistingDirectChat(currentUserId, otherUserId);
      
      if (existingChat != null) {
        // 기존 채팅방이 있으면 바로 열기
        await openChat(existingChat);
        return;
      }

      // 기존 초대가 있는지 확인
      final inviteService = _inviteService;
      if (inviteService == null) {
        Get.snackbar(
          '오류', 
          '초대 서비스를 사용할 수 없습니다.',
          backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
          colorText: const Color(0xFFFF0000),
        );
        return;
      }
      
      final existingInvite = inviteService.findInviteToUser(otherUserId);
      if (existingInvite != null) {
        if (existingInvite.isPending) {
          Get.snackbar(
            '초대 대기 중', 
            '${otherUser.name}님에게 이미 초대를 보냈습니다. 응답을 기다려주세요.',
            backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
            colorText: const Color(0xFFFF9800),
          );
          return;
        }
      }

      // 새로운 초대 생성
      final invite = await inviteService.createDirectChatInvite(
        targetUserId: otherUserId,
        message: '안녕하세요! 대화를 나누고 싶어요.',
      );

      if (invite != null) {
        Get.snackbar(
          '초대 전송 완료', 
          '${otherUser.name}님에게 채팅 초대를 보냈습니다. 수락하면 대화를 시작할 수 있습니다.',
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
          colorText: const Color(0xFF4CAF50),
        );
      } else {
        // 기존 채팅방이 생성된 경우 바로 열기
        final newChat = await getChatById(invite?.chatId ?? '');
        if (newChat != null) {
          await openChat(newChat);
        }
      }
      
    } catch (e) {
      print('개인 채팅 시작 실패: $e');
      Get.snackbar(
        '오류', 
        '채팅 초대 전송에 실패했습니다: ${e.toString()}',
        backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
        colorText: const Color(0xFFFF0000),
      );
    }
  }

  /// 기존 1:1 채팅방 찾기
  Future<ChatModel?> _findExistingDirectChat(String user1Id, String user2Id) async {
    try {
      final snapshots = await _firestore.queryDocuments(
        'chats',
        field: 'type',
        isEqualTo: 'private',
      );

      for (final doc in snapshots.docs) {
        final chat = ChatModel.fromSnapshot(doc);
        if (chat.participants.contains(user1Id) && 
            chat.participants.contains(user2Id) &&
            chat.participants.length == 2) {
          return chat;
        }
      }
      return null;
    } catch (e) {
      print('기존 채팅방 찾기 실패: $e');
      return null;
    }
  }

  /// 채팅 ID로 채팅방 정보 가져오기
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      if (chatId.isEmpty) return null;
      
      final snapshot = await _firestore.getDocument('chats/$chatId');
      if (snapshot.exists) {
        return ChatModel.fromSnapshot(snapshot);
      }
      return null;
    } catch (e) {
      print('채팅방 정보 조회 실패: $e');
      return null;
    }
  }

  /// MBTI별 맞춤 인사말 추가 (더미데이터 제거됨)
  void _addMBTIGreeting(String? mbtiType) {
    // 더미데이터 자동 응답 기능 제거
    // 실제 사용자와의 대화에서는 이 기능을 사용하지 않음
    return;
  }

  /// 메시지 전송
  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    
    // 입력 유효성 검사
    if (content.isEmpty) {
      Get.snackbar(
        '알림',
        '메시지를 입력해주세요.',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
      );
      return;
    }
    
    if (isSending.value) return;
    
    // 채팅방이 선택되지 않은 경우
    if (currentChat.value == null) {
      Get.snackbar(
        '오류',
        '채팅방을 선택해주세요.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      isSending.value = true;

      final newMessage = MessageModel(
        messageId: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId.value,
        senderId: authController.userId ?? 'current-user',
        senderName: authController.userName ?? '나',
        senderMBTI: authController.userProfile['mbti'] ?? 'ENFP',
        content: content,
        type: MessageType.text.value,
        createdAt: DateTime.now(),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: [authController.userId ?? 'current-user'],
        ),
        reactions: {},
      );

      // 메시지 목록에 추가
      messages.add(newMessage);
      
      // 입력창 초기화
      messageController.clear();
      
      // 스크롤을 맨 아래로
      _scrollToBottom();

      // Firestore에 메시지 저장
      try {
        await _firestore.setDocument('messages/${newMessage.messageId}', newMessage.toMap());
        
        // 채팅방의 마지막 메시지 정보 업데이트
        try {
          await _firestore.updateDocument('chats/${chatId.value}', {
            'lastMessage': {
              'content': content,
              'timestamp': newMessage.createdAt.toIso8601String(),
              'senderId': newMessage.senderId,
            },
            'stats.lastActivity': newMessage.createdAt.toIso8601String(),
            'stats.messageCount': FieldValue.increment(1),
          });
        } catch (e) {
          print('채팅방 업데이트 오류: $e');
        }
        
        // 채팅 목록 새로고침
        await loadChatList();
        
      } catch (e) {
        print('Firestore 저장 오류: $e');
        // 저장 실패 시에도 UI는 유지 (사용자 경험 향상)
      }

      // 메시지 전송 완료 후 읽음 상태 업데이트
      _updateReadStatus(newMessage.messageId);

    } catch (e) {
      print('메시지 전송 오류: $e');
      Get.snackbar(
        '오류',
        '메시지 전송 중 오류가 발생했습니다.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isSending.value = false;
    }
  }





  /// 스크롤을 맨 아래로
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 메시지 시간 포맷팅
  String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  /// 내가 보낸 메시지인지 확인
  bool isMyMessage(MessageModel message) {
    return message.senderId == (authController.userId ?? 'current-user');
  }

  /// MBTI 색상 반환
  Color getMBTIColor(String? mbti) {
    if (mbti == null) return Colors.grey;
    
    switch (mbti.substring(0, 2)) {
      case 'EN':
        return const Color(0xFF6C63FF); // 보라색 - 외향적 직관
      case 'IN':
        return const Color(0xFF4ECDC4); // 청록색 - 내향적 직관
      case 'ES':
        return const Color(0xFFFF6B6B); // 빨간색 - 외향적 감각
      case 'IS':
        return const Color(0xFF45B7D1); // 파란색 - 내향적 감각
      default:
        return Colors.grey;
    }
  }

  /// 메시지 반응 추가
  void addReaction(String messageId, String reaction) {
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      final message = messages[messageIndex];
      final reactions = Map<String, List<String>>.from(message.reactions);
      
      final userId = authController.userId ?? 'current-user';
      if (reactions[reaction] == null) {
        reactions[reaction] = [];
      }
      
      if (reactions[reaction]!.contains(userId)) {
        reactions[reaction]!.remove(userId);
        if (reactions[reaction]!.isEmpty) {
          reactions.remove(reaction);
        }
      } else {
        reactions[reaction]!.add(userId);
      }
      
      messages[messageIndex] = message.copyWith(reactions: reactions);
    }
  }

  /// 채팅방 나가기
  void leaveChat() {
    currentChat.value = null;
    chatId.value = '';
    messages.clear();
    // 채팅 목록으로 돌아가기 (메인으로는 뒤로가기 버튼에서 처리)
  }

  /// 메시지 읽음 상태 업데이트
  void _updateReadStatus(String messageId) {
    try {
      // 현재 사용자 ID
      final currentUserId = authController.userId ?? 'current-user';
      
      // 메시지의 읽음 상태 업데이트
      final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
      if (messageIndex != -1) {
        final message = messages[messageIndex];
        final updatedReadBy = List<String>.from(message.status.readBy);
        if (!updatedReadBy.contains(currentUserId)) {
          updatedReadBy.add(currentUserId);
        }
        
        final updatedStatus = message.status.copyWith(readBy: updatedReadBy);
        messages[messageIndex] = message.copyWith(status: updatedStatus);
        
        // Firestore에도 업데이트
        _firestore.updateDocument('messages/$messageId', {
          'status.readBy': updatedReadBy,
        });
      }
    } catch (e) {
      print('읽음 상태 업데이트 오류: $e');
    }
  }

  /// 채팅방 설정
  void openChatSettings() {
    Get.snackbar('설정', '채팅방 설정 기능은 곧 추가될 예정입니다.');
  }

  // ============================================================================
  // 데이터 정합성 및 삭제 처리 기능
  // ============================================================================

  /// 채팅방 완전 삭제
  Future<void> deleteChatPermanently(String chatId) async {
    try {
      final currentUserId = authController.userId ?? 'current-user';
      
      // 권한 확인
      final chat = chatList.firstWhereOrNull((c) => c.chatId == chatId);
      if (chat == null) {
        Get.snackbar('오류', '채팅방을 찾을 수 없습니다.');
        return;
      }
      
      if (chat.createdBy != currentUserId) {
        Get.snackbar('오류', '채팅방 삭제 권한이 없습니다.');
        return;
      }

      // 삭제 처리
      isLoading.value = true;
      
      // 1. 채팅방의 모든 메시지 삭제
      final messageSnapshots = await _firestore.messages
          .where('chatId', isEqualTo: chatId)
          .get();
      
      for (final messageSnapshot in messageSnapshots.docs) {
        await _firestore.messages.doc(messageSnapshot.id).delete();
      }
      
      // 2. 채팅방 삭제
      await _firestore.chats.doc(chatId).delete();
      
      // 3. 로컬 데이터 정리
      chatList.removeWhere((c) => c.chatId == chatId);
      if (currentChat.value?.chatId == chatId) {
        leaveChat();
      }
      
      Get.snackbar('완료', '채팅방이 삭제되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '채팅방 삭제 실패: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// 메시지 삭제
  Future<void> deleteMessage(String messageId) async {
    try {
      final currentUserId = authController.userId ?? 'current-user';
      
      final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
      if (messageIndex == -1) {
        Get.snackbar('오류', '메시지를 찾을 수 없습니다.');
        return;
      }
      
      final message = messages[messageIndex];
      
      // 권한 확인 (메시지 발송자만 삭제 가능)
      if (message.senderId != currentUserId) {
        Get.snackbar('오류', '메시지 삭제 권한이 없습니다.');
        return;
      }

      // 소프트 삭제 처리
      final deletedMessage = message.markAsDeleted(currentUserId);
      
      // Firestore 업데이트
      await _firestore.messages.doc(messageId).update(deletedMessage.toMap());
      
      // 로컬 업데이트
      messages[messageIndex] = deletedMessage;
      
      Get.snackbar('완료', '메시지가 삭제되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '메시지 삭제 실패: ${e.toString()}');
    }
  }

  /// 고아 데이터 정리 (관리자 기능)
  Future<void> cleanupOrphanedData() async {
    try {
      isLoading.value = true;
      
      // 1. 존재하지 않는 채팅방을 참조하는 메시지들 정리
      final allMessages = await _firestore.messages.get();
      final allChats = await _firestore.chats.get();
      
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      int deletedMessages = 0;
      
      for (final messageSnapshot in allMessages.docs) {
        final message = MessageModel.fromSnapshot(messageSnapshot);
        if (!existingChatIds.contains(message.chatId)) {
          await _firestore.messages.doc(message.messageId).delete();
          deletedMessages++;
        }
      }
      
      // 로컬 데이터도 정리
      await loadChatList();
      if (currentChat.value != null) {
        await loadMessagesForChat(currentChat.value!.chatId);
      }
      
      Get.snackbar('완료', '고아 메시지 $deletedMessages개 정리가 완료되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '고아 데이터 정리 실패: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// 데이터 정합성 검증
  Future<Map<String, dynamic>?> validateDataIntegrity() async {
    try {
      isLoading.value = true;
      
      final report = <String, dynamic>{
        'timestamp': DateTime.now(),
        'totalChats': 0,
        'totalMessages': 0,
        'orphanedMessages': 0,
        'issues': <String>[],
      };
      
      // 전체 데이터 개수 확인
      final allChats = await _firestore.chats.get();
      final allMessages = await _firestore.messages.get();
      
      report['totalChats'] = allChats.docs.length;
      report['totalMessages'] = allMessages.docs.length;
      
      // 채팅방 ID 목록
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      
      // 고아 메시지 확인
      int orphanedMessages = 0;
      for (final messageSnapshot in allMessages.docs) {
        final message = MessageModel.fromSnapshot(messageSnapshot);
        if (!existingChatIds.contains(message.chatId)) {
          orphanedMessages++;
        }
      }
      
      report['orphanedMessages'] = orphanedMessages;
      
      // 문제 항목 정리
      final issues = <String>[];
      if (orphanedMessages > 0) issues.add('고아 메시지 $orphanedMessages개 발견');
      
      report['issues'] = issues;
      report['isHealthy'] = issues.isEmpty;
      
      if (report['isHealthy'] == true) {
        Get.snackbar('완료', '데이터 정합성 검증 통과: 모든 데이터가 정상입니다.');
      } else {
        final issueList = report['issues'] as List<String>;
        Get.snackbar(
          '주의', 
          '데이터 정합성 문제 발견:\n${issueList.join('\n')}',
          duration: const Duration(seconds: 5),
        );
      }
      
      return report;
    } catch (e) {
      Get.snackbar('오류', '데이터 정합성 검증 실패: ${e.toString()}');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// 채팅방 삭제 확인 다이얼로그
  void showDeleteChatDialog(String chatId, String chatTitle) {
    Get.dialog(
      AlertDialog(
        title: const Text('채팅방 삭제'),
        content: Text('정말로 "$chatTitle" 채팅방을 삭제하시겠습니까?\n\n삭제된 채팅방과 모든 메시지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteChatPermanently(chatId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 메시지 삭제 확인 다이얼로그
  void showDeleteMessageDialog(String messageId, String messageContent) {
    Get.dialog(
      AlertDialog(
        title: const Text('메시지 삭제'),
        content: Text('정말로 이 메시지를 삭제하시겠습니까?\n\n"${messageContent.length > 50 ? '${messageContent.substring(0, 50)}...' : messageContent}"\n\n삭제된 메시지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteMessage(messageId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
