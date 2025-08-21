import 'package:get/get.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_participant_model.dart';
import 'package:typetalk/models/chat_invite_model.dart';
import 'package:typetalk/services/real_firebase_service.dart';

// 채팅 서비스 클래스
class ChatService extends GetxService {
  final RealFirebaseService _firestoreService = Get.find<RealFirebaseService>();
  
  // 채팅방 목록 스트림
  final RxList<ChatModel> chats = <ChatModel>[].obs;
  
  // 현재 채팅방
  final Rx<ChatModel?> currentChat = Rx<ChatModel?>(null);
  
  // 메시지 목록
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  
  // 참여자 목록
  final RxList<ChatParticipantModel> participants = <ChatParticipantModel>[].obs;
  
  // 초대 목록
  final RxList<ChatInviteModel> invites = <ChatInviteModel>[].obs;
  
  // 로딩 상태
  final RxBool isLoading = false.obs;
  final RxBool isSendingMessage = false.obs;

  // 채팅방 생성
  Future<ChatModel> createChat({
    required String title,
    required String createdBy,
    String? description,
    List<String>? targetMBTI,
    int? maxParticipants,
    ChatSettings? settings,
    List<String>? initialParticipants,
  }) async {
    try {
      isLoading.value = true;
      
      // MBTI 기반 그룹 채팅방 생성
      final chat = ChatCreationHelper.createMBTIGroupChat(
        title: title,
        createdBy: createdBy,
        targetMBTI: targetMBTI ?? [],
        description: description,
        maxParticipants: maxParticipants,
        settings: settings,
      );
      
      // Firestore에 저장
      await _firestoreService.setDocument('chats/${chat.chatId}', chat.toMap());
      
      // 생성자 참여자 정보 생성
      final creatorParticipant = ChatParticipantHelper.createCreator(
        chatId: chat.chatId,
        userId: createdBy,
      );
      
      await _firestoreService.setDocument('chatParticipants/${creatorParticipant.participantId}', creatorParticipant.toMap());
      
      // 초기 참여자들 추가
      if (initialParticipants != null) {
        for (final participantId in initialParticipants) {
          if (participantId != createdBy) {
            await addParticipantToChat(chat.chatId, participantId);
          }
        }
      }
      
      // 시스템 메시지 생성
      final systemMessage = MessageCreationHelper.createChatCreatedMessage(
        chatId: chat.chatId,
        creatorName: createdBy, // 실제로는 사용자 이름을 가져와야 함
      );
      
      await _firestoreService.setDocument('messages/${systemMessage.messageId}', systemMessage.toMap());
      
      // 채팅방 목록에 추가
      chats.add(chat);
      
      return chat;
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 개인 채팅방 생성
  Future<ChatModel> createPrivateChat({
    required String user1Id,
    required String user2Id,
  }) async {
    try {
      isLoading.value = true;
      
      // 개인 채팅방 생성
      final chat = ChatCreationHelper.createPrivateChat(
        user1Id: user1Id,
        user2Id: user2Id,
      );
      
      // Firestore에 저장
      await _firestoreService.chats.doc(chat.chatId).set(chat.toMap());
      
      // 참여자들 추가
      await addParticipantToChat(chat.chatId, user1Id);
      await addParticipantToChat(chat.chatId, user2Id);
      
      // 채팅방 목록에 추가
      chats.add(chat);
      
      return chat;
    } catch (e) {
      throw Exception('개인 채팅방 생성 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 채팅방에 참여자 추가
  Future<void> addParticipantToChat(String chatId, String userId) async {
    try {
      // 이미 참여자인지 확인
      final existingParticipant = participants.firstWhereOrNull(
        (p) => p.chatId == chatId && p.userId == userId,
      );
      
      if (existingParticipant != null) return;
      
      // 새로운 참여자 생성
      final participant = ChatParticipantHelper.createParticipant(
        chatId: chatId,
        userId: userId,
      );
      
      // Firestore에 저장
      await _firestoreService.chatParticipants.doc(participant.participantId)
          .set(participant.toMap());
      
      // 참여자 목록에 추가
      participants.add(participant);
      
      // 채팅방 정보 업데이트
      final chatIndex = chats.indexWhere((c) => c.chatId == chatId);
      if (chatIndex != -1) {
        final updatedChat = chats[chatIndex].addParticipant(userId);
        chats[chatIndex] = updatedChat;
        
        // Firestore 업데이트
        await _firestoreService.chats.doc(chatId).update(updatedChat.toMap());
      }
      
      // 시스템 메시지 생성
      final systemMessage = MessageCreationHelper.createUserJoinedMessage(
        chatId: chatId,
        userName: userId, // 실제로는 사용자 이름을 가져와야 함
      );
      
      await _firestoreService.messages.doc(systemMessage.messageId)
          .set(systemMessage.toMap());
      
    } catch (e) {
      throw Exception('참여자 추가 실패: $e');
    }
  }

  // 채팅방에서 참여자 제거
  Future<void> removeParticipantFromChat(String chatId, String userId) async {
    try {
      // 참여자 찾기
      final participantIndex = participants.indexWhere(
        (p) => p.chatId == chatId && p.userId == userId,
      );
      
      if (participantIndex == -1) return;
      
      final participant = participants[participantIndex];
      
      // 채팅방 나가기 상태로 업데이트
      final updatedParticipant = participant.leave();
      
      // Firestore 업데이트
      await _firestoreService.chatParticipants.doc(participant.participantId)
          .update(updatedParticipant.toMap());
      
      // 참여자 목록 업데이트
      participants[participantIndex] = updatedParticipant;
      
      // 채팅방 정보 업데이트
      final chatIndex = chats.indexWhere((c) => c.chatId == chatId);
      if (chatIndex != -1) {
        final updatedChat = chats[chatIndex].removeParticipant(userId);
        chats[chatIndex] = updatedChat;
        
        // Firestore 업데이트
        await _firestoreService.chats.doc(chatId).update(updatedChat.toMap());
      }
      
      // 시스템 메시지 생성
      final systemMessage = MessageCreationHelper.createUserLeftMessage(
        chatId: chatId,
        userName: userId, // 실제로는 사용자 이름을 가져와야 함
      );
      
      await _firestoreService.messages.doc(systemMessage.messageId)
          .set(systemMessage.toMap());
      
    } catch (e) {
      throw Exception('참여자 제거 실패: $e');
    }
  }

  // 메시지 전송
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String type = 'text',
    MessageMedia? media,
    MessageReply? replyTo,
  }) async {
    try {
      isSendingMessage.value = true;
      
      // 메시지 생성
      final message = MessageCreationHelper.createTextMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderId, // 실제로는 사용자 이름을 가져와야 함
        content: content,
        replyTo: replyTo,
      );
      
      // Firestore에 저장
      await _firestoreService.messages.doc(message.messageId)
          .set(message.toMap());
      
      // 메시지 목록에 추가
      messages.add(message);
      
      // 채팅방 정보 업데이트
      final chatIndex = chats.indexWhere((c) => c.chatId == chatId);
      if (chatIndex != -1) {
        final lastMessage = LastMessage(
          content: content,
          senderId: senderId,
          senderName: senderId, // 실제로는 사용자 이름을 가져와야 함
          timestamp: DateTime.now(),
          type: type,
        );
        
        final updatedChat = chats[chatIndex].updateLastMessage(lastMessage);
        chats[chatIndex] = updatedChat;
        
        // Firestore 업데이트
        await _firestoreService.chats.doc(chatId).update(updatedChat.toMap());
      }
      
      // 참여자 통계 업데이트
      final participantIndex = participants.indexWhere(
        (p) => p.chatId == chatId && p.userId == senderId,
      );
      
      if (participantIndex != -1) {
        final updatedParticipant = participants[participantIndex].incrementMessageCount();
        participants[participantIndex] = updatedParticipant;
        
        // Firestore 업데이트
        await _firestoreService.chatParticipants.doc(updatedParticipant.participantId)
            .update(updatedParticipant.toMap());
      }
      
      return message;
    } catch (e) {
      throw Exception('메시지 전송 실패: $e');
    } finally {
      isSendingMessage.value = false;
    }
  }

  // 채팅방 초대 생성
  Future<ChatInviteModel> createInvite({
    required String chatId,
    required String invitedBy,
    String? invitedUserId,
    String? invitedUserEmail,
    String? message,
    List<String>? allowedMBTI,
    bool requireApproval = false,
  }) async {
    try {
      ChatInviteModel invite;
      
      if (invitedUserId != null) {
        // 직접 사용자 초대
        invite = ChatInviteHelper.createDirectUserInvite(
          chatId: chatId,
          invitedBy: invitedBy,
          invitedUserId: invitedUserId,
          message: message,
          allowedMBTI: allowedMBTI,
          requireApproval: requireApproval,
        );
      } else if (invitedUserEmail != null) {
        // 이메일 초대
        invite = ChatInviteHelper.createEmailInvite(
          chatId: chatId,
          invitedBy: invitedBy,
          invitedUserEmail: invitedUserEmail,
          message: message,
          allowedMBTI: allowedMBTI,
          requireApproval: requireApproval,
        );
      } else {
        throw Exception('초대할 사용자 정보가 필요합니다.');
      }
      
      // Firestore에 저장
      await _firestoreService.chatInvites.doc(invite.inviteId)
          .set(invite.toMap());
      
      // 초대 목록에 추가
      invites.add(invite);
      
      return invite;
    } catch (e) {
      throw Exception('초대 생성 실패: $e');
    }
  }

  // 초대 수락
  Future<void> acceptInvite(String inviteId) async {
    try {
      final inviteIndex = invites.indexWhere((i) => i.inviteId == inviteId);
      if (inviteIndex == -1) throw Exception('초대를 찾을 수 없습니다.');
      
      final invite = invites[inviteIndex];
      
      // 초대 상태 업데이트
      final updatedInvite = invite.accept();
      invites[inviteIndex] = updatedInvite;
      
      // Firestore 업데이트
      await _firestoreService.chatInvites.doc(inviteId)
          .update(updatedInvite.toMap());
      
      // 채팅방에 참여자 추가
      if (invite.invitedUserId != null) {
        await addParticipantToChat(invite.chatId, invite.invitedUserId!);
      }
      
    } catch (e) {
      throw Exception('초대 수락 실패: $e');
    }
  }

  // 초대 거절
  Future<void> declineInvite(String inviteId) async {
    try {
      final inviteIndex = invites.indexWhere((i) => i.inviteId == inviteId);
      if (inviteIndex == -1) throw Exception('초대를 찾을 수 없습니다.');
      
      final invite = invites[inviteIndex];
      
      // 초대 상태 업데이트
      final updatedInvite = invite.decline();
      invites[inviteIndex] = updatedInvite;
      
      // Firestore 업데이트
      await _firestoreService.chatInvites.doc(inviteId)
          .update(updatedInvite.toMap());
      
    } catch (e) {
      throw Exception('초대 거절 실패: $e');
    }
  }

  // 채팅방 목록 로드
  Future<void> loadChats(String userId) async {
    try {
      isLoading.value = true;
      
      // 사용자가 참여한 채팅방들 조회
      final chatSnapshots = await _firestoreService.chats
          .where('participants', isEqualTo: [userId])
          .orderBy('updatedAt', descending: true)
          .get();
      
      final loadedChats = chatSnapshots.docs.map((snapshot) {
        return ChatModel.fromSnapshot(snapshot);
      }).toList();
      
      chats.assignAll(loadedChats);
      
    } catch (e) {
      throw Exception('채팅방 목록 로드 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 메시지 목록 로드
  Future<void> loadMessages(String chatId) async {
    try {
      isLoading.value = true;
      
      // 채팅방의 메시지들 조회
      final messageSnapshots = await _firestoreService.messages
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final loadedMessages = messageSnapshots.docs.map((snapshot) {
        return MessageModel.fromSnapshot(snapshot);
      }).toList();
      
      // 시간순으로 정렬
      loadedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      messages.assignAll(loadedMessages);
      
    } catch (e) {
      throw Exception('메시지 목록 로드 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 참여자 목록 로드
  Future<void> loadParticipants(String chatId) async {
    try {
      isLoading.value = true;
      
      // 채팅방의 참여자들 조회
      final participantSnapshots = await _firestoreService.chatParticipants
          .where('chatId', isEqualTo: chatId)
          .get();
      
      final loadedParticipants = participantSnapshots.docs.map((snapshot) {
        return ChatParticipantModel.fromSnapshot(snapshot);
      }).toList();
      
      participants.assignAll(loadedParticipants);
      
    } catch (e) {
      throw Exception('참여자 목록 로드 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 초대 목록 로드
  Future<void> loadInvites(String userId) async {
    try {
      isLoading.value = true;
      
      // 사용자에게 온 초대들 조회
      final inviteSnapshots = await _firestoreService.chatInvites
          .where('invitedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      
      final loadedInvites = inviteSnapshots.docs.map((snapshot) {
        return ChatInviteModel.fromSnapshot(snapshot);
      }).toList();
      
      invites.assignAll(loadedInvites);
      
    } catch (e) {
      throw Exception('초대 목록 로드 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 채팅방 선택
  void selectChat(ChatModel chat) {
    currentChat.value = chat;
    loadMessages(chat.chatId);
    loadParticipants(chat.chatId);
  }

  // 채팅방 나가기
  void leaveChat() {
    currentChat.value = null;
    messages.clear();
    participants.clear();
  }

  // 타이핑 상태 업데이트
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      final participantIndex = participants.indexWhere(
        (p) => p.chatId == chatId && p.userId == userId,
      );
      
      if (participantIndex != -1) {
        final updatedParticipant = participants[participantIndex].setTyping(isTyping);
        participants[participantIndex] = updatedParticipant;
        
        // Firestore 업데이트
        await _firestoreService.chatParticipants.doc(updatedParticipant.participantId)
            .update(updatedParticipant.toMap());
      }
    } catch (e) {
      // 타이핑 상태 업데이트 실패는 무시
      print('타이핑 상태 업데이트 실패: $e');
    }
  }

  // 읽음 표시 업데이트
  Future<void> markMessageAsRead(String chatId, String userId, String messageId) async {
    try {
      final participantIndex = participants.indexWhere(
        (p) => p.chatId == chatId && p.userId == userId,
      );
      
      if (participantIndex != -1) {
        final updatedParticipant = participants[participantIndex].updateLastRead(messageId);
        participants[participantIndex] = updatedParticipant;
        
        // Firestore 업데이트
        await _firestoreService.chatParticipants.doc(updatedParticipant.participantId)
            .update(updatedParticipant.toMap());
      }
    } catch (e) {
      print('읽음 표시 업데이트 실패: $e');
    }
  }

  // 채팅방 검색
  List<ChatModel> searchChats(String query) {
    if (query.isEmpty) return chats;
    
    return chats.where((chat) {
      return chat.title.toLowerCase().contains(query.toLowerCase()) ||
             (chat.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  // MBTI 기반 채팅방 필터링
  List<ChatModel> filterChatsByMBTI(String mbti) {
    return chats.where((chat) {
      return chat.isCompatibleWithMBTI(mbti);
    }).toList();
  }

  // 활성 채팅방만 필터링
  List<ChatModel> getActiveChats() {
    return chats.where((chat) {
      return chat.stats.lastActivity.isAfter(
        DateTime.now().subtract(const Duration(days: 7)),
      );
    }).toList();
  }

  // ============================================================================
  // 데이터 정합성 및 삭제 처리 기능
  // ============================================================================

  /// 채팅방 완전 삭제 (관련 데이터 모두 삭제)
  Future<void> deleteChatPermanently(String chatId, String requestUserId) async {
    try {
      isLoading.value = true;
      
      // 1. 권한 확인 (채팅방 생성자 또는 관리자만 삭제 가능)
      final chat = chats.firstWhereOrNull((c) => c.chatId == chatId);
      if (chat == null) {
        throw Exception('채팅방을 찾을 수 없습니다.');
      }
      
      if (chat.createdBy != requestUserId) {
        throw Exception('채팅방 삭제 권한이 없습니다.');
      }
      
      // 2. 트랜잭션으로 관련 데이터 일괄 삭제
      await _executeChatDeletionTransaction(chatId);
      
      // 3. 로컬 데이터 정리
      _cleanupLocalChatData(chatId);
      
      print('채팅방이 완전히 삭제되었습니다: $chatId');
      
    } catch (e) {
      throw Exception('채팅방 삭제 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 채팅방 삭제 트랜잭션 실행
  Future<void> _executeChatDeletionTransaction(String chatId) async {
    try {
      // 삭제할 데이터 목록 수집
      final deleteOperations = <Map<String, dynamic>>[];
      
      // 1. 채팅방 메시지들 삭제
      final chatMessages = await _firestoreService.messages
          .where('chatId', isEqualTo: chatId)
          .get();
      
      for (final messageSnapshot in chatMessages.docs) {
        deleteOperations.add({
          'type': 'delete',
          'path': 'messages/${messageSnapshot.id}',
        });
      }
      
      // 2. 채팅방 참여자들 삭제
      final chatParticipants = await _firestoreService.chatParticipants
          .where('chatId', isEqualTo: chatId)
          .get();
      
      for (final participantSnapshot in chatParticipants.docs) {
        deleteOperations.add({
          'type': 'delete',
          'path': 'chatParticipants/${participantSnapshot.id}',
        });
      }
      
      // 3. 채팅방 초대들 삭제
      final chatInvites = await _firestoreService.chatInvites
          .where('chatId', isEqualTo: chatId)
          .get();
      
      for (final inviteSnapshot in chatInvites.docs) {
        deleteOperations.add({
          'type': 'delete',
          'path': 'chatInvites/${inviteSnapshot.id}',
        });
      }
      
      // 4. 채팅방 자체 삭제
      deleteOperations.add({
        'type': 'delete',
        'path': 'chats/$chatId',
      });
      
      // 5. 배치 삭제 실행
      if (deleteOperations.isNotEmpty) {
        final batch = _firestoreService.batch();
        for (final operation in deleteOperations) {
          batch.delete(operation['path']);
        }
        await batch.commit();
      }
      
    } catch (e) {
      throw Exception('채팅방 삭제 트랜잭션 실패: $e');
    }
  }

  /// 로컬 채팅 데이터 정리
  void _cleanupLocalChatData(String chatId) {
    // 채팅방 목록에서 제거
    chats.removeWhere((chat) => chat.chatId == chatId);
    
    // 해당 채팅방의 메시지들 제거
    messages.removeWhere((message) => message.chatId == chatId);
    
    // 해당 채팅방의 참여자들 제거
    participants.removeWhere((participant) => participant.chatId == chatId);
    
    // 해당 채팅방의 초대들 제거
    invites.removeWhere((invite) => invite.chatId == chatId);
    
    // 현재 선택된 채팅방이면 해제
    if (currentChat.value?.chatId == chatId) {
      currentChat.value = null;
    }
  }

  /// 메시지 삭제 (소프트 삭제)
  Future<void> deleteMessage(String messageId, String requestUserId) async {
    try {
      final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
      if (messageIndex == -1) {
        throw Exception('메시지를 찾을 수 없습니다.');
      }
      
      final message = messages[messageIndex];
      
      // 메시지 발송자만 삭제 가능
      if (message.senderId != requestUserId) {
        throw Exception('메시지 삭제 권한이 없습니다.');
      }
      
      // 메시지를 삭제됨으로 표시
      final deletedMessage = message.markAsDeleted(requestUserId);
      
      // Firestore 업데이트
      await _firestoreService.messages.doc(messageId)
          .update(deletedMessage.toMap());
      
      // 로컬 업데이트
      messages[messageIndex] = deletedMessage;
      
      // 마지막 메시지였다면 채팅방 정보 업데이트
      await _updateChatLastMessageIfNeeded(message.chatId, messageId);
      
    } catch (e) {
      throw Exception('메시지 삭제 실패: $e');
    }
  }

  /// 채팅방의 마지막 메시지 업데이트 (삭제된 메시지인 경우)
  Future<void> _updateChatLastMessageIfNeeded(String chatId, String deletedMessageId) async {
    try {
      final chatIndex = chats.indexWhere((c) => c.chatId == chatId);
      if (chatIndex == -1) return;
      
      final chat = chats[chatIndex];
      
      // 삭제된 메시지가 마지막 메시지인지 확인
      final chatMessages = messages.where((m) => 
        m.chatId == chatId && 
        !m.isDeleted && 
        m.type != 'system'
      ).toList();
      
      if (chatMessages.isEmpty) {
        // 모든 메시지가 삭제된 경우
        final updatedChat = chat.clearLastMessage();
        chats[chatIndex] = updatedChat;
        await _firestoreService.chats.doc(chatId).update(updatedChat.toMap());
      } else {
        // 가장 최근 메시지로 업데이트
        chatMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latestMessage = chatMessages.first;
        
        final newLastMessage = LastMessage(
          content: latestMessage.content,
          senderId: latestMessage.senderId,
          senderName: latestMessage.senderName,
          timestamp: latestMessage.createdAt,
          type: latestMessage.type,
        );
        
        final updatedChat = chat.updateLastMessage(newLastMessage);
        chats[chatIndex] = updatedChat;
        await _firestoreService.chats.doc(chatId).update(updatedChat.toMap());
      }
    } catch (e) {
      print('마지막 메시지 업데이트 실패: $e');
    }
  }

  /// 사용자 탈퇴 시 채팅 데이터 정리
  Future<void> cleanupUserChatData(String userId) async {
    try {
      isLoading.value = true;
      
      // 1. 사용자가 생성한 채팅방들 조회
      final userCreatedChats = await _firestoreService.chats
          .where('createdBy', isEqualTo: userId)
          .get();
      
      // 2. 생성한 채팅방이 개인 채팅방이면 삭제, 그룹 채팅방이면 소유권 이전
      for (final chatSnapshot in userCreatedChats.docs) {
        final chat = ChatModel.fromSnapshot(chatSnapshot);
        
        if (chat.type == 'private') {
          // 개인 채팅방은 완전 삭제
          await _executeChatDeletionTransaction(chat.chatId);
        } else {
          // 그룹 채팅방은 다른 참여자에게 소유권 이전
          await _transferChatOwnership(chat.chatId, userId);
        }
      }
      
      // 3. 사용자가 참여한 모든 채팅방에서 참여자 정보 정리
      final userParticipations = await _firestoreService.chatParticipants
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final participantSnapshot in userParticipations.docs) {
        final participant = ChatParticipantModel.fromSnapshot(participantSnapshot);
        
        // 참여자를 나간 것으로 처리
        await removeParticipantFromChat(participant.chatId, userId);
      }
      
      // 4. 사용자의 미처리 초대들 정리
      await _cleanupUserInvites(userId);
      
      print('사용자 채팅 데이터 정리 완료: $userId');
      
    } catch (e) {
      throw Exception('사용자 채팅 데이터 정리 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 채팅방 소유권 이전
  Future<void> _transferChatOwnership(String chatId, String oldOwnerId) async {
    try {
      // 채팅방의 다른 참여자 중 가장 오래된 참여자에게 소유권 이전
      final chatParticipants = await _firestoreService.chatParticipants
          .where('chatId', isEqualTo: chatId)
          .where('userId', isGreaterThan: oldOwnerId) // 이전 소유자 제외
          .orderBy('joinedAt')
          .limit(1)
          .get();
      
      if (chatParticipants.docs.isNotEmpty) {
        final newOwner = ChatParticipantModel.fromSnapshot(chatParticipants.docs.first);
        
        // 채팅방 소유자 변경
        await _firestoreService.chats.doc(chatId).update({
          'createdBy': newOwner.userId,
          'updatedAt': DateTime.now(),
        });
        
        // 시스템 메시지 생성
        final systemMessage = MessageCreationHelper.createOwnershipTransferMessage(
          chatId: chatId,
          newOwnerName: newOwner.userId, // 실제로는 사용자 이름을 가져와야 함
        );
        
        await _firestoreService.messages.doc(systemMessage.messageId)
            .set(systemMessage.toMap());
      } else {
        // 다른 참여자가 없으면 채팅방 삭제
        await _executeChatDeletionTransaction(chatId);
      }
    } catch (e) {
      print('채팅방 소유권 이전 실패: $e');
      // 실패하면 채팅방 삭제
      await _executeChatDeletionTransaction(chatId);
    }
  }

  /// 사용자 초대 정리
  Future<void> _cleanupUserInvites(String userId) async {
    try {
      // 사용자가 보낸 초대들
      final sentInvites = await _firestoreService.chatInvites
          .where('invitedBy', isEqualTo: userId)
          .get();
      
      // 사용자가 받은 초대들
      final receivedInvites = await _firestoreService.chatInvites
          .where('invitedUserId', isEqualTo: userId)
          .get();
      
      final deleteOperations = <Map<String, dynamic>>[];
      
      // 모든 관련 초대 삭제
      for (final inviteSnapshot in [...sentInvites.docs, ...receivedInvites.docs]) {
        deleteOperations.add({
          'type': 'delete',
          'path': 'chatInvites/${inviteSnapshot.id}',
        });
      }
      
      if (deleteOperations.isNotEmpty) {
        final batch = _firestoreService.batch();
        for (final operation in deleteOperations) {
          batch.delete(operation['path']);
        }
        await batch.commit();
      }
    } catch (e) {
      print('사용자 초대 정리 실패: $e');
    }
  }

  /// 고아 데이터 정리
  Future<void> cleanupOrphanedData() async {
    try {
      isLoading.value = true;
      
      // 1. 존재하지 않는 채팅방을 참조하는 메시지들 정리
      await _cleanupOrphanedMessages();
      
      // 2. 존재하지 않는 채팅방을 참조하는 참여자들 정리
      await _cleanupOrphanedParticipants();
      
      // 3. 존재하지 않는 채팅방을 참조하는 초대들 정리
      await _cleanupOrphanedInvites();
      
      // 4. 빈 채팅방(참여자가 없는 채팅방) 정리
      await _cleanupEmptyChats();
      
      print('고아 데이터 정리 완료');
      
    } catch (e) {
      throw Exception('고아 데이터 정리 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 고아 메시지 정리
  Future<void> _cleanupOrphanedMessages() async {
    try {
      final allMessages = await _firestoreService.messages.get();
      final allChats = await _firestoreService.chats.get();
      
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      final deleteOperations = <Map<String, dynamic>>[];
      
      for (final messageSnapshot in allMessages.docs) {
        final message = MessageModel.fromSnapshot(messageSnapshot);
        if (!existingChatIds.contains(message.chatId)) {
          deleteOperations.add({
            'type': 'delete',
            'path': 'messages/${message.messageId}',
          });
        }
      }
      
      if (deleteOperations.isNotEmpty) {
        final batch = _firestoreService.batch();
        for (final operation in deleteOperations) {
          batch.delete(operation['path']);
        }
        await batch.commit();
        print('고아 메시지 ${deleteOperations.length}개 정리됨');
      }
    } catch (e) {
      print('고아 메시지 정리 실패: $e');
    }
  }

  /// 고아 참여자 정리
  Future<void> _cleanupOrphanedParticipants() async {
    try {
      final allParticipants = await _firestoreService.chatParticipants.get();
      final allChats = await _firestoreService.chats.get();
      
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      final deleteOperations = <Map<String, dynamic>>[];
      
      for (final participantSnapshot in allParticipants.docs) {
        final participant = ChatParticipantModel.fromSnapshot(participantSnapshot);
        if (!existingChatIds.contains(participant.chatId)) {
          deleteOperations.add({
            'type': 'delete',
            'path': 'chatParticipants/${participant.participantId}',
          });
        }
      }
      
      if (deleteOperations.isNotEmpty) {
        final batch = _firestoreService.batch();
        for (final operation in deleteOperations) {
          batch.delete(operation['path']);
        }
        await batch.commit();
        print('고아 참여자 ${deleteOperations.length}개 정리됨');
      }
    } catch (e) {
      print('고아 참여자 정리 실패: $e');
    }
  }

  /// 고아 초대 정리
  Future<void> _cleanupOrphanedInvites() async {
    try {
      final allInvites = await _firestoreService.chatInvites.get();
      final allChats = await _firestoreService.chats.get();
      
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      final deleteOperations = <Map<String, dynamic>>[];
      
      for (final inviteSnapshot in allInvites.docs) {
        final invite = ChatInviteModel.fromSnapshot(inviteSnapshot);
        if (!existingChatIds.contains(invite.chatId)) {
          deleteOperations.add({
            'type': 'delete',
            'path': 'chatInvites/${invite.inviteId}',
          });
        }
      }
      
      if (deleteOperations.isNotEmpty) {
        final batch = _firestoreService.batch();
        for (final operation in deleteOperations) {
          batch.delete(operation['path']);
        }
        await batch.commit();
        print('고아 초대 ${deleteOperations.length}개 정리됨');
      }
    } catch (e) {
      print('고아 초대 정리 실패: $e');
    }
  }

  /// 빈 채팅방 정리
  Future<void> _cleanupEmptyChats() async {
    try {
      final allChats = await _firestoreService.chats.get();
      final deleteOperations = <Map<String, dynamic>>[];
      
      for (final chatSnapshot in allChats.docs) {
        final chat = ChatModel.fromSnapshot(chatSnapshot);
        
        // 참여자가 없는 채팅방 찾기
        final participants = await _firestoreService.chatParticipants
            .where('chatId', isEqualTo: chat.chatId)
            .where('status', isEqualTo: 'active')
            .get();
        
        if (participants.docs.isEmpty) {
          // 빈 채팅방이므로 삭제
          await _executeChatDeletionTransaction(chat.chatId);
        }
      }
      
      if (deleteOperations.isNotEmpty) {
        print('빈 채팅방 ${deleteOperations.length}개 정리됨');
      }
    } catch (e) {
      print('빈 채팅방 정리 실패: $e');
    }
  }

  /// 데이터 정합성 검증
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    try {
      final report = <String, dynamic>{
        'timestamp': DateTime.now(),
        'totalChats': 0,
        'totalMessages': 0,
        'totalParticipants': 0,
        'totalInvites': 0,
        'orphanedMessages': 0,
        'orphanedParticipants': 0,
        'orphanedInvites': 0,
        'emptyChats': 0,
        'issues': <String>[],
      };
      
      // 전체 데이터 개수 확인
      final allChats = await _firestoreService.chats.get();
      final allMessages = await _firestoreService.messages.get();
      final allParticipants = await _firestoreService.chatParticipants.get();
      final allInvites = await _firestoreService.chatInvites.get();
      
      report['totalChats'] = allChats.docs.length;
      report['totalMessages'] = allMessages.docs.length;
      report['totalParticipants'] = allParticipants.docs.length;
      report['totalInvites'] = allInvites.docs.length;
      
      // 채팅방 ID 목록
      final existingChatIds = allChats.docs.map((chat) => chat.id).toSet();
      
      // 고아 데이터 확인
      int orphanedMessages = 0;
      int orphanedParticipants = 0;
      int orphanedInvites = 0;
      
      // 고아 메시지 확인
      for (final messageSnapshot in allMessages.docs) {
        final message = MessageModel.fromSnapshot(messageSnapshot);
        if (!existingChatIds.contains(message.chatId)) {
          orphanedMessages++;
        }
      }
      
      // 고아 참여자 확인
      for (final participantSnapshot in allParticipants.docs) {
        final participant = ChatParticipantModel.fromSnapshot(participantSnapshot);
        if (!existingChatIds.contains(participant.chatId)) {
          orphanedParticipants++;
        }
      }
      
      // 고아 초대 확인
      for (final inviteSnapshot in allInvites.docs) {
        final invite = ChatInviteModel.fromSnapshot(inviteSnapshot);
        if (!existingChatIds.contains(invite.chatId)) {
          orphanedInvites++;
        }
      }
      
      // 빈 채팅방 확인
      int emptyChats = 0;
      for (final chatSnapshot in allChats.docs) {
        final chat = ChatModel.fromSnapshot(chatSnapshot);
        final participants = await _firestoreService.chatParticipants
            .where('chatId', isEqualTo: chat.chatId)
            .where('status', isEqualTo: 'active')
            .get();
        
        if (participants.docs.isEmpty) {
          emptyChats++;
        }
      }
      
      report['orphanedMessages'] = orphanedMessages;
      report['orphanedParticipants'] = orphanedParticipants;
      report['orphanedInvites'] = orphanedInvites;
      report['emptyChats'] = emptyChats;
      
      // 문제 항목 정리
      final issues = <String>[];
      if (orphanedMessages > 0) issues.add('고아 메시지 $orphanedMessages개 발견');
      if (orphanedParticipants > 0) issues.add('고아 참여자 $orphanedParticipants개 발견');
      if (orphanedInvites > 0) issues.add('고아 초대 $orphanedInvites개 발견');
      if (emptyChats > 0) issues.add('빈 채팅방 $emptyChats개 발견');
      
      report['issues'] = issues;
      report['isHealthy'] = issues.isEmpty;
      
      return report;
    } catch (e) {
      throw Exception('데이터 정합성 검증 실패: $e');
    }
  }

  @override
  void onClose() {
    chats.clear();
    messages.clear();
    participants.clear();
    invites.clear();
    super.onClose();
  }
}
