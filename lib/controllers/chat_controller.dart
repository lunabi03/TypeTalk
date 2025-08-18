import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/services/user_repository.dart';
import 'package:typetalk/services/firestore_service.dart';

/// 채팅 화면 컨트롤러
/// 실시간 메시지 전송/수신 및 채팅방 관리를 담당합니다.
class ChatController extends GetxController {
  static ChatController get instance => Get.find<ChatController>();

  final AuthController authController = Get.find<AuthController>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final DemoFirestoreService _firestore = Get.find<DemoFirestoreService>();

  // 현재 채팅방 정보
  Rx<ChatModel?> currentChat = Rx<ChatModel?>(null);
  RxString chatId = ''.obs;
  
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
    _initializeDemoChat();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// 데모 채팅방 초기화
  void _initializeDemoChat() {
    // 데모 채팅방 정보 설정
    currentChat.value = ChatModel(
      chatId: 'demo-enfp-chat',
      type: 'group',
      title: '유진 (ENFP)의 대화',
      description: 'ENFP 성격의 유진과의 1:1 대화',
      createdBy: 'demo-user-enfp',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
      participants: ['demo-user-enfp', authController.userId ?? 'current-user'],
      participantCount: 2,
      maxParticipants: 2,
      targetMBTI: ['ENFP'],
      mbtiCategory: 'NF',
      settings: ChatSettings(
        isPrivate: false,
        allowInvites: false,
        moderatedMode: false,
        autoDelete: false,
      ),
      stats: ChatStats(
        messageCount: 4,
        activeMembers: 2,
        lastActivity: DateTime.now(),
      ),
    );

    chatId.value = currentChat.value!.chatId;
    _initializeDemoMessages();
  }

  /// 데모 메시지 초기화
  void _initializeDemoMessages() {
    final now = DateTime.now();
    final demoMessages = [
      MessageModel(
        messageId: 'msg-001',
        chatId: chatId.value,
        senderId: 'demo-user-enfp',
        senderName: '유진 (ENFP)',
        senderMBTI: 'ENFP',
        content: '안녕하세요! 😊\n프로필 봤어주 좋아하신다구요~\n혹시 최근에 간 여행지 중에\n가장 인상 깊었던 곳은 어디였어요?',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 10)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
      MessageModel(
        messageId: 'msg-002',
        chatId: chatId.value,
        senderId: authController.userId ?? 'current-user',
        senderName: authController.userName ?? '나',
        senderMBTI: authController.userProfile['mbti'] ?? 'ENFP',
        content: '안녕하세요.\n저는 작년 가을에 가족과 가팀구 지적하 나날다.\n케이블카를 하면 임상해서\n만족스러워 여행이었어요.',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 8)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
      MessageModel(
        messageId: 'msg-003',
        chatId: chatId.value,
        senderId: 'demo-user-enfp',
        senderName: '유진 (ENFP)',
        senderMBTI: 'ENFP',
        content: '오 경주 좋죠~!!\n전 그냥 무작정 가서 다니 것다가,\n월리단절에서 감짝 감막 독어다시여운 호황\n케이블카로 올적이는 것 좋아하시는군요.',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 5)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
      MessageModel(
        messageId: 'msg-004',
        chatId: chatId.value,
        senderId: authController.userId ?? 'current-user',
        senderName: authController.userName ?? '나',
        senderMBTI: authController.userProfile['mbti'] ?? 'ENFP',
        content: '네, 즉흥적인 것보다 미리 준비된 일정이\n더 마음이 편해서요.\n유진님도 자유로운 스타일 같네요.\n하원도 감성적으로 하시는 것 같고요.',
        type: MessageType.text.value,
        createdAt: now.subtract(const Duration(minutes: 2)),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp', authController.userId ?? 'current-user'],
        ),
        reactions: {},
      ),
    ];

    messages.assignAll(demoMessages);
    _scrollToBottom();
  }

  /// 메시지 전송
  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty || isSending.value) return;

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

      // 실제 구현에서는 Firestore에 저장
      // await _firestore.collection('messages').doc(newMessage.messageId).set(newMessage.toMap());

      // 데모: 3초 후 자동 응답 (ENFP 스타일)
      _simulateAutoReply();

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

  /// 자동 응답 시뮬레이션 (데모용)
  void _simulateAutoReply() {
    Future.delayed(const Duration(seconds: 3), () {
      final replies = [
        '맞아요! 저도 계획 세우는 것보다\n즉흥적으로 하는 게 더 재미있어요! 😄',
        '와 정말 성향이 다르네요!\n그런데 그게 또 매력적이에요 ✨',
        '계획적인 분들이 부러워요~\n저는 항상 덜렁덜렁해서 😅',
        '오늘 대화 정말 재미있었어요!\n또 얘기해요~ 💕',
      ];

      final randomReply = replies[DateTime.now().second % replies.length];

      final autoReply = MessageModel(
        messageId: 'auto-${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId.value,
        senderId: 'demo-user-enfp',
        senderName: '유진 (ENFP)',
        senderMBTI: 'ENFP',
        content: randomReply,
        type: MessageType.text.value,
        createdAt: DateTime.now(),
        status: MessageStatus(
          isEdited: false,
          isDeleted: false,
          readBy: ['demo-user-enfp'],
        ),
        reactions: {},
      );

      messages.add(autoReply);
      _scrollToBottom();
    });
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
    Get.back();
  }

  /// 채팅방 설정
  void openChatSettings() {
    Get.snackbar('설정', '채팅방 설정 기능은 곧 추가될 예정입니다.');
  }
}
