import 'dart:async';
import 'package:get/get.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/services/realtime_message_service.dart';

class RealtimeChatController extends GetxController {
  final RealtimeMessageService _messageService = Get.find<RealtimeMessageService>();
  
  // 현재 채팅방 정보
  final Rx<ChatModel?> currentChatRoom = Rx<ChatModel?>(null);
  
  // 메시지 목록
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  
  // 타이핑 상태
  final RxMap<String, bool> typingUsers = <String, bool>{}.obs;
  
  // 로딩 상태
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  
  // 페이지네이션
  final RxBool hasMoreMessages = true.obs;
  final RxInt currentPage = 0.obs;
  final int messagesPerPage = 20;
  
  // 스트림 구독
  StreamSubscription<List<MessageModel>>? _messageSubscription;
  StreamSubscription<Map<String, bool>>? _typingSubscription;
  
  // 타이핑 디바운스 타이머
  Timer? _typingTimer;
  final Duration _typingDebounce = Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _disposeStreams();
    _typingTimer?.cancel();
    super.onClose();
  }

  // 채팅방 설정
  Future<void> setChatRoom(ChatModel chatRoom) async {
    try {
      // 기존 스트림 정리
      _disposeStreams();
      
      // 새 채팅방 설정
      currentChatRoom.value = chatRoom;
      messages.clear();
      typingUsers.clear();
      currentPage.value = 0;
      hasMoreMessages.value = true;
      
      // 메시지 스트림 시작
      await _startMessageStream();
      
      // 타이핑 스트림 시작
      await _startTypingStream();
      
      // 초기 메시지 로드
      await loadInitialMessages();
      
    } catch (e) {
      Get.snackbar('오류', '채팅방 설정에 실패했습니다: $e');
    }
  }

  // 메시지 스트림 시작
  Future<void> _startMessageStream() async {
    if (currentChatRoom.value == null) return;
    
    try {
              _messageSubscription = _messageService
            .startMessageStream(currentChatRoom.value!.chatId)
          .listen((newMessages) {
        messages.assignAll(newMessages);
      });
    } catch (e) {
      // 메시지 스트림 시작 실패 처리
    }
  }

  // 타이핑 스트림 시작
  Future<void> _startTypingStream() async {
    if (currentChatRoom.value == null) return;
    
    try {
              _typingSubscription = _messageService
            .startTypingStream(currentChatRoom.value!.chatId)
          .listen((newTypingUsers) {
        typingUsers.assignAll(newTypingUsers);
      });
    } catch (e) {
      // 타이핑 스트림 시작 실패 처리
    }
  }

  // 스트림 정리
  void _disposeStreams() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageSubscription = null;
    _typingSubscription = null;
  }

  // 초기 메시지 로드
  Future<void> loadInitialMessages() async {
    if (currentChatRoom.value == null) return;
    
    try {
      isLoading.value = true;
      
      // 첫 페이지 메시지 로드
      await loadMoreMessages();
      
    } catch (e) {
      Get.snackbar('오류', '메시지 로드에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 더 많은 메시지 로드 (페이지네이션)
  Future<void> loadMoreMessages() async {
    if (currentChatRoom.value == null || !hasMoreMessages.value) return;
    
    try {
      isLoading.value = true;
      
      final newMessages = await _messageService.getChatMessages(
        chatRoomId: currentChatRoom.value!.id,
        limit: messagesPerPage,
        lastMessageId: messages.isNotEmpty ? messages.last.messageId : null,
      );
      
      if (newMessages.isNotEmpty) {
        messages.addAll(newMessages);
        currentPage.value++;
      }
      
      hasMoreMessages.value = newMessages.length >= messagesPerPage;
      
    } catch (e) {
      Get.snackbar('오류', '메시지 로드에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 메시지 전송
  Future<void> sendMessage(String content, {MessageReply? replyTo}) async {
    if (currentChatRoom.value == null || content.trim().isEmpty) return;
    
    try {
      isSending.value = true;
      
      // 타이핑 상태 종료
      await _messageService.stopTyping(currentChatRoom.value!.id);
      
      // 메시지 전송
      final message = await _messageService.sendMessage(
        chatRoomId: currentChatRoom.value!.id,
        content: content.trim(),
        replyTo: replyTo,
      );
      
      // 로컬 메시지 목록에 추가 (실시간 업데이트 대기)
      messages.insert(0, message);
      
      // 입력 필드 초기화는 UI에서 처리
      
    } catch (e) {
      Get.snackbar('오류', '메시지 전송에 실패했습니다: $e');
    } finally {
      isSending.value = false;
    }
  }

  // 미디어 메시지 전송
  Future<void> sendMediaMessage({
    required String content,
    required MessageMedia media,
    MessageReply? replyTo,
  }) async {
    if (currentChatRoom.value == null) return;
    
    try {
      isSending.value = true;
      
      // 타이핑 상태 종료
      await _messageService.stopTyping(currentChatRoom.value!.id);
      
      // 미디어 메시지 전송
      final message = await _messageService.sendMessage(
        chatRoomId: currentChatRoom.value!.id,
        content: content.trim(),
        type: media.mimeType.startsWith('image/') ? 'image' : 'file',
        media: media,
        replyTo: replyTo,
      );
      
      // 로컬 메시지 목록에 추가
      messages.insert(0, message);
      
    } catch (e) {
      Get.snackbar('오류', '미디어 메시지 전송에 실패했습니다: $e');
    } finally {
      isSending.value = false;
    }
  }

  // 메시지 편집
  Future<void> editMessage(String messageId, String newContent) async {
    if (newContent.trim().isEmpty) return;
    
    try {
      await _messageService.editMessage(messageId, newContent.trim());
      
      // 로컬 메시지 업데이트
      final index = messages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        final updatedMessage = messages[index].edit(newContent.trim());
        messages[index] = updatedMessage;
      }
      
    } catch (e) {
      Get.snackbar('오류', '메시지 편집에 실패했습니다: $e');
    }
  }

  // 메시지 삭제
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      
      // 로컬 메시지 업데이트
      final index = messages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        final deletedMessage = messages[index].delete();
        messages[index] = deletedMessage;
      }
      
    } catch (e) {
      Get.snackbar('오류', '메시지 삭제에 실패했습니다: $e');
    }
  }

  // 메시지 반응 토글
  Future<void> toggleMessageReaction(String messageId, String emoji) async {
    try {
      await _messageService.toggleMessageReaction(messageId, emoji);
      
      // 로컬 메시지 업데이트는 실시간 스트림에서 처리됨
      
    } catch (e) {
      Get.snackbar('오류', '반응 처리에 실패했습니다: $e');
    }
  }

  // 타이핑 시작
  Future<void> startTyping() async {
    if (currentChatRoom.value == null) return;
    
    try {
      await _messageService.startTyping(currentChatRoom.value!.id);
    } catch (e) {
      // 타이핑 시작 실패 처리
    }
  }

  // 타이핑 종료 (디바운스)
  Future<void> stopTyping() async {
    if (currentChatRoom.value == null) return;
    
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingDebounce, () async {
      try {
        await _messageService.stopTyping(currentChatRoom.value!.id);
      } catch (e) {
        // 타이핑 종료 실패 처리
      }
    });
  }

  // 메시지 읽음 표시
  Future<void> markMessageAsRead(String messageId) async {
    if (currentChatRoom.value == null) return;
    
    try {
      await _messageService.markMessageAsRead(
        currentChatRoom.value!.id,
        messageId,
      );
    } catch (e) {
      // 메시지 읽음 표시 실패 처리
    }
  }

  // 메시지 검색
  Future<List<MessageModel>> searchMessages(String query) async {
    if (currentChatRoom.value == null || query.trim().isEmpty) {
      return [];
    }
    
    try {
      return await _messageService.searchMessages(
        chatRoomId: currentChatRoom.value!.id,
        query: query.trim(),
      );
    } catch (e) {
      Get.snackbar('오류', '메시지 검색에 실패했습니다: $e');
      return [];
    }
  }

  // 메시지 통계 조회
  Future<Map<String, dynamic>> getMessageStats() async {
    if (currentChatRoom.value == null) return {};
    
    try {
      return await _messageService.getMessageStats(currentChatRoom.value!.id);
    } catch (e) {
      // 메시지 통계 조회 실패 처리
    }
    return {};
  }

  // 채팅방 나가기
  Future<void> leaveChatRoom() async {
    if (currentChatRoom.value == null) return;
    
    try {
      // 스트림 정리
      _disposeStreams();
      
      // 채팅방 정보 초기화
      currentChatRoom.value = null;
      messages.clear();
      typingUsers.clear();
      currentPage.value = 0;
      hasMoreMessages.value = true;
      
    } catch (e) {
      // 채팅방 나가기 실패 처리
    }
  }

  // 새로고침
  Future<void> refresh() async {
    if (currentChatRoom.value == null) return;
    
    try {
      messages.clear();
      currentPage.value = 0;
      hasMoreMessages.value = true;
      
      await loadInitialMessages();
      
    } catch (e) {
      Get.snackbar('오류', '새로고침에 실패했습니다: $e');
    }
  }

  // 메시지 스크롤 위치 저장
  void saveScrollPosition(int index) {
    // TODO: 스크롤 위치 저장 로직 구현
  }

  // 메시지 스크롤 위치 복원
  int getScrollPosition() {
    // TODO: 스크롤 위치 복원 로직 구현
    return 0;
  }

  // 현재 사용자가 타이핑 중인지 확인
  bool get isCurrentUserTyping {
    // TODO: 현재 사용자 ID 가져오기
    final currentUserId = 'current_user_id';
    return typingUsers[currentUserId] ?? false;
  }

  // 타이핑 중인 다른 사용자 목록
  List<String> get otherTypingUsers {
    // TODO: 현재 사용자 ID 가져오기
    final currentUserId = 'current_user_id';
    return typingUsers.entries
        .where((entry) => entry.key != currentUserId && entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  // 타이핑 상태 메시지
  String get typingStatusMessage {
    final others = otherTypingUsers;
    if (others.isEmpty) return '';
    
    if (others.length == 1) {
      return '${others.first}님이 타이핑 중입니다...';
    } else if (others.length == 2) {
      return '${others.first}님과 ${others.last}님이 타이핑 중입니다...';
    } else {
      return '여러 명이 타이핑 중입니다...';
    }
  }
} 