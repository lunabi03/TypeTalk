import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/services/notification_service.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  /// 알림 패널 표시
  void _showNotificationPanel(NotificationService notificationService) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
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
                    '알림',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // 모든 알림 읽음 처리
                  if (notificationService.unreadCount.value > 0)
                    TextButton(
                      onPressed: () {
                        notificationService.markAllAsRead();
                        Get.back();
                      },
                      child: Text(
                        '모두 읽음',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // 알림 목록
            Expanded(
              child: Obx(() {
                if (notificationService.allNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 48.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '새로운 알림이 없습니다',
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
                  itemCount: notificationService.allNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationService.allNotifications[index];
                    return _buildNotificationItem(notification, notificationService);
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

  /// 알림 아이템 위젯
  Widget _buildNotificationItem(NotificationItem notification, NotificationService notificationService) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: notification.isRead ? Colors.grey.withOpacity(0.2) : Color(int.parse(notification.color.replaceAll('#', '0xFF'))),
          width: 1,
        ),
        boxShadow: notification.isRead ? null : [
          BoxShadow(
            color: Color(int.parse(notification.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                notification.icon,
                style: TextStyle(fontSize: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: notification.isRead ? Colors.grey : Colors.black,
                      ),
                    ),
                    Text(
                      notification.relativeTime,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // 읽음 처리 버튼
              if (!notification.isRead)
                IconButton(
                  onPressed: () => notificationService.markAsRead(notification.id),
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.grey,
                  iconSize: 20.sp,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 14.sp,
              color: notification.isRead ? Colors.grey[600] : Colors.black87,
            ),
          ),
          // 알림 타입별 액션 버튼
          if (notification.type == NotificationType.chatInvite && !notification.isRead) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleChatInvite(notification, notificationService),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '초대 확인하기',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 채팅 초대 처리
  void _handleChatInvite(NotificationItem notification, NotificationService notificationService) {
    // 알림을 읽음 처리
    notificationService.markAsRead(notification.id);
    
    // 채팅 화면으로 이동
    Get.back(); // 알림 패널 닫기
    Get.toNamed(AppRoutes.chat);
    
    Get.snackbar(
      '초대 확인', 
      '채팅 화면에서 초대를 확인할 수 있습니다.',
      backgroundColor: AppColors.primary.withOpacity(0.1),
      colorText: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF3FF), Colors.white],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.diagonal3Values(1.08, 0.85, 1.0),
                      child: Text(
                        'TypeMate',
                        style: TextStyle(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 알림 아이콘
                    Obx(() {
                      final notificationService = Get.find<NotificationService>();
                      return Stack(
                        children: [
                          IconButton(
                            onPressed: () => _showNotificationPanel(notificationService),
                            icon: const Icon(Icons.notifications_outlined),
                            color: Colors.black87,
                          ),
                          // 읽지 않은 알림 개수 표시
                          if (notificationService.unreadCount.value > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20.w,
                                  minHeight: 20.h,
                                ),
                                child: Text(
                                  '${notificationService.unreadCount.value}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                    IconButton(
                      onPressed: () => Get.snackbar('설정', '설정 화면은 준비 중입니다.'),
                      icon: const Icon(Icons.settings_outlined),
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 36.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 6.h),
                    Text(
                      '나의 MBTI 유형은?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27.sp,
                        height: 1.22,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '간단한 질문을 통해 나의 성격 유형을\n알아보고 더 나은 자신을 발견해보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                        letterSpacing: -0.1,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/home_image.png',
                    width: 356.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -5.h),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.question),
                      style: ElevatedButton.styleFrom(
                        // Start Screen.png 기준 보라색, 텍스트는 화이트로 고정
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '테스트 시작하기',
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // FCM 데모 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.toNamed(AppRoutes.fcmDemo),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'FCM 데모 화면',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Get.toNamed(AppRoutes.profile);
            } else if (index == 2) {
              Get.toNamed(AppRoutes.chat);
            }
          },
          showUnselectedLabels: true,
          selectedItemColor: const Color(0xFF5C3DF7),
          unselectedItemColor: Color(0xFF9FA4B0),
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
              icon: Icon(Icons.chat_bubble_outline, size: 28),
              activeIcon: Icon(Icons.chat_bubble, size: 28),
              label: '채팅',
            ),
          ],
        ),
      ),
    );
  }
}