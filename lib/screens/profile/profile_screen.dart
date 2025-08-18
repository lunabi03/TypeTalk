import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/controllers/profile_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileController = Get.put(ProfileController());
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and logout button
            Padding(
              padding: EdgeInsets.only(left: 24.w, top: 12.h, bottom: 16.h, right: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '마이 프로필',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Row(
                    children: [
                      // 새로고침 버튼
                      IconButton(
                        onPressed: () {
                          profileController.refreshProfile();
                          authController.refreshProfile();
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF007AFF),
                        ),
                        tooltip: '프로필 새로고침',
                      ),
                      // 디버그 버튼 (실제 Firebase 데이터 확인)
                      IconButton(
                        onPressed: () {
                          authController.debugCheckUserData();
                        },
                        icon: const Icon(
                          Icons.cloud_done,
                          color: Color(0xFF007AFF),
                        ),
                        tooltip: 'Firebase 데이터 확인',
                      ),
                      IconButton(
                        onPressed: () {
                          authController.logout();
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Profile Information Section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    // Profile Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Column(
                        children: [
                          // Profile Icon
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Image.asset(
                                'assets/images/_icon_profile.png',
                                width: 60.w,
                                height: 60.w,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          
                          // User Name
                          Obx(() => Text(
                            authController.userName ?? '사용자',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          )),
                          SizedBox(height: 8.h),
                          
                          // Email
                          Obx(() => Text(
                            '이메일: ${authController.currentUserEmail ?? ''}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF6C757D),
                              height: 1.3,
                            ),
                          )),
                          SizedBox(height: 4.h),
                          
                          // Join Date
                          Obx(() {
                            final createdAt = authController.userProfile['createdAt'];
                            String joinDate = '2024.03.21'; // 기본값
                            if (createdAt != null) {
                              try {
                                final date = (createdAt as dynamic).toDate();
                                joinDate = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                              } catch (e) {
                                print('날짜 변환 오류: $e');
                              }
                            }
                            return Text(
                              '가입일: $joinDate',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF6C757D),
                                height: 1.3,
                              ),
                            );
                          }),
                          SizedBox(height: 16.h),
                          
                          // Edit Information Button
                          Center(
                            child: GestureDetector(
                              onTap: () => Get.toNamed('/profile/edit'),
                              child: Container(
                                width: 100.w,
                                height: 36.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFFDEE2E6),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '내 정보 수정',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF495057),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // MBTI Result Banner
                    Container(
                      width: double.infinity,
                      height: 100.h,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: Image.asset(
                          'assets/images/banner_enfp.png',
                          width: double.infinity,
                          height: 100.h,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Profile Statistics Cards
                    Obx(() {
                      final stats = profileController.profileStats;
                      return Column(
                        children: [
                          // MBTI Test Completion Card
                          Container(
                            width: double.infinity,
                            height: 88.h,
                            padding: EdgeInsets.all(18.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'MBTI 테스트 완료',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        '현재 유형: ${authController.currentUserMBTI ?? "미완료"}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF6C757D),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  '${stats['mbtiTestCount'] ?? 0}회',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          // Profile Completeness Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(18.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '프로필 완성도',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    Text(
                                      '${(profileController.profileCompleteness * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF007AFF),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                LinearProgressIndicator(
                                  value: profileController.profileCompleteness,
                                  backgroundColor: const Color(0xFFE9ECEF),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                                  minHeight: 6.h,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  profileController.profileCompletenessMessage,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF6C757D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Get.offAllNamed(AppRoutes.start);
            } else if (index == 2) {
              Get.toNamed(AppRoutes.chat);
            }
          },
          showUnselectedLabels: true,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: const Color(0xFF9FA4B0),
          selectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'MBTI 테스트',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28),
              activeIcon: Icon(Icons.person, size: 28),
              label: '프로필',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz, size: 28),
              activeIcon: Icon(Icons.more_horiz, size: 28),
              label: '채팅',
            ),
          ],
        ),
      ),
    );
  }
}
