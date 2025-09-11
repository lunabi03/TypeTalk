import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File; // guarded with kIsWeb
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/controllers/profile_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthController authController;
  late final ProfileController profileController;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    // 이미 등록된 ProfileController가 있으면 재사용하여 인스턴스 중복을 방지
    profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    
    // 화면 초기화 시 MBTI 정보 강제 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    
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
                              child: Obx(() {
                                final mapUrl = authController.userProfile['profileImageUrl'] as String?;
                                final modelUrl = authController.userModel.value?.profileImageUrl;
                                final controllerUrl = profileController.profileImageUrl.value;
                                final imageUrl = (mapUrl?.isNotEmpty == true)
                                    ? mapUrl!
                                    : (modelUrl?.isNotEmpty == true)
                                        ? modelUrl!
                                        : (controllerUrl.isNotEmpty ? controllerUrl : '');

                                if (imageUrl.isEmpty) {
                                  return Image.asset(
                                    'assets/images/_icon_profile.png',
                                    width: 60.w,
                                    height: 60.w,
                                    fit: BoxFit.contain,
                                  );
                                }

                                final isNetworkLike = imageUrl.startsWith('http://') ||
                                    imageUrl.startsWith('https://') ||
                                    imageUrl.startsWith('blob:') ||
                                    imageUrl.startsWith('data:');

                                if (isNetworkLike || kIsWeb) {
                                  return Image.network(
                                    imageUrl,
                                    width: 60.w,
                                    height: 60.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) {
                                      return Image.asset(
                                        'assets/images/_icon_profile.png',
                                        width: 60.w,
                                        height: 60.w,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  );
                                }

                                try {
                                  return Image.file(
                                    File(imageUrl),
                                    width: 60.w,
                                    height: 60.w,
                                    fit: BoxFit.cover,
                                  );
                                } catch (_) {
                                  return Image.asset(
                                    'assets/images/_icon_profile.png',
                                    width: 60.w,
                                    height: 60.w,
                                    fit: BoxFit.contain,
                                  );
                                }
                              }),
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
                          SizedBox(height: 8.h),
                          
                          // Age and Gender Display
                          Obx(() {
                            final userModel = authController.userModel.value;
                            final map = authController.userProfile;
                            final controllerUser = profileController.currentUser.value;
                            // 나이/성별을 "가장 최근 저장(맵) → 모델 → 로컬" 순으로 폴백
                            final int? age = (map['age'] as int?) ?? userModel?.age ?? controllerUser?.age;
                            final String? gender = (map['gender'] as String?) ?? userModel?.gender ?? controllerUser?.gender;
                            
                            // 디버그 로그 추가
                            print('=== 프로필 화면 나이/성별 디버그 ===');
                            print('userModel: $userModel');
                            print('age: $age');
                            print('gender: $gender');
                            print('userModel?.age: ${userModel?.age}');
                            print('userModel?.gender: ${userModel?.gender}');
                            print('userModel?.toMap(): ${userModel?.toMap()}');
                            print('================================');
                            
                            // 나이와 성별을 각각 별도로 표시
                            List<Widget> infoWidgets = [];
                            
                            // 나이 표시 (null이 아니고 0보다 큰 경우)
                            if (age != null && age > 0) {
                              infoWidgets.add(
                                Text(
                                  '나이: ${age}세',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF6C757D),
                                    height: 1.3,
                                  ),
                                ),
                              );
                            }
                            
                            // 성별 표시 (null이 아니고 빈 문자열이 아닌 경우)
                            if (gender != null && gender.isNotEmpty) {
                              infoWidgets.add(
                                Text(
                                  '성별: $gender',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF6C757D),
                                    height: 1.3,
                                  ),
                                ),
                              );
                            }
                            
                            if (infoWidgets.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: infoWidgets,
                              );
                            }
                            
                            return const SizedBox.shrink();
                          }),
                          SizedBox(height: 8.h),
                          
                          // Bio (소개글)
                          Obx(() {
                            final bio = authController.userProfile['bio'] as String?;
                            final userModelBio = authController.userModel.value?.bio;
                            
                            // 디버그 정보 출력
                            print('=== Bio 디버그 정보 ===');
                            print('userProfile bio: $bio');
                            print('userModel bio: $userModelBio');
                            print('userProfile 전체: ${authController.userProfile}');
                            print('=======================');
                            
                            // bio 정보를 여러 소스에서 확인
                            final effectiveBio = bio ?? userModelBio;
                            
                            if (effectiveBio != null && effectiveBio.isNotEmpty) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                child: Text(
                                  effectiveBio,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF424242),
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          SizedBox(height: 4.h),
                          
                          // Join Date
                          Obx(() {
                            final createdAt = authController.userProfile['createdAt'];
                            String joinDate = '로딩 중...';
                            
                            // 디버그 정보 출력
                            print('프로필 화면 createdAt: $createdAt (타입: ${createdAt?.runtimeType})');
                            
                            if (createdAt != null) {
                              try {
                                DateTime date;
                                if (createdAt is DateTime) {
                                  date = createdAt;
                                } else if (createdAt is String) {
                                  date = DateTime.parse(createdAt);
                                } else {
                                  // Firestore Timestamp인 경우
                                  date = (createdAt as dynamic).toDate();
                                }
                                joinDate = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                                print('변환된 날짜: $joinDate');
                              } catch (e) {
                                print('날짜 변환 오류: $e');
                                joinDate = '날짜 오류';
                              }
                            } else {
                              joinDate = '정보 없음';
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
                    Obx(() {
                      // MBTI 정보를 여러 소스에서 확인
                      final userMBTI = authController.currentUserMBTI;
                      final userProfileMBTI = authController.userProfile['mbti'];
                      final userModelMBTI = authController.userModel.value?.mbtiType;
                      
                      // 가장 신뢰할 수 있는 MBTI 정보 선택
                      final effectiveMBTI = userMBTI ?? userProfileMBTI ?? userModelMBTI;
                      
                      final bannerText = _getMBTIBannerText(effectiveMBTI);
                      final bannerColor = _getMBTIBannerColor(effectiveMBTI);
                      
                      // MBTI 정보 디버그 로그 추가
                      print('=== ProfileScreen MBTI 디버그 ===');
                      print('userMBTI: $userMBTI');
                      print('userProfileMBTI: $userProfileMBTI');
                      print('userModelMBTI: $userModelMBTI');
                      print('effectiveMBTI: $effectiveMBTI');
                      print('bannerText: $bannerText');
                      print('userProfile 전체: ${authController.userProfile}');
                      print('===============================');
                      
                      return Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: 100.h,
                          maxHeight: 120.h,
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: bannerColor,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: bannerColor[0].withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                          child: Row(
                            children: [
                              // MBTI 아이콘
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  _getMBTIIcon(effectiveMBTI),
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              // MBTI 텍스트
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      bannerText['title'] ?? 'MBTI 결과',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      bannerText['subtitle'] ?? '당신의 성격 유형을 확인해보세요',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    SizedBox(height: 16.h),
                    
                    // Profile Statistics Cards
                    Obx(() {
                      final stats = profileController.profileStats;
                      final mbtiTestCount = authController.userProfile['mbtiTestCount'] ?? 0;
                      
                      // MBTI 정보를 여러 소스에서 확인
                      final userMBTI = authController.currentUserMBTI;
                      final userProfileMBTI = authController.userProfile['mbti'];
                      final userModelMBTI = authController.userModel.value?.mbtiType;
                      
                      // 가장 신뢰할 수 있는 MBTI 정보 선택
                      final effectiveMBTI = userMBTI ?? userProfileMBTI ?? userModelMBTI;
                      
                      return Column(
                        children: [
                          // MBTI Test Completion Card
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: 80.h,
                              maxHeight: 100.h,
                            ),
                            padding: EdgeInsets.all(16.w),
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'MBTI 테스트 완료',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        '현재 유형: ${effectiveMBTI ?? "미완료"}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: effectiveMBTI != null ? const Color(0xFF007AFF) : const Color(0xFF6C757D),
                                          fontWeight: effectiveMBTI != null ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  '${mbtiTestCount}회',
                                  style: TextStyle(
                                    fontSize: 14.sp,
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
                            constraints: BoxConstraints(
                              minHeight: 100.h,
                              maxHeight: 120.h,
                            ),
                            padding: EdgeInsets.all(16.w),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '프로필 완성도',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${(profileController.profileCompleteness * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF007AFF),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                LinearProgressIndicator(
                                  value: profileController.profileCompleteness,
                                  backgroundColor: const Color(0xFFE9ECEF),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                                  minHeight: 5.h,
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  profileController.profileCompletenessMessage,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF6C757D),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 6.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showCompletenessGuide,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: Size(0, 0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF007AFF)),
                                        SizedBox(width: 6.w),
                                        const Text(
                                          '어떻게 채워지나요?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF007AFF),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
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
        height: 80,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Get.toNamed(AppRoutes.start);
            } else if (index == 2) {
              Get.toNamed(AppRoutes.chat);
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
              icon: Icon(Icons.chat_bubble_outline, size: 28),
              activeIcon: Icon(Icons.chat_bubble, size: 28),
              label: '채팅',
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getMBTIBannerText(String? userMBTI) {
    if (userMBTI == null || userMBTI.isEmpty) {
      return {'title': 'MBTI 테스트 완료하기', 'subtitle': '당신의 성격 유형을 알아보세요'};
    }

    switch (userMBTI) {
      case 'ENFP':
        return {'title': 'ENFP - 재기발랄한 모험가', 'subtitle': '당신은 창의적이고 열정적인 영혼의 여행자입니다'};
      case 'ENFJ':
        return {'title': 'ENFJ - 따뜻한 리더', 'subtitle': '당신은 사람들을 이끄는 카리스마 넘치는 지도자입니다'};
      case 'ENTP':
        return {'title': 'ENTP - 혁신적인 사상가', 'subtitle': '당신은 창의적이고 논리적인 문제 해결사입니다'};
      case 'ENTJ':
        return {'title': 'ENTJ - 전략적인 지도자', 'subtitle': '당신은 목표 지향적이고 효율적인 조직가입니다'};
      case 'ESFP':
        return {'title': 'ESFP - 자유로운 영혼', 'subtitle': '당신은 삶을 즐기고 사람들과 어울리는 사교적인 사람입니다'};
      case 'ESFJ':
        return {'title': 'ESFJ - 배려하는 조력자', 'subtitle': '당신은 다른 사람을 돕고 조화를 추구하는 따뜻한 사람입니다'};
      case 'ESTP':
        return {'title': 'ESTP - 실용적인 모험가', 'subtitle': '당신은 현실적이고 적응력이 뛰어난 행동가입니다'};
      case 'ESTJ':
        return {'title': 'ESTJ - 체계적인 관리자', 'subtitle': '당신은 질서와 규칙을 중시하는 신뢰할 수 있는 사람입니다'};
      case 'INFP':
        return {'title': 'INFP - 이상주의적 꿈꾸는자', 'subtitle': '당신은 창의적이고 공감능력이 뛰어난 예술가입니다'};
      case 'INFJ':
        return {'title': 'INFJ - 통찰력 있는 조언자', 'subtitle': '당신은 깊은 통찰력으로 사람들을 돕는 지혜로운 사람입니다'};
      case 'INTP':
        return {'title': 'INTP - 논리적인 사상가', 'subtitle': '당신은 복잡한 문제를 해결하는 창의적인 분석가입니다'};
      case 'INTJ':
        return {'title': 'INTJ - 전략적인 설계자', 'subtitle': '당신은 장기적 비전을 가진 혁신적인 전략가입니다'};
      case 'ISFP':
        return {'title': 'ISFP - 예술적인 모험가', 'subtitle': '당신은 아름다움을 추구하는 자유로운 영혼입니다'};
      case 'ISFJ':
        return {'title': 'ISFJ - 헌신적인 보호자', 'subtitle': '당신은 다른 사람을 돌보고 보호하는 따뜻한 수호자입니다'};
      case 'ISTP':
        return {'title': 'ISTP - 실용적인 기술자', 'subtitle': '당신은 문제를 해결하는 실용적인 기술자입니다'};
      case 'ISTJ':
        return {'title': 'ISTJ - 신뢰할 수 있는 실무자', 'subtitle': '당신은 책임감 있고 체계적인 실무자입니다'};
      default:
        return {'title': 'MBTI 결과', 'subtitle': '당신의 성격 유형을 확인해보세요'};
    }
  }

  List<Color> _getMBTIBannerColor(String? userMBTI) {
    if (userMBTI == null || userMBTI.isEmpty) {
      return [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)];
    }

    switch (userMBTI) {
      case 'ENFP':
        return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)]; // 빨강-노랑
      case 'ENFJ':
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)]; // 청록
      case 'ENTP':
        return [const Color(0xFF45B7D1), const Color(0xFF96CEB4)]; // 파랑-초록
      case 'ENTJ':
        return [const Color(0xFFDDA0DD), const Color(0xFF98D8C8)]; // 보라-청록
      case 'ESFP':
        return [const Color(0xFFFF8C42), const Color(0xFFFFB6C1)]; // 주황-분홍
      case 'ESFJ':
        return [const Color(0xFF20B2AA), const Color(0xFF87CEEB)]; // 바다색-하늘색
      case 'ESTP':
        return [const Color(0xFF32CD32), const Color(0xFF90EE90)]; // 초록
      case 'ESTJ':
        return [const Color(0xFF4682B4), const Color(0xFF87CEEB)]; // 강철색-하늘색
      case 'INFP':
        return [const Color(0xFF9370DB), const Color(0xFFDDA0DD)]; // 보라
      case 'INFJ':
        return [const Color(0xFF2E8B57), const Color(0xFF98FB98)]; // 바다색-연한초록
      case 'INTP':
        return [const Color(0xFF4169E1), const Color(0xFF87CEEB)]; // 로얄블루-하늘색
      case 'INTJ':
        return [const Color(0xFF191970), const Color(0xFF483D8B)]; // 미드나이트블루-다크슬레이트
      case 'ISFP':
        return [const Color(0xFFFF69B4), const Color(0xFFFFB6C1)]; // 핫핑크-연한분홍
      case 'ISFJ':
        return [const Color(0xFFDEB887), const Color(0xFFF5DEB3)]; // 버번우드-밀색
      case 'ISTP':
        return [const Color(0xFF708090), const Color(0xFFC0C0C0)]; // 슬레이트그레이-실버
      case 'ISTJ':
        return [const Color(0xFF556B2F), const Color(0xFF8FBC8F)]; // 다크올리브그린-다크시그린
      default:
        return [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)]; // 기본 보라 그라데이션
    }
  }

  IconData _getMBTIIcon(String? userMBTI) {
    if (userMBTI == null || userMBTI.isEmpty) {
      return Icons.psychology_outlined;
    }

    switch (userMBTI) {
      case 'ENFP':
        return Icons.auto_awesome; // 창의적이고 영감을 주는
      case 'ENFJ':
        return Icons.leaderboard; // 리더십
      case 'ENTP':
        return Icons.lightbulb_outline; // 혁신적 (아이디어)
      case 'ENTJ':
        return Icons.trending_up; // 전략적 (성장/전략)
      case 'ESFP':
        return Icons.celebration; // 축하/즐거움
      case 'ESFJ':
        return Icons.favorite; // 사랑/배려
      case 'ESTP':
        return Icons.sports_esports; // 모험/액션
      case 'ESTJ':
        return Icons.rule; // 규칙/질서
      case 'INFP':
        return Icons.brush; // 예술적
      case 'INFJ':
        return Icons.insights; // 통찰력
      case 'INTP':
        return Icons.science; // 과학적 사고
      case 'INTJ':
        return Icons.architecture; // 설계/계획
      case 'ISFP':
        return Icons.palette; // 예술적
      case 'ISFJ':
        return Icons.shield; // 보호/수호
      case 'ISTP':
        return Icons.build; // 기술/건축
      case 'ISTJ':
        return Icons.work; // 실무/업무
      default:
        return Icons.psychology_outlined;
    }
  }

  // 프로필 완성도 가이드 바텀시트 표시
  void _showCompletenessGuide() {
    // 한글 설명: 각 항목이 몇 %를 차지하는지 안내하는 시트
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 16.h,
            bottom: 16.h + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF007AFF)),
                  SizedBox(width: 8.w),
                  Text(
                    '프로필 완성도 계산 기준',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildGuideItem('이름', 20, completed: (profileController.currentUser.value?.name.isNotEmpty ?? false)),
              _buildGuideItem('이메일', 20, completed: (profileController.currentUser.value?.email.isNotEmpty ?? false)),
              _buildGuideItem('소개(한 줄 소개)', 10, completed: (profileController.currentUser.value?.bio?.isNotEmpty ?? false)),
              _buildGuideItem('프로필 이미지', 20, completed: (profileController.currentUser.value?.profileImageUrl?.isNotEmpty ?? false)),
              _buildGuideItem('MBTI 설정', 30, completed: (profileController.currentUser.value?.mbtiType?.isNotEmpty ?? false)),
              SizedBox(height: 12.h),
              Text(
                '팁: 프로필 이미지를 추가하고 MBTI를 설정하면 빠르게 50%를 채울 수 있어요.',
                style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6C757D)),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  // 가이드 항목 위젯 (항목명, 가중치, 완료 여부)
  Widget _buildGuideItem(String label, int weight, {required bool completed}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? const Color(0xFF28A745) : const Color(0xFFADB5BD),
            size: 18,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '+${weight}%',
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6C757D)),
          ),
        ],
      ),
    );
  }
}
