import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/models/user_model.dart';

import 'package:typetalk/controllers/chat_controller.dart';
import 'package:typetalk/services/gemini_service.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/screens/chat/_inline_ai_chat.dart';
import 'package:typetalk/routes/app_routes.dart';

/// 대화 상대 찾기 화면
class FindChatPartnerScreen extends StatelessWidget {
  const FindChatPartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'MBTI 궁합 기반 대화 상대 찾기',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // TODO: 전체 검색 기능 구현
            },
          ),
        ],
      ),
      body: _buildMBTICompatibilityTab(),
    );
  }

  



  /// MBTI 궁합 기반 추천 탭
  Widget _buildMBTICompatibilityTab() {
    final selectedMBTI = 'ENFP'.obs; // 기본값
    final searchQuery = ''.obs;
    final geminiService = Get.put(GeminiService());
    final authController = Get.find<AuthController>();
    
    return Column(
      children: [
        // 상단 고정 영역
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              // MBTI 궁합 추천 헤더
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: const Color(0xFF9C27B0),
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MBTI 궁합 기반 추천',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9C27B0),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '성격 유형 궁합이 좋은 사용자를 추천합니다',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF9C27B0).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // MBTI 선택
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '찾고 싶은 MBTI 유형:',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      height: 72.h,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildMBTISelectionChip('ENFP', '열정적인', selectedMBTI),
                          _buildMBTISelectionChip('INTJ', '전략적인', selectedMBTI),
                          _buildMBTISelectionChip('ISFP', '예술적인', selectedMBTI),
                          _buildMBTISelectionChip('ENTP', '혁신적인', selectedMBTI),
                          _buildMBTISelectionChip('INFJ', '통찰력 있는', selectedMBTI),
                          _buildMBTISelectionChip('ESTJ', '체계적인', selectedMBTI),
                          _buildMBTISelectionChip('INFP', '이상주의적인', selectedMBTI),
                          _buildMBTISelectionChip('ISTP', '실용적인', selectedMBTI),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // 검색 바
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '이름, 관심사로 검색',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: Icon(Icons.filter_list, color: Colors.grey[600]),
                  ),
                  onChanged: (value) {
                    searchQuery.value = value;
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
        // 사용자 목록 영역 (Expanded로 남은 공간 차지)
        Expanded(
          child: Obx(() {
            final mbtiUsers = _generateMBTIUsers(selectedMBTI.value);
            
            if (mbtiUsers.isEmpty) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_alt_outlined,
                      size: 56.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '${selectedMBTI.value} 사용자가 없습니다',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '다른 MBTI 유형을 선택해보세요',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: mbtiUsers.length,
              itemBuilder: (context, index) {
                final user = mbtiUsers[index];
                return _buildMBTICompatibilityUserListItem(
                  user,
                  Get.find<ChatController>(),
                  selectedMBTI.value,
                  _getUserDescription(user.name),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  /// MBTI 기반 사용자 목록 생성
  List<UserModel> _generateMBTIUsers(String selectedMBTI) {
    // MBTI별 다양한 닉네임과 프로필 데이터
    final userProfiles = {
      'ENFP': [
        {'name': '민서_98', 'description': '새로운 경험을 사랑하는 모험가', 'bio': 'ㅎㅇ', 'friendCount': 127, 'chatCount': 45},
        {'name': '준호93', 'description': '아이디어가 넘치는 발명가', 'bio': '', 'friendCount': 89, 'chatCount': 32},
        {'name': '다연이에요', 'description': '활력이 넘치는 소통왕', 'bio': '반가워요~', 'friendCount': 156, 'chatCount': 67},
      ],
      'INTJ': [
        {'name': '진우_k', 'description': '체계적으로 계획하는 리더', 'bio': '안녕하세요', 'friendCount': 78, 'chatCount': 23},
        {'name': 'yuna.j', 'description': '논리적 사고의 전문가', 'bio': '', 'friendCount': 92, 'chatCount': 34},
        {'name': 'warmguy', 'description': '장기적 비전을 가진 설계자', 'bio': '하이', 'friendCount': 65, 'chatCount': 19},
      ],
      'ISFP': [
        {'name': '하늘조각', 'description': '감성적인 창작자', 'bio': '안녕', 'friendCount': 103, 'chatCount': 28},
        {'name': '민혁__', 'description': '개성 넘치는 독립가', 'bio': '', 'friendCount': 87, 'chatCount': 31},
        {'name': '소소한행복', 'description': '따뜻한 마음의 소유자', 'bio': '반갑습니다', 'friendCount': 134, 'chatCount': 42},
      ],
      'ENTP': [
        {'name': 'coffee_addict', 'description': '새로운 아이디어의 창조자', 'bio': '헬로', 'friendCount': 145, 'chatCount': 58},
        {'name': 'jay.p', 'description': '논리적 토론을 즐기는 사상가', 'bio': '', 'friendCount': 98, 'chatCount': 37},
        {'name': '도시산책러', 'description': '끊임없는 변화를 추구하는 혁신가', 'bio': '안녕하세요', 'friendCount': 112, 'chatCount': 44},
      ],
      'INFJ': [
        {'name': '바람결', 'description': '깊은 통찰력을 가진 조언자', 'bio': '반가워요', 'friendCount': 76, 'chatCount': 25},
        {'name': '여름밤', 'description': '타인의 마음을 이해하는 공감자', 'bio': '', 'friendCount': 89, 'chatCount': 33},
        {'name': 'moody_day', 'description': '미래를 내다보는 비전가', 'bio': 'ㅎㅇ', 'friendCount': 67, 'chatCount': 21},
      ],
      'ESTJ': [
        {'name': 'hello.sun', 'description': '체계적인 조직 관리자', 'bio': '안녕하세요', 'friendCount': 123, 'chatCount': 41},
        {'name': 'filmlover', 'description': '책임감 넘치는 리더', 'bio': '', 'friendCount': 98, 'chatCount': 35},
        {'name': '새벽감성', 'description': '효율적인 실행 전문가', 'bio': '하이요', 'friendCount': 87, 'chatCount': 29},
      ],
      'INFP': [
        {'name': 'mellow_', 'description': '순수한 마음의 이상주의자', 'bio': '안녕', 'friendCount': 95, 'chatCount': 26},
        {'name': '하루커피☕', 'description': '깊은 감성을 가진 예술가', 'bio': '', 'friendCount': 78, 'chatCount': 22},
        {'name': 'luna_', 'description': '조화를 추구하는 평화주의자', 'bio': '반갑습니다', 'friendCount': 112, 'chatCount': 38},
      ],
      'ISTP': [
        {'name': 'moody_day', 'description': '손재주가 뛰어난 장인', 'bio': '헬로우', 'friendCount': 84, 'chatCount': 27},
        {'name': 'filmlover', 'description': '실용적인 해결사', 'bio': '', 'friendCount': 76, 'chatCount': 24},
        {'name': '새벽감성', 'description': '도전을 즐기는 모험가', 'bio': '안녕하세요', 'friendCount': 92, 'chatCount': 31},
      ],
    };
    
    final profiles = userProfiles[selectedMBTI] ?? [
      {'name': '바람결', 'description': '친근한 사용자', 'bio': '하이', 'friendCount': 50, 'chatCount': 15},
      {'name': '여름밤', 'description': '활발한 사용자', 'bio': '', 'friendCount': 60, 'chatCount': 20},
      {'name': 'moody_day', 'description': '따뜻한 사용자', 'bio': '헬로우', 'friendCount': 45, 'chatCount': 18},
    ];
    
    final users = <UserModel>[];
    
    for (int i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      final user = UserModel(
        uid: 'mbti-$selectedMBTI-$i',
        email: '${profile['name']}@example.com',
        name: profile['name'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mbtiType: selectedMBTI,
        profileImageUrl: null,
        bio: profile['bio'] as String?,
        stats: UserStats(
          friendCount: profile['friendCount'] as int,
          chatCount: profile['chatCount'] as int,
          lastLoginAt: DateTime.now(),
        ),
      );
      users.add(user);
    }
    
    return users;
  }

  /// MBTI 설명 반환
  String _getMBTIDescription(String mbti) {
    final descriptions = {
      'ENFP': '재기발랄한 모험가',
      'ENFJ': '정의로운 사회운동가',
      'ENTP': '뜨거운 논쟁을 즐기는 변론가',
      'ENTJ': '대담한 통솔자',
      'ESFP': '자유로운 영혼의 연예인',
      'ESFJ': '사교적인 외교관',
      'ESTP': '모험을 즐기는 사업가',
      'ESTJ': '엄격한 관리자',
      'INFP': '열정적인 중재자',
      'INFJ': '선의의 옹호자',
      'INTP': '논리적인 사색가',
      'INTJ': '용의주도한 전략가',
      'ISFP': '호기심 많은 예술가',
      'ISFJ': '용감한 수호자',
      'ISTP': '만능 재주꾼',
      'ISTJ': '실용주의자',
    };
    return descriptions[mbti] ?? '성격 유형';
  }

  /// 사용자별 개별 설명 반환
  String _getUserDescription(String userName) {
    final userDescriptions = {
      '민서_98': '새로운 경험을 사랑하는 모험가',
      '준호93': '아이디어가 넘치는 발명가',
      '다연이에요': '활력이 넘치는 소통왕',
      '진우_k': '체계적으로 계획하는 리더',
      'yuna.j': '논리적 사고의 전문가',
      'warmguy': '장기적 비전을 가진 설계자',
      '하늘조각': '감성적인 창작자',
      '민혁__': '개성 넘치는 독립가',
      '소소한행복': '따뜻한 마음의 소유자',
      'coffee_addict': '새로운 아이디어의 창조자',
      'jay.p': '논리적 토론을 즐기는 사상가',
      '도시산책러': '끊임없는 변화를 추구하는 혁신가',
      '바람결': '깊은 통찰력을 가진 조언자',
      '여름밤': '타인의 마음을 이해하는 공감자',
      'moody_day': '미래를 내다보는 비전가',
      'hello.sun': '체계적인 조직 관리자',
      'filmlover': '책임감 넘치는 리더',
      '새벽감성': '효율적인 실행 전문가',
      'mellow_': '순수한 마음의 이상주의자',
      '하루커피☕': '깊은 감성을 가진 예술가',
      'luna_': '조화를 추구하는 평화주의자',
    };
    return userDescriptions[userName] ?? '친근하고 도움이 되는';
  }



  /// 사용자 프로필 모달 표시
  void _showUserProfileModal(UserModel user) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
            maxWidth: 400.w,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '프로필',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              // 프로필 내용
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // 프로필 카드
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Column(
                          children: [
                            // 프로필 아이콘
                            Container(
                              width: 100.w,
                              height: 100.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18.r),
                                child: user.profileImageUrl != null
                                    ? Image.network(
                                        user.profileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildDefaultAvatar(user);
                                        },
                                      )
                                    : _buildDefaultAvatar(user),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            
                            // 사용자 이름
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8.h),
                            
                            // 소개글 (있는 경우)
                            if (user.bio != null && user.bio!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                child: Text(
                                  user.bio!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF424242),
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            SizedBox(height: 8.h),
                            
                            // 가입일
                            Text(
                              '가입일: ${_formatDate(user.createdAt)}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: const Color(0xFF6C757D),
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // MBTI 정보 배너
                      Container(
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
                            colors: _getMBTIBannerColor(user.mbtiType),
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: _getMBTIBannerColor(user.mbtiType)[0].withOpacity(0.3),
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
                                  _getMBTIIcon(user.mbtiType),
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
                                      _getMBTIBannerText(user.mbtiType)['title'] ?? 'MBTI 결과',
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
                                      _getMBTIBannerText(user.mbtiType)['subtitle'] ?? '당신의 성격 유형을 확인해보세요',
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
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // 채팅 시작 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back(); // 모달 닫기
                            // AI 채팅방으로 전체 화면 이동
                            _openFullScreenAIChat(user.mbtiType ?? 'ENFP', user.name);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                '채팅 신청 보내기',
                                style: TextStyle(
                                  fontSize: 16.sp,
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
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// 기본 아바타 위젯
  Widget _buildDefaultAvatar(UserModel user) {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: Text(
          user.name.characters.first,
          style: TextStyle(
            color: _getMBTIColor(user.mbtiType),
            fontWeight: FontWeight.bold,
            fontSize: 36.sp,
          ),
        ),
      ),
    );
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// MBTI 배너 텍스트 반환
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

  /// MBTI 배너 색상 반환
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

  /// MBTI 아이콘 반환
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



  /// 전체 화면 AI 채팅 열기
  void _openFullScreenAIChat(String mbti, String userName) {
    final geminiService = Get.find<GeminiService>();
    final auth = Get.find<AuthController>();
    final personaName = userName; // 실제 사용자 이름 사용

    Get.to(
      Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF1A1A1A),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 프로필 아바타
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: _getMBTIColor(mbti),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  personaName.characters.first,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // 이름과 MBTI 정보
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    personaName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'MBTI: $mbti',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _getMBTIColor(mbti).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _getMBTIDescription(mbti),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: _getMBTIColor(mbti),
                ),
              ),
            ),
          ],
        ),
        body: InlineAIChat(
          personaName: personaName,
          personaMBTI: mbti,
          geminiService: geminiService,
          userMBTI: auth.userModel.value?.mbtiType ?? 'UNKNOWN',
        ),
      ),
    );
  }

  /// 하단 시트로 인라인 AI 채팅 열기
  void _openInlineAIChat(String mbti) {
    final geminiService = Get.find<GeminiService>();
    final auth = Get.find<AuthController>();
    final personaName = '$mbti 친구';

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: SafeArea(
          top: false,
          child: InlineAIChat(
            personaName: personaName,
            personaMBTI: mbti,
            geminiService: geminiService,
            userMBTI: auth.userModel.value?.mbtiType ?? 'UNKNOWN',
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// MBTI 선택 칩 위젯
  Widget _buildMBTISelectionChip(String mbti, String description, RxString selectedMBTI) {
    final isSelected = selectedMBTI.value == mbti;
    
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: () => selectedMBTI.value = mbti,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF9C27B0) 
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF9C27B0) 
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mbti,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// MBTI 궁합 기반 사용자 목록 항목 위젯
  Widget _buildMBTICompatibilityUserListItem(
    UserModel user,
    ChatController controller,
    String selectedMBTI,
    String mbtiDescription,
  ) {
    // MBTI 궁합 점수 계산 (간단한 예시)
    final compatibilityScore = _calculateMBTICompatibility(selectedMBTI, user.mbtiType ?? '');
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단: 프로필 이미지, 이름, MBTI
          Row(
            children: [
              // 프로필 이미지 또는 아바타
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Center(
                  child: user.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: Image.network(
                            user.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                user.name.characters.first,
                                style: TextStyle(
                                  color: _getMBTIColor(user.mbtiType),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24.sp,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          user.name.characters.first,
                          style: TextStyle(
                            color: _getMBTIColor(user.mbtiType),
                            fontWeight: FontWeight.bold,
                            fontSize: 24.sp,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16.w),
              // 사용자 이름과 MBTI
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            user.mbtiType!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: _getMBTIColor(user.mbtiType),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getUserDescription(user.name),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 하단: 궁합 점수, 통계, 버튼
          Row(
            children: [
              // 궁합 점수
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 14.sp,
                    color: Colors.red[400],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '궁합 $compatibilityScore%',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.red[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),
              // 빈 공간 (통계 정보 제거)
              Expanded(
                child: SizedBox.shrink(),
              ),
              // 대화 시작 버튼
              ElevatedButton(
                onPressed: () async {
                  // 일반 사용자와의 대화 시작
                  final chatController = Get.find<ChatController>();
                  await chatController.startUserChat(
                    user.name,
                    user.mbtiType ?? 'UNKNOWN',
                    user.bio,
                  );
                  
                  // 대화 시작 후 채팅 화면으로 이동
                  Get.toNamed(AppRoutes.chat);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                  minimumSize: Size(0, 32.h),
                ),
                child: Text(
                  '대화 시작',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// MBTI 궁합 점수 계산 (간단한 예시)
  int _calculateMBTICompatibility(String selectedMBTI, String userMBTI) {
    if (selectedMBTI.isEmpty || userMBTI.isEmpty) return 0;
    
    // 간단한 궁합 점수 계산 (실제로는 더 복잡한 알고리즘 사용)
    if (selectedMBTI == userMBTI) return 95; // 같은 MBTI
    
    // 보완적인 궁합 (예시)
    final complementaryPairs = {
      'ENFP': ['INTJ', 'ISTJ'],
      'INTJ': ['ENFP', 'ESFP'],
      'ISFP': ['ENTJ', 'ESTJ'],
      'ENTP': ['ISFJ', 'INFJ'],
      'INFJ': ['ENTP', 'ESTP'],
    };
    
    if (complementaryPairs[selectedMBTI]?.contains(userMBTI) == true) {
      return 88;
    }
    
    // 기본 점수 (50-85 사이)
    return 50 + (userMBTI.hashCode % 36);
  }

  /// MBTI 유형별 색상 반환
  Color _getMBTIColor(String? mbtiType) {
    if (mbtiType == null) return Colors.grey;
    
    final mbtiColors = {
      'ENFP': const Color(0xFFFF6B6B), // 빨간색 계열
      'INTJ': const Color(0xFF4ECDC4), // 청록색 계열
      'ISFP': const Color(0xFF45B7D1), // 파란색 계열
      'ENTP': const Color(0xFF96CEB4), // 초록색 계열
      'INFJ': const Color(0xFFFECA57), // 노란색 계열
      'ESTJ': const Color(0xFFDDA0DD), // 보라색 계열
      'INFP': const Color(0xFFFFB6C1), // 분홍색 계열
      'ISTP': const Color(0xFFDEB887), // 갈색 계열
    };
    
    return mbtiColors[mbtiType] ?? Colors.grey;
  }


}
