import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:typetalk/models/chat_invite_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/services/real_firebase_service.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/controllers/auth_controller.dart';

// 채팅 초대 관리 서비스
class ChatInviteService extends GetxService {
  static ChatInviteService get instance => Get.find<ChatInviteService>();

  final RealFirebaseService _firebase = Get.find<RealFirebaseService>();
  final RealUserRepository _userRepository = Get.find<RealUserRepository>();
  AuthController? get _authController => Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  // 내가 받은 초대 목록
  RxList<ChatInviteModel> receivedInvites = <ChatInviteModel>[].obs;
  
  // 내가 보낸 초대 목록
  RxList<ChatInviteModel> sentInvites = <ChatInviteModel>[].obs;
  
  // 로딩 상태
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 초대 목록 로드는 사용자가 로그인한 후에 로드
    // loadInvites();
  }

  /// 초대 목록 로드
  Future<void> loadInvites() async {
    try {
      isLoading.value = true;
      final authController = _authController;
      if (authController == null) return;
      
      final currentUserId = authController.userId;
      if (currentUserId == null) return;

      // 받은 초대 로드
      await _loadReceivedInvites(currentUserId);
      
      // 보낸 초대 로드
      await _loadSentInvites(currentUserId);
      
    } catch (e) {
      print('초대 목록 로드 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 받은 초대 로드
  Future<void> _loadReceivedInvites(String userId) async {
    try {
      final snapshots = await _firebase.queryDocuments(
        'chatInvites',
        field: 'invitedUserId',
        isEqualTo: userId,
        orderByField: 'createdAt',
        descending: true,
      );

      final invites = snapshots.docs
          .map((doc) => ChatInviteModel.fromSnapshot(doc))
          .where((invite) => invite.isValid || invite.isPending)
          .toList();

      receivedInvites.assignAll(invites);
      print('받은 초대 ${invites.length}개 로드 완료');
    } catch (e) {
      print('받은 초대 로드 실패: $e');
      receivedInvites.clear();
    }
  }

  /// 보낸 초대 로드
  Future<void> _loadSentInvites(String userId) async {
    try {
      final snapshots = await _firebase.queryDocuments(
        'chatInvites',
        field: 'invitedBy',
        isEqualTo: userId,
        orderByField: 'createdAt',
        descending: true,
      );

      final invites = snapshots.docs
          .map((doc) => ChatInviteModel.fromSnapshot(doc))
          .toList();

      sentInvites.assignAll(invites);
      print('보낸 초대 ${invites.length}개 로드 완료');
    } catch (e) {
      print('보낸 초대 로드 실패: $e');
      sentInvites.clear();
    }
  }

  /// 1:1 채팅 초대 생성
  Future<ChatInviteModel?> createDirectChatInvite({
    required String targetUserId,
    String? message,
  }) async {
    try {
      final authController = _authController;
      if (authController == null) {
        throw Exception('로그인이 필요합니다.');
      }
      
      final currentUserId = authController.userId;
      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 기존 채팅방이 있는지 확인
      final existingChat = await _findExistingDirectChat(currentUserId, targetUserId);
      
      if (existingChat != null) {
        // 기존 채팅방이 있으면 바로 열기
        return null;
      }

      // 새로운 개인 채팅방 생성
      final chatId = await _createDirectChat(currentUserId, targetUserId);
      
      // 초대 생성
      final invite = ChatInviteHelper.createDirectUserInvite(
        chatId: chatId,
        invitedBy: currentUserId,
        invitedUserId: targetUserId,
        message: message,
        requireApproval: true, // 승인 필요
      );

      // Firestore에 초대 저장
      await _firebase.setDocument('chatInvites/${invite.inviteId}', invite.toMap());
      
      // 초대 목록 새로고침
      await loadInvites();
      
      print('1:1 채팅 초대 생성 완료: ${invite.inviteId}');
      return invite;
      
    } catch (e) {
      print('1:1 채팅 초대 생성 실패: $e');
      rethrow;
    }
  }

  /// 기존 1:1 채팅방 찾기
  Future<String?> _findExistingDirectChat(String user1Id, String user2Id) async {
    try {
      final snapshots = await _firebase.queryDocuments(
        'chats',
        field: 'type',
        isEqualTo: 'private',
      );

      for (final doc in snapshots.docs) {
        final chat = ChatModel.fromSnapshot(doc);
        if (chat.participants.contains(user1Id) && 
            chat.participants.contains(user2Id) &&
            chat.participants.length == 2) {
          return chat.chatId;
        }
      }
      return null;
    } catch (e) {
      print('기존 채팅방 찾기 실패: $e');
      return null;
    }
  }

  /// 새로운 1:1 채팅방 생성
  Future<String> _createDirectChat(String user1Id, String user2Id) async {
    try {
      // 정렬된 조합으로 일관된 개인 채팅 ID 생성
      final ids = [user1Id, user2Id]..sort();
      final chatId = 'private-${ids.join('-')}';

      // 사용자 정보 가져오기
      final user1 = await _userRepository.getUser(user1Id);
      final user2 = await _userRepository.getUser(user2Id);

      final chat = ChatModel(
        chatId: chatId,
        type: 'private',
        title: user2?.name ?? '개인 채팅',
        description: null,
        createdBy: user1Id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: [user1Id, user2Id],
        participantCount: 2,
        maxParticipants: 2,
        targetMBTI: null,
        mbtiCategory: null,
        settings: ChatSettings(
          isPrivate: true,
          allowInvites: false,
          moderatedMode: false,
          autoDelete: false,
        ),
        stats: ChatStats(
          messageCount: 0,
          activeMembers: 2,
          lastActivity: DateTime.now(),
          totalParticipants: 2,
          onlineParticipants: 2,
        ),
      );

      // Firestore에 채팅방 저장
      await _firebase.setDocument('chats/$chatId', chat.toMap());
      
      return chatId;
    } catch (e) {
      print('새 채팅방 생성 실패: $e');
      rethrow;
    }
  }

  /// 초대 수락
  Future<bool> acceptInvite(String inviteId) async {
    try {
      isLoading.value = true;
      
      // 초대 정보 가져오기
      final inviteDoc = await _firebase.getDocument('chatInvites/$inviteId');
      if (!inviteDoc.exists) {
        throw Exception('초대를 찾을 수 없습니다.');
      }

      final invite = ChatInviteModel.fromSnapshot(inviteDoc);
      
      // 초대 상태 확인
      if (!invite.isValid) {
        throw Exception('유효하지 않은 초대입니다.');
      }

      // 초대 수락 처리
      final acceptedInvite = invite.accept();
      await _firebase.updateDocument('chatInvites/$inviteId', acceptedInvite.toMap());
      
      // 초대 목록 새로고침
      await loadInvites();
      
      print('초대 수락 완료: $inviteId');
      return true;
      
    } catch (e) {
      print('초대 수락 실패: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 초대 거절
  Future<bool> declineInvite(String inviteId) async {
    try {
      isLoading.value = true;
      
      // 초대 정보 가져오기
      final inviteDoc = await _firebase.getDocument('chatInvites/$inviteId');
      if (!inviteDoc.exists) {
        throw Exception('초대를 찾을 수 없습니다.');
      }

      final invite = ChatInviteModel.fromSnapshot(inviteDoc);
      
      // 초대 거절 처리
      final declinedInvite = invite.decline();
      await _firebase.updateDocument('chatInvites/$inviteId', declinedInvite.toMap());
      
      // 초대 목록 새로고침
      await loadInvites();
      
      print('초대 거절 완료: $inviteId');
      return true;
      
    } catch (e) {
      print('초대 거절 실패: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 초대 취소
  Future<bool> cancelInvite(String inviteId) async {
    try {
      isLoading.value = true;
      
      // 초대 정보 가져오기
      final inviteDoc = await _firebase.getDocument('chatInvites/$inviteId');
      if (!inviteDoc.exists) {
        throw Exception('초대를 찾을 수 없습니다.');
      }

      final invite = ChatInviteModel.fromSnapshot(inviteDoc);
      
      // 초대 취소 처리
      final cancelledInvite = invite.cancel();
      await _firebase.updateDocument('chatInvites/$inviteId', cancelledInvite.toMap());
      
      // 초대 목록 새로고침
      await loadInvites();
      
      print('초대 취소 완료: $inviteId');
      return true;
      
    } catch (e) {
      print('초대 취소 실패: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 특정 사용자에게 보낸 초대 찾기
  ChatInviteModel? findInviteToUser(String targetUserId) {
    final authController = _authController;
    if (authController == null) return null;
    
    final currentUserId = authController.userId;
    if (currentUserId == null) return null;

    return sentInvites.firstWhereOrNull((invite) => 
      invite.invitedUserId == targetUserId && 
      invite.isPending
    );
  }

  /// 특정 사용자로부터 받은 초대 찾기
  ChatInviteModel? findInviteFromUser(String fromUserId) {
    final authController = _authController;
    if (authController == null) return null;
    
    final currentUserId = authController.userId;
    if (currentUserId == null) return null;

    return receivedInvites.firstWhereOrNull((invite) => 
      invite.invitedBy == fromUserId && 
      invite.isPending
    );
  }

  /// 대기 중인 초대 개수
  int get pendingInviteCount => receivedInvites.where((invite) => invite.isPending).length;

  /// 수락된 초대 개수
  int get acceptedInviteCount => receivedInvites.where((invite) => invite.isAccepted).length;

  /// 거절된 초대 개수
  int get declinedInviteCount => receivedInvites.where((invite) => invite.isDeclined).length;

  /// 초대 새로고침
  Future<void> refreshInvites() async {
    await loadInvites();
  }
}
