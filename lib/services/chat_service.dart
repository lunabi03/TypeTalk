import 'package:get/get.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_participant_model.dart';
import 'package:typetalk/models/chat_invite_model.dart';
import 'package:typetalk/services/firestore_service.dart';

// 채팅 서비스 클래스
class ChatService extends GetxService {
  final DemoFirestoreService _firestoreService = DemoFirestoreService();
  
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
      await _firestoreService.chats.doc(chat.chatId).set(chat.toMap());
      
      // 생성자 참여자 정보 생성
      final creatorParticipant = ChatParticipantHelper.createCreator(
        chatId: chat.chatId,
        userId: createdBy,
      );
      
      await _firestoreService.chatParticipants.doc(creatorParticipant.participantId)
          .set(creatorParticipant.toMap());
      
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
      
      await _firestoreService.messages.doc(systemMessage.messageId)
          .set(systemMessage.toMap());
      
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
      
      final loadedChats = chatSnapshots.map((snapshot) {
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
      
      final loadedMessages = messageSnapshots.map((snapshot) {
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
      
      final loadedParticipants = participantSnapshots.map((snapshot) {
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
      
      final loadedInvites = inviteSnapshots.map((snapshot) {
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

  @override
  void onClose() {
    chats.clear();
    messages.clear();
    participants.clear();
    invites.clear();
    super.onClose();
  }
}
