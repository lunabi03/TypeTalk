import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/controllers/realtime_chat_controller.dart';

/// 메시지 표시를 위한 전용 위젯
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwnMessage;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyTap;
  final VoidCallback? onReactionTap;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isOwnMessage,
    this.onLongPress,
    this.onReplyTap,
    this.onReactionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isOwnMessage ? 50 : 16,
        right: isOwnMessage ? 16 : 50,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isOwnMessage 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          // 답장 표시
          if (message.replyTo != null) ...[
            _buildReplyPreview(),
            const SizedBox(height: 4),
          ],
          
          // 메시지 버블
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOwnMessage 
                    ? AppColors.primary 
                    : AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 발신자 이름 (자신이 아닌 경우만 표시)
                  if (!isOwnMessage) ...[
                    Text(
                      message.senderName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // 메시지 내용
                  _buildMessageContent(),
                  
                  // 메시지 메타데이터
                  const SizedBox(height: 4),
                  _buildMessageMetadata(),
                ],
              ),
            ),
          ),
          
          // 반응 표시
          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildReactions(),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.replyTo!.senderName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  message.replyTo!.content,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case 'text':
        return Text(
          message.content,
          style: AppTextStyles.body.copyWith(
            color: isOwnMessage ? AppColors.white : AppColors.textPrimary,
          ),
        );
      
      case 'media':
        return _buildMediaContent();
      
      case 'file':
        return _buildFileContent();
      
      case 'location':
        return _buildLocationContent();
      
      default:
        return Text(
          message.content,
          style: AppTextStyles.body.copyWith(
            color: isOwnMessage ? AppColors.white : AppColors.textPrimary,
          ),
        );
    }
  }

  Widget _buildMediaContent() {
    if (message.media == null) {
      return Text(
        message.content,
        style: AppTextStyles.body.copyWith(
          color: isOwnMessage ? AppColors.white : AppColors.textPrimary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 미디어 표시
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: message.media!.mimeType.startsWith('image/')
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.media!.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image,
                        size: 48,
                        color: AppColors.textSecondary,
                      );
                    },
                  ),
                )
              : const Icon(
                  Icons.video_file,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
        ),
        
        // 캡션이 있는 경우
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: AppTextStyles.body.copyWith(
              color: isOwnMessage ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent() {
    if (message.media == null) {
      return Text(
        message.content,
        style: AppTextStyles.body.copyWith(
          color: isOwnMessage ? AppColors.white : AppColors.textPrimary,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.attach_file,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.media!.fileName ?? '파일',
                style: AppTextStyles.body.copyWith(
                  color: isOwnMessage ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.media!.fileSize != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(message.media!.fileSize!),
                  style: AppTextStyles.caption.copyWith(
                    color: isOwnMessage 
                        ? AppColors.white.withOpacity(0.8) 
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationContent() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '위치 공유됨',
            style: AppTextStyles.body.copyWith(
              color: isOwnMessage ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageMetadata() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 시간
        Text(
          _formatTime(message.createdAt),
          style: AppTextStyles.caption.copyWith(
            color: isOwnMessage 
                ? AppColors.white.withOpacity(0.8) 
                : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        
        // 편집 표시
        if (message.isEdited) ...[
          const SizedBox(width: 8),
          Text(
            '(편집됨)',
            style: AppTextStyles.caption.copyWith(
              color: isOwnMessage 
                  ? AppColors.white.withOpacity(0.8) 
                  : AppColors.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        
        // 읽음 표시 (자신의 메시지인 경우만)
        if (isOwnMessage) ...[
          const SizedBox(width: 8),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 16,
            color: message.isRead 
                ? AppColors.white.withOpacity(0.8) 
                : AppColors.white.withOpacity(0.6),
          ),
        ],
      ],
    );
  }

  Widget _buildReactions() {
    return Wrap(
      spacing: 4,
      children: message.reactions.entries.map((entry) {
        return GestureDetector(
          onTap: onReactionTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.value}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate.isAtSameMomentAs(today)) {
      // 오늘: HH:MM
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      // 어제: 어제 HH:MM
      return '어제 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // 그 이전: MM/DD HH:MM
      return '${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 메시지 목록을 표시하는 위젯
class MessageList extends StatelessWidget {
  final List<MessageModel> messages;
  final String currentUserId;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMoreMessages;

  const MessageList({
    Key? key,
    required this.messages,
    required this.currentUserId,
    this.scrollController,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && hasMoreMessages) {
          return _buildLoadMoreButton();
        }
        
        final messageIndex = hasMoreMessages ? index - 1 : index;
        final message = messages[messageIndex];
        final isOwnMessage = message.senderId == currentUserId;
        
        return MessageBubble(
          message: message,
          isOwnMessage: isOwnMessage,
          onLongPress: () => _showMessageOptions(context, message),
          onReplyTap: () => _handleReplyTap(message),
          onReactionTap: () => _handleReactionTap(message),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton(
          onPressed: isLoadingMore ? null : onLoadMore,
          child: isLoadingMore
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('더 많은 메시지 로드'),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    final isOwnMessage = message.senderId == currentUserId;
    
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
                _handleReplyTap(message);
              },
            ),
            
            // 반응
            ListTile(
              leading: const Icon(Icons.emoji_emotions, color: AppColors.primary),
              title: const Text('반응'),
              onTap: () {
                Navigator.pop(context);
                _handleReactionTap(message);
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
                  _handleEditMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('삭제', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleReplyTap(MessageModel message) {
    final controller = Get.find<RealtimeChatController>();
    controller.selectMessage(message);
  }

  void _handleReactionTap(MessageModel message) {
    // TODO: 반응 선택 다이얼로그 구현
    Get.snackbar('알림', '반응 선택 기능은 개발 중입니다.');
  }

  void _copyMessage(MessageModel message) {
    // TODO: 메시지 복사 구현
    Get.snackbar('알림', '메시지가 복사되었습니다.');
  }

  void _handleEditMessage(MessageModel message) {
    final controller = Get.find<RealtimeChatController>();
    controller.startEditingMessage(message);
  }

  void _handleDeleteMessage(MessageModel message) {
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
              final controller = Get.find<RealtimeChatController>();
              controller.deleteMessage(message.messageId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

