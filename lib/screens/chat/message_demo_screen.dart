import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/message_input.dart';
import 'package:typetalk/core/widgets/message_bubble.dart';
import 'package:typetalk/controllers/realtime_chat_controller.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/models/message_model.dart';

/// 메시지 전송 기능을 테스트하기 위한 데모 화면
class MessageDemoScreen extends StatefulWidget {
  const MessageDemoScreen({Key? key}) : super(key: key);

  @override
  State<MessageDemoScreen> createState() => _MessageDemoScreenState();
}

class _MessageDemoScreenState extends State<MessageDemoScreen> {
  final RealtimeChatController _chatController = Get.find<RealtimeChatController>();
  final ScrollController _scrollController = ScrollController();
  
  String? _replyToMessageId;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _initializeDemoChat();
  }

  void _initializeDemoChat() {
    // 데모 채팅방 생성
    final demoChat = ChatModel(
      chatId: 'demo_chat_001',
      title: '메시지 전송 데모',
      description: '메시지 전송 기능을 테스트하는 데모 채팅방입니다.',
      createdBy: 'demo_user',
      type: ChatType.group.value,
      settings: ChatSettings(),
      stats: ChatStats(lastActivity: DateTime.now()),
      participants: ['demo_user', 'user1', 'user2'],
      participantCount: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _chatController.selectChat(demoChat);
    
    // 데모 메시지들 추가
    _addDemoMessages();
  }

  void _addDemoMessages() {
    final demoMessages = [
      MessageModel(
        messageId: 'msg_001',
        chatId: 'demo_chat_001',
        senderId: 'user1',
        senderName: '김철수',
        content: '안녕하세요! 메시지 전송 기능을 테스트해보겠습니다.',
        type: 'text',
        status: MessageStatus(),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      MessageModel(
        messageId: 'msg_002',
        chatId: 'demo_chat_001',
        senderId: 'user2',
        senderName: '이영희',
        content: '안녕하세요! 저도 테스트해보겠습니다.',
        type: 'text',
        status: MessageStatus(),
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      MessageModel(
        messageId: 'msg_003',
        chatId: 'demo_chat_001',
        senderId: 'demo_user',
        senderName: '나',
        content: '반갑습니다! 이제 다양한 메시지 타입을 테스트해보겠습니다.',
        type: 'text',
        status: MessageStatus(),
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      MessageModel(
        messageId: 'msg_004',
        chatId: 'demo_chat_001',
        senderId: 'user1',
        senderName: '김철수',
        content: '이모지도 사용할 수 있나요? 😀',
        type: 'text',
        status: MessageStatus(),
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      MessageModel(
        messageId: 'msg_005',
        chatId: 'demo_chat_001',
        senderId: 'user2',
        senderName: '이영희',
        content: '네! 다양한 이모지를 사용할 수 있습니다. 🎉✨',
        type: 'text',
        status: MessageStatus(),
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];
    
    _chatController.messages.assignAll(demoMessages);
  }

  void _handleMessageSent() {
    // 메시지 전송 완료 후 스크롤을 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // 답장 모드 해제
    setState(() {
      _replyToMessageId = null;
    });
  }

  void _handleCancelReply() {
    setState(() {
      _replyToMessageId = null;
    });
  }

  void _showMessageOptions(MessageModel message) {
    final isOwnMessage = message.senderId == 'demo_user';
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 답장
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.primary),
              title: const Text('답장'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessageId = message.messageId;
                });
              },
            ),
            
            // 반응
            ListTile(
              leading: const Icon(Icons.emoji_emotions, color: AppColors.primary),
              title: const Text('반응'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(message);
              },
            ),
            
            // 복사
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.primary),
              title: const Text('복사'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
            
            // 자신의 메시지인 경우에만 편집/삭제 표시
            if (isOwnMessage) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('편집'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('삭제', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(MessageModel message) {
    final reactions = ['😀', '😂', '😍', '🥰', '😎', '🤔', '👍', '👎', '❤️', '🔥', '💯', '✨'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반응 선택'),
        content: Container(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: reactions.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _addReaction(message, reactions[index]);
                },
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    reactions[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _addReaction(MessageModel message, String emoji) {
    try {
      _chatController.toggleReaction(message.messageId, emoji);
      Get.snackbar(
        '성공',
        '반응이 추가되었습니다: $emoji',
        backgroundColor: AppColors.success,
        colorText: AppColors.white,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '반응 추가에 실패했습니다: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
    }
  }

  void _copyMessage(MessageModel message) {
    // TODO: 실제 클립보드 복사 구현
    Get.snackbar(
      '알림',
      '메시지가 복사되었습니다: ${message.content}',
      backgroundColor: AppColors.primary,
      colorText: AppColors.white,
    );
  }

  void _editMessage(MessageModel message) {
    // TODO: 메시지 편집 다이얼로그 구현
    Get.snackbar(
      '알림',
      '메시지 편집 기능은 개발 중입니다.',
      backgroundColor: AppColors.primary,
      colorText: AppColors.white,
    );
  }

  void _deleteMessage(MessageModel message) {
    Get.dialog(
      AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              try {
                _chatController.deleteMessage(message.messageId);
                Get.snackbar(
                  '성공',
                  '메시지가 삭제되었습니다.',
                  backgroundColor: AppColors.success,
                  colorText: AppColors.white,
                );
              } catch (e) {
                Get.snackbar(
                  '오류',
                  '메시지 삭제에 실패했습니다: $e',
                  backgroundColor: AppColors.error,
                  colorText: AppColors.white,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메시지 전송 데모'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _addDemoMessages();
              Get.snackbar(
                '알림',
                '데모 메시지가 새로고침되었습니다.',
                backgroundColor: AppColors.primary,
                colorText: AppColors.white,
              );
            },
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 채팅방 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.lightGrey),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '💬',
                    style: AppTextStyles.h6.copyWith(color: AppColors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _chatController.currentChat?.title ?? '데모 채팅방',
                        style: AppTextStyles.h6.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_chatController.messages.length}개의 메시지',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 메시지 목록
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (_chatController.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '아직 메시지가 없습니다.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '첫 번째 메시지를 보내보세요!',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = _chatController.messages[index];
                  return MessageBubble(
                    message: message,
                    isOwnMessage: message.senderId == 'demo_user',
                    onLongPress: () => _showMessageOptions(message),
                  );
                },
              );
            }),
          ),
          
          // 타이핑 상태 표시
          Obx(() {
            final typingUsers = _chatController.typingUsers;
            if (typingUsers.isEmpty) return const SizedBox.shrink();
            
            final typingUserNames = typingUsers.keys
                .where((userId) => userId != 'demo_user')
                .map((userId) => userId == 'user1' ? '김철수' : '이영희')
                .toList();
            
            if (typingUserNames.isEmpty) return const SizedBox.shrink();
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.background,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${typingUserNames.join(', ')}님이 타이핑 중입니다...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
          
          // 메시지 입력
          MessageInput(
            onSendMessage: (text) {
              // TODO: 메시지 전송 로직 구현
              Get.snackbar('알림', '메시지 전송 기능은 개발 중입니다.');
            },
            replyTo: _replyToMessageId != null ? MessageReply(
              messageId: _replyToMessageId!,
              content: '답장할 메시지',
              senderId: 'demo_user',
            ) : null,
            onMessageSent: (text) => _handleMessageSent(),
            onCancelReply: () => _handleCancelReply(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
