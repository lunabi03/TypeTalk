import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/services/notification_service.dart';

import 'package:typetalk/controllers/profile_controller.dart';

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

  /// 설정 패널 표시
  void _showSettingsPanel() {
    // ProfileController 초기화 (회원 탈퇴 기능을 위해)
    Get.put(ProfileController());
    
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
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
                    '설정',
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
            // 설정 옵션들
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // 위치 권한 설정
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '위치 권한',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '가까운 사용자를 찾기 위해 필요합니다',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // 위치 권한 상태 표시
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[600],
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '위치 권한을 허용하면 가까운 사용자를 찾을 수 있습니다',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // 권한 요청 버튼들
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.snackbar(
                                    '알림',
                                    '위치 기반 서비스는 현재 사용하지 않습니다.',
                                    backgroundColor: Colors.orange.withOpacity(0.1),
                                    colorText: Colors.orange,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '위치 권한 설정',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            OutlinedButton(
                              onPressed: () {
                                Get.snackbar(
                                  '알림',
                                  '위치 기반 서비스는 현재 사용하지 않습니다.',
                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                  colorText: Colors.orange,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primary),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                '시스템 설정',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // 기타 설정 옵션들
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              color: Colors.grey[600],
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '알림 설정',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '채팅 초대 및 메시지 알림',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // 회원 탈퇴 섹션
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.red[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.delete_forever_outlined,
                              color: Colors.red[600],
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '회원 탈퇴',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  Text(
                                    '계정과 모든 데이터를 영구적으로 삭제합니다',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.red[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_outlined,
                                color: Colors.red[700],
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '회원 탈퇴 시 모든 프로필 정보, 채팅 기록, MBTI 결과가 영구적으로 삭제되며 복구할 수 없습니다.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showDeleteAccountDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              '회원 탈퇴',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 위치 권한 설정 다이얼로그 표시 (사용하지 않음)
  void _showLocationPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              '위치 권한 설정',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TypeMate에서 위치 정보를 사용하는 이유:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            _buildPermissionReason(
              Icons.people,
              '가까운 사용자 찾기',
              '주변에 있는 새로운 친구를 발견할 수 있습니다',
            ),
            SizedBox(height: 8.h),
            _buildPermissionReason(
              Icons.place,
              '지역 기반 추천',
              '같은 지역의 사용자와 더 쉽게 연결됩니다',
            ),
            SizedBox(height: 8.h),
            _buildPermissionReason(
              Icons.security,
              '프라이버시 보호',
              '정확한 위치는 저장되지 않으며, 대략적인 거리만 계산됩니다',
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.blue[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '위치 권한은 언제든지 설정에서 변경할 수 있습니다',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '나중에',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                '알림',
                '위치 기반 서비스는 현재 사용하지 않습니다.',
                backgroundColor: Colors.orange.withOpacity(0.1),
                colorText: Colors.orange,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              '권한 허용',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 권한 이유 설명 위젯
  Widget _buildPermissionReason(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 회원 탈퇴 확인 다이얼로그 표시
  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.delete_forever_outlined,
              color: Colors.red[600],
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              '회원 탈퇴',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정말로 회원 탈퇴를 진행하시겠습니까?',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '삭제되는 데이터:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildDeleteItem('프로필 정보'),
                  _buildDeleteItem('MBTI 테스트 결과'),
                  _buildDeleteItem('채팅 기록'),
                  _buildDeleteItem('친구 목록'),
                  _buildDeleteItem('알림 설정'),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '⚠️ 이 작업은 되돌릴 수 없으며, 모든 데이터가 영구적으로 삭제됩니다.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              '회원 탈퇴',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 삭제될 항목 위젯
  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, top: 4.h),
      child: Row(
        children: [
          Icon(
            Icons.remove_circle_outline,
            color: Colors.red[600],
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 회원 탈퇴 최종 확인 및 실행
  void _confirmDeleteAccount() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              '최종 확인',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '회원 탈퇴를 진행하시겠습니까?',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _executeDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              '탈퇴 진행',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 회원 탈퇴 실행
  void _executeDeleteAccount() async {
    try {
      // ProfileController를 통해 회원 탈퇴 실행
      final profileController = Get.find<ProfileController>();
      final success = await profileController.deleteUserProfile(confirmDelete: true);
      
      if (success) {
        Get.snackbar(
          '회원 탈퇴 완료',
          '계정이 성공적으로 삭제되었습니다.',
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
          duration: const Duration(seconds: 3),
        );
        // 로그인 화면으로 이동
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '회원 탈퇴 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
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
                            onPressed: () async {
                              // 알림 패널 열기 전 최신 데이터 새로고침
                              // (채팅 초대/채팅 알림이 최신 상태로 표시되도록 보장)
                              await notificationService.refreshNotifications();
                              _showNotificationPanel(notificationService);
                            },
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
                      onPressed: () => _showSettingsPanel(),
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
                        'MBTI 테스트 시작하기',
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