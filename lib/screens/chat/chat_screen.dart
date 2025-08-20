import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/controllers/chat_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/services/user_repository.dart';
import 'package:typetalk/routes/app_routes.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.put(ChatController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // 연한 파란색 배경
      appBar: _buildAppBar(chatController),
      body: Obx(() {
        // 채팅방이 선택되지 않은 경우: 채팅 목록 또는 빈 상태 표시
        if (chatController.currentChat.value == null) {
          return _buildChatListOrEmpty(chatController);
        }
        // 채팅방이 선택된 경우: 메시지 UI
        return Column(
          children: [
            Expanded(child: _buildMessageList(chatController)),
            _buildMessageInput(chatController),
          ],
        );
      }),
    );
  }

  /// 채팅 목록 또는 빈 상태
  Widget _buildChatListOrEmpty(ChatController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final chats = controller.chatList;
      if (chats.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 56.sp, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(
                '대화창이 없습니다\n지금 바로 대화를 시작해보세요!',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }
      return Column(
        children: [
          // 검색/정렬 바
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => controller.searchQuery.value = v,
                            decoration: const InputDecoration(
                              hintText: '대화 검색',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Obx(() {
                  final desc = controller.sortByRecentDesc.value;
                  return GestureDetector(
                    onTap: () => controller.sortByRecentDesc.value = !desc,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(desc ? Icons.south : Icons.north, size: 16.sp, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text('최근순', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final filtered = controller.visibleChats;
              return ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final chat = filtered[index];
                  final unread = controller.getUnreadCount(chat);
                  return ListTile(
                    leading: Stack(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: Text(
                              chat.title.isNotEmpty ? chat.title.characters.first : 'C',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(chat.title),
                    subtitle: Text(chat.lastMessage?.content ?? '메시지가 없습니다'),
                    trailing: Text(
                      controller.formatMessageTime(chat.stats.lastActivity),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    onTap: () => controller.openChat(chat),
                  );
                },
              );
            }),
          ),
        ],
      );
    });
  }

  /// 앱바 구성
  PreferredSizeWidget _buildAppBar(ChatController controller) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        onPressed: () {
          if (controller.currentChat.value != null) {
            // 채팅 중일 때: 목록으로 돌아가기
            controller.leaveChat();
          } else {
            // 목록 화면일 때: 메인으로 돌아가기
            Get.offAllNamed(AppRoutes.start);
          }
        },
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppColors.textPrimary,
          size: 20.sp,
        ),
      ),
      title: Obx(() {
        final chat = controller.currentChat.value;
        if (chat == null) {
          return Text('채팅');
        }
        return Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  chat.title.isNotEmpty ? chat.title.characters.first : 'C',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                chat.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          tooltip: '사용자 선택',
          onPressed: () => _openUserPicker(controller),
          icon: Icon(
            Icons.person_add_alt_1,
            color: AppColors.textPrimary,
            size: 20.sp,
          ),
        ),
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

  /// 사용자 선택 UI (검색 및 MBTI 필터링 포함)
  void _openUserPicker(ChatController controller) async {
    final users = await Get.find<UserRepository>().getRecentUsers(limit: 50);
    final searchController = TextEditingController();
    final selectedMBTI = 'all'.obs;
    final searchQuery = ''.obs;
    
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '대화할 사용자 선택',
                style: AppTextStyles.titleMedium,
              ),
              SizedBox(height: 16.h),
              
              // 검색 바
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: '이름이나 이메일로 검색',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          searchQuery.value = value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              
              // MBTI 필터
              Text(
                'MBTI 필터',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildMBTIFilterChip('all', '전체', selectedMBTI),
                  _buildMBTIFilterChip('NT', '분석가', selectedMBTI),
                  _buildMBTIFilterChip('NF', '외교관', selectedMBTI),
                  _buildMBTIFilterChip('SJ', '관리자', selectedMBTI),
                  _buildMBTIFilterChip('SP', '탐험가', selectedMBTI),
                ],
              ),
              SizedBox(height: 16.h),
              
              // 사용자 목록
              Expanded(
                child: Obx(() {
                  final filteredUsers = _filterUsers(users, searchQuery.value, selectedMBTI.value);
                  return ListView.separated(
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserListTile(user, controller);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// MBTI 필터 칩 위젯
  Widget _buildMBTIFilterChip(String value, String label, RxString selectedMBTI) {
    return GestureDetector(
      onTap: () => selectedMBTI.value = value,
      child: Obx(() => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selectedMBTI.value == value 
              ? AppColors.primary 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedMBTI.value == value 
                ? Colors.white 
                : AppColors.textPrimary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      )),
    );
  }

  /// 사용자 필터링
  List<UserModel> _filterUsers(List<UserModel> users, String searchQuery, String selectedMBTI) {
    var filtered = users;
    
    // MBTI 카테고리 필터링
    if (selectedMBTI != 'all') {
      filtered = filtered.where((user) {
        final mbti = user.mbtiType ?? '';
        switch (selectedMBTI) {
          case 'NT': return mbti.contains('NT');
          case 'NF': return mbti.contains('NF');
          case 'SJ': return mbti.contains('SJ');
          case 'SP': return mbti.contains('SP');
          default: return true;
        }
      }).toList();
    }
    
    // 검색어 필터링
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((user) =>
        user.name.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query) ||
        (user.mbtiType?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  /// 사용자 목록 아이템 위젯
  Widget _buildUserListTile(UserModel user, ChatController controller) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getMBTIColor(user.mbtiType),
        child: Text(
          user.name.isNotEmpty ? user.name[0] : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Text(user.name),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _getMBTIColor(user.mbtiType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              user.mbtiType ?? 'MBTI',
              style: TextStyle(
                color: _getMBTIColor(user.mbtiType),
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              user.bio!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${user.stats.friendCount}명',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${user.stats.chatCount}채팅',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      onTap: () {
        Get.back();
        controller.startPrivateChatWith(user);
      },
    );
  }

  /// MBTI 색상 반환
  Color _getMBTIColor(String? mbti) {
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