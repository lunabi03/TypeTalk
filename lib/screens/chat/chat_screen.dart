import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/controllers/chat_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/services/chat_invite_service.dart';
import 'package:typetalk/models/chat_invite_model.dart';
import 'package:typetalk/routes/app_routes.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatController chatController;
  late final ChatInviteService? inviteService;
  late final FocusNode _inputFocusNode; // 입력창 포커스 감지용
  double _lastBottomInset = 0; // 키보드 인셋 변화 추적

  @override
  void initState() {
    super.initState();
    chatController = Get.find<ChatController>();
    inviteService = Get.isRegistered<ChatInviteService>() ? Get.find<ChatInviteService>() : null;
    _inputFocusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this); // 키보드 인셋 변화 감지 시작
    
    // 입력창에 포커스가 생기면 약간의 지연 후 하단으로 스크롤
    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 120), _scrollToBottomSmooth);
      }
    });
    
    // 화면이 로드될 때마다 채팅 목록 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatController.loadChatList();
    });
  }

  @override
  void didChangeMetrics() {
    // 키보드 인셋(하단)이 증가하면(=키보드 표시) 하단으로 스크롤
    final currentInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (currentInset > _lastBottomInset && currentInset > 0) {
      Future.delayed(const Duration(milliseconds: 150), _scrollToBottomSmooth);
    }
    _lastBottomInset = currentInset.toDouble();
    super.didChangeMetrics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // 연한 파란색 배경
      resizeToAvoidBottomInset: true, // 키보드가 올라올 때 화면 크기 조정
      appBar: _buildAppBar(),
      body: Obx(() {
        // 채팅방이 선택되지 않은 경우: 채팅 목록 또는 빈 상태 표시
        if (chatController.currentChat.value == null) {
          return Column(
            children: [
              // 초대 알림 표시 (서비스가 사용 가능할 때만)
              if (inviteService != null && inviteService!.pendingInviteCount > 0) 
                _buildInviteNotification(inviteService!),
              // 채팅 목록 또는 빈 상태
              Expanded(child: _buildChatListOrEmpty()),
            ],
          );
        }
        // 채팅방이 선택된 경우: 메시지 UI
        return Column(
          children: [
            // 메시지 리스트가 키보드 인셋을 정상 반영하도록 수정
            Expanded(
              child: _buildMessageList(),
            ),
            _buildMessageInput(),
          ],
        );
      }),
      // 채팅 목록 화면에서만 네비게이션바 표시, 대화방 입장 시 숨김
      bottomNavigationBar: Obx(() {
        final isChatRoomOpen = chatController.currentChat.value != null;
        if (isChatRoomOpen) return const SizedBox.shrink();
        return Container(
          height: 80,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 2,
            onTap: (index) {
              if (index == 0) {
                Get.offAllNamed(AppRoutes.start);
              } else if (index == 1) {
                Get.offAllNamed(AppRoutes.profile);
              }
            },
            showUnselectedLabels: true,
            selectedItemColor: const Color(0xFF5C3DF7),
            unselectedItemColor: const Color(0xFF9FA4B0),
            selectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            backgroundColor: Colors.white,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome, size: 28),
                activeIcon: Icon(Icons.auto_awesome, size: 28),
                label: 'MBTI 테스트',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 28),
                activeIcon: Icon(Icons.person, size: 28),
                label: '프로필',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble, size: 28),
                activeIcon: Icon(Icons.chat_bubble, size: 28),
                label: '채팅',
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 초대 알림 위젯
  Widget _buildInviteNotification(ChatInviteService inviteService) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mail_outline,
                color: const Color(0xFFFF9800),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '새로운 채팅 초대',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF9800),
                ),
              ),
              const Spacer(),
              Text(
                '${inviteService.pendingInviteCount}개',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '채팅 초대를 확인하고 응답해주세요.',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFFFF9800),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showInviteList(inviteService),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              child: Text(
                '초대 확인하기',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 초대 목록 표시
  void _showInviteList(ChatInviteService inviteService) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '채팅 초대',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // 초대 목록
            Expanded(
              child: Obx(() {
                if (inviteService.receivedInvites.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '받은 초대가 없습니다',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: inviteService.receivedInvites.length,
                  itemBuilder: (context, index) {
                    final invite = inviteService.receivedInvites[index];
                    return _buildInviteItem(invite, inviteService);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 초대 아이템 위젯
  Widget _buildInviteItem(ChatInviteModel invite, ChatInviteService inviteService) {
    return FutureBuilder(
      future: _getUserInfo(invite.invitedBy),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : '?',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : '사용자',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${user.mbtiType ?? 'MBTI 미설정'} • ${_formatTime(invite.createdAt)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (invite.hasMessage) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    invite.metadata.message!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineInvite(invite.inviteId, inviteService),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        '거절',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptInvite(invite, inviteService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text('수락'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 사용자 정보 가져오기
  Future<UserModel?> _getUserInfo(String userId) async {
    try {
      final userRepository = Get.find<RealUserRepository>();
      return await userRepository.getUser(userId);
    } catch (e) {
      print('사용자 정보 조회 실패: $e');
      return null;
    }
  }

  /// 시간 포맷팅
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  /// 정확한 시간 표시 (디버그용)
  String _formatExactTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  /// 초대 수락
  Future<void> _acceptInvite(ChatInviteModel invite, ChatInviteService inviteService) async {
    try {
      final success = await inviteService.acceptInvite(invite.inviteId);
      if (success) {
        Get.back(); // 바텀시트 닫기
        Get.snackbar(
          '초대 수락', 
          '채팅방이 열렸습니다!',
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
          colorText: const Color(0xFF4CAF50),
        );
        
                 // 채팅방 열기
         final chatController = Get.find<ChatController>();
         final chat = await chatController.getChatById(invite.chatId);
         if (chat != null) {
           await chatController.openChat(chat);
         }
      }
    } catch (e) {
      Get.snackbar(
        '오류', 
        '초대 수락에 실패했습니다: ${e.toString()}',
        backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
        colorText: const Color(0xFFFF0000),
      );
    }
  }

  /// 초대 거절
  Future<void> _declineInvite(String inviteId, ChatInviteService inviteService) async {
    try {
      final success = await inviteService.declineInvite(inviteId);
      if (success) {
        Get.snackbar(
          '초대 거절', 
          '초대를 거절했습니다.',
          backgroundColor: Colors.grey.withOpacity(0.1),
          colorText: Colors.grey[700],
        );
      }
    } catch (e) {
      Get.snackbar(
        '오류', 
        '초대 거절에 실패했습니다: ${e.toString()}',
        backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
        colorText: const Color(0xFFFF0000),
      );
    }
  }

  /// 채팅 목록 또는 빈 상태
  Widget _buildChatListOrEmpty() {
    return Obx(() {
      if (chatController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final chats = chatController.chatList;
      print('🖥️ UI 업데이트 - 채팅 목록 개수: ${chats.length}');
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
              SizedBox(height: 16.h),
              // 빈 상태에서도 대화 상대 찾기 버튼 제공
              SizedBox(
                width: 220.w,
                child: ElevatedButton.icon(
                  onPressed: () => _showFindChatPartnerDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.person_add, size: 18.sp),
                  label: Text(
                    '대화 상대 찾기',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                            onChanged: (v) => chatController.searchQuery.value = v,
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
                  final desc = chatController.sortByRecentDesc.value;
                  return GestureDetector(
                    onTap: () => chatController.sortByRecentDesc.value = !desc,
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
          // 대화 상대 찾기 버튼
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFindChatPartnerDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.person_add, size: 20.sp),
                label: Text(
                  '대화 상대 찾기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final filtered = chatController.visibleChats;
              return ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final chat = filtered[index];
                  final unread = chatController.getUnreadCount(chat);
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
                      chatController.formatMessageTime(chat.stats.lastActivity),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    onTap: () => chatController.openChat(chat),
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
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        onPressed: () {
          if (chatController.currentChat.value != null) {
            // 채팅 중일 때: 목록으로 돌아가기
            chatController.leaveChat();
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
        final chat = chatController.currentChat.value;
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
          onPressed: () => chatController.openChatSettings(),
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
  Widget _buildMessageList() {
    return Obx(() {
      final messages = chatController.messages;
      
      if (messages.isEmpty) {
        return const Center(
          child: Text('메시지가 없습니다'),
        );
      }

      // 메시지 목록을 시간순으로 정렬 (UI 표시용)
      final sortedMessages = List<MessageModel>.from(messages);
      sortedMessages.sort((a, b) {
        final timeComparison = a.createdAt.compareTo(b.createdAt);
        if (timeComparison != 0) return timeComparison;
        return a.messageId.compareTo(b.messageId);
      });

      return ListView.builder(
        controller: chatController.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: sortedMessages.length,
        itemBuilder: (context, index) {
          final message = sortedMessages[index];
          final isMyMessage = chatController.isMyMessage(message);
          
          return _buildMessageBubble(message, isMyMessage);
        },
      );
    });
  }

  /// 메시지 버블
  Widget _buildMessageBubble(MessageModel message, bool isMyMessage) {
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
                color: chatController.getMBTIColor(message.senderMBTI),
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
                              color: chatController.getMBTIColor(message.senderMBTI),
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
                          chatController.formatMessageTime(message.createdAt),
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
                        onLongPress: () => _showMessageOptions(message),
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
                          chatController.formatMessageTime(message.createdAt),
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
                  _buildReactions(message),
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
  Widget _buildReactions(MessageModel message) {
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
  Widget _buildMessageInput() {
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
                  controller: chatController.messageController,
                  focusNode: _inputFocusNode, // 포커스 연결
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
                  onSubmitted: (_) => chatController.sendMessage(),
                  onTap: _scrollToBottomSmooth, // 탭 시에도 하단으로 스크롤
                ),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // 전송 버튼
            Obx(() => GestureDetector(
              onTap: chatController.isSending.value ? null : chatController.sendMessage,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: chatController.isSending.value 
                      ? Colors.grey 
                      : const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Center(
                  child: chatController.isSending.value
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

  // 화면 하단으로 부드럽게 스크롤 (키보드가 올라와도 마지막 말풍선이 보이도록)
  void _scrollToBottomSmooth() {
    final controller = chatController.scrollController;
    if (!controller.hasClients) return;
    // 프레임 반영 후 실행하여 안전하게 최대 스크롤 값 계산
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// 메시지 옵션 표시 (길게 누르기)
  void _showMessageOptions(MessageModel message) {
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
                    '${message.senderName} • ${chatController.formatMessageTime(message.createdAt)}',
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
                _buildReactionButton('👍', message),
                _buildReactionButton('❤️', message),
                _buildReactionButton('😂', message),
                _buildReactionButton('😮', message),
                _buildReactionButton('😢', message),
                _buildReactionButton('😡', message),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // 액션 버튼들
            if (!chatController.isMyMessage(message)) ...[
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
            
            if (chatController.isMyMessage(message)) ...[
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('삭제하기'),
                onTap: () {
                  Get.back();
                  _confirmDeleteMessage(message);
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
    final users = await Get.find<RealUserRepository>().getRecentUsers(limit: 50);
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
        chatController.startPrivateChatWith(user);
      },
    );
  }



  /// 반응 버튼
  Widget _buildReactionButton(String emoji, MessageModel message) {
    final currentUserId = chatController.authController.currentUserId ?? 'current-user';
    final isReacted = message.reactions[emoji]?.contains(currentUserId) ?? false;
    
    return GestureDetector(
      onTap: () {
        chatController.addReaction(message.messageId, emoji);
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
  void _confirmDeleteMessage(MessageModel message) {
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
              chatController.messages.removeWhere((m) => m.messageId == message.messageId);
              Get.snackbar('삭제됨', '메시지가 삭제되었습니다.');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// MBTI 색상 반환
  Color _getMBTIColor(String? mbti) {
    if (mbti == null || mbti.isEmpty) return Colors.grey;
    
    // MBTI별 색상 매핑
    final colors = {
      'ENFP': Colors.orange,
      'INTJ': Colors.indigo,
      'ISFP': Colors.teal,
      'ENTP': Colors.purple,
      'INFJ': Colors.pink,
      'ESTJ': Colors.blue,
      'INFP': Colors.green,
      'ISTP': Colors.brown,
      'ENFJ': Colors.red,
      'ISTJ': Colors.cyan,
      'ESFP': Colors.amber,
      'ENTJ': Colors.deepPurple,
      'ESFJ': Colors.lightBlue,
      'INTP': Colors.deepOrange,
    };
    
    return colors[mbti] ?? Colors.grey;
  }

  /// 대화 상대 찾기 다이얼로그 표시
  void _showFindChatPartnerDialog() {
    Get.toNamed(AppRoutes.findChatPartner);
  }
}