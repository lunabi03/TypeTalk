import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/controllers/chat_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/models/message_model.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.put(ChatController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // 연한 파란색 배경
      appBar: _buildAppBar(chatController),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: _buildMessageList(chatController),
          ),
          // 메시지 입력창
          _buildMessageInput(chatController),
        ],
      ),
    );
  }

  /// 앱바 구성
  PreferredSizeWidget _buildAppBar(ChatController controller) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        onPressed: () => controller.leaveChat(),
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppColors.textPrimary,
          size: 20.sp,
        ),
      ),
      title: Obx(() {
        final chat = controller.currentChat.value;
        return Row(
          children: [
            // 프로필 아이콘
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: controller.getMBTIColor('ENFP'),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat?.title ?? '채팅',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '온라인', // 실제로는 마지막 접속 시간 표시
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.green,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          onPressed: () => controller.openChatSettings(),
          icon: Icon(
            Icons.more_vert,
            color: AppColors.textPrimary,
            size: 20.sp,
          ),
        ),
      ],
    );
  }

  /// 메시지 목록
  Widget _buildMessageList(ChatController controller) {
    return Obx(() {
      final messages = controller.messages;
      
      if (messages.isEmpty) {
        return const Center(
          child: Text('메시지가 없습니다'),
        );
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMyMessage = controller.isMyMessage(message);
          
          return _buildMessageBubble(message, isMyMessage, controller);
        },
      );
    });
  }

  /// 메시지 버블
  Widget _buildMessageBubble(MessageModel message, bool isMyMessage, ChatController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            // 상대방 프로필 이미지
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: controller.getMBTIColor(message.senderMBTI),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  message.senderMBTI?.substring(0, 1) ?? 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          
          // 메시지 컨테이너
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage) ...[
                  // 상대방 이름과 MBTI
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.senderName ?? '익명',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (message.senderMBTI != null) ...[
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: controller.getMBTIColor(message.senderMBTI),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              message.senderMBTI!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMyMessage) ...[
                      // 시간 (내 메시지 - 왼쪽)
                      Padding(
                        padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
                        child: Text(
                          controller.formatMessageTime(message.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                    
                    // 메시지 버블
                    Flexible(
                      child: GestureDetector(
                        onLongPress: () => _showMessageOptions(message, controller),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isMyMessage 
                                ? const Color(0xFF6C63FF) 
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16.r),
                              topRight: Radius.circular(16.r),
                              bottomLeft: Radius.circular(isMyMessage ? 16.r : 4.r),
                              bottomRight: Radius.circular(isMyMessage ? 4.r : 16.r),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            message.content,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isMyMessage ? Colors.white : AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    if (!isMyMessage) ...[
                      // 시간 (상대방 메시지 - 오른쪽)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
                        child: Text(
                          controller.formatMessageTime(message.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                // 반응 이모지
                if (message.reactions.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  _buildReactions(message, controller),
                ],
              ],
            ),
          ),
          
          if (isMyMessage) ...[
            SizedBox(width: 8.w),
            // 내 프로필 이미지 (선택사항)
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 반응 이모지
  Widget _buildReactions(MessageModel message, ChatController controller) {
    return Wrap(
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        
        return Container(
          margin: EdgeInsets.only(right: 4.w, top: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: 12.sp)),
              if (users.length > 1) ...[
                SizedBox(width: 2.w),
                Text(
                  '${users.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 메시지 입력창
  Widget _buildMessageInput(ChatController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 텍스트 입력 필드
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextField(
                  controller: controller.messageController,
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => controller.sendMessage(),
                ),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // 전송 버튼
            Obx(() => GestureDetector(
              onTap: controller.isSending.value ? null : controller.sendMessage,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: controller.isSending.value 
                      ? Colors.grey 
                      : const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Center(
                  child: controller.isSending.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 메시지 옵션 표시 (길게 누르기)
  void _showMessageOptions(MessageModel message, ChatController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // 메시지 정보
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${message.senderName} • ${controller.formatMessageTime(message.createdAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // 반응 추가
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReactionButton('👍', message, controller),
                _buildReactionButton('❤️', message, controller),
                _buildReactionButton('😂', message, controller),
                _buildReactionButton('😮', message, controller),
                _buildReactionButton('😢', message, controller),
                _buildReactionButton('😡', message, controller),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // 액션 버튼들
            if (!controller.isMyMessage(message)) ...[
              ListTile(
                leading: Icon(Icons.reply, color: AppColors.primary),
                title: Text('답장하기'),
                onTap: () {
                  Get.back();
                  // 답장 기능 구현
                },
              ),
            ],
            
            ListTile(
              leading: Icon(Icons.copy, color: AppColors.textSecondary),
              title: Text('복사하기'),
              onTap: () {
                Get.back();
                // 클립보드에 복사
                Get.snackbar('복사됨', '메시지가 클립보드에 복사되었습니다.');
              },
            ),
            
            if (controller.isMyMessage(message)) ...[
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('삭제하기'),
                onTap: () {
                  Get.back();
                  _confirmDeleteMessage(message, controller);
                },
              ),
            ],
            
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// 반응 버튼
  Widget _buildReactionButton(String emoji, MessageModel message, ChatController controller) {
    final currentUserId = controller.authController.currentUserId ?? 'current-user';
    final isReacted = message.reactions[emoji]?.contains(currentUserId) ?? false;
    
    return GestureDetector(
      onTap: () {
        controller.addReaction(message.messageId, emoji);
        Get.back();
      },
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isReacted ? Colors.blue.withOpacity(0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
    );
  }

  /// 메시지 삭제 확인
  void _confirmDeleteMessage(MessageModel message, ChatController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('메시지 삭제'),
        content: Text('이 메시지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // 메시지 삭제 로직
              controller.messages.removeWhere((m) => m.messageId == message.messageId);
              Get.snackbar('삭제됨', '메시지가 삭제되었습니다.');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('삭제'),
          ),
        ],
      ),
    );
  }
}