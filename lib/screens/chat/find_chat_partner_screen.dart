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
        {'name': '열정맨', 'description': '새로운 경험을 사랑하는 모험가', 'friendCount': 127, 'chatCount': 45},
        {'name': '창의킹', 'description': '아이디어가 넘치는 발명가', 'friendCount': 89, 'chatCount': 32},
        {'name': '에너지봄', 'description': '활력이 넘치는 소통왕', 'friendCount': 156, 'chatCount': 67},
      ],
      'INTJ': [
        {'name': '전략가', 'description': '체계적으로 계획하는 리더', 'friendCount': 78, 'chatCount': 23},
        {'name': '분석왕', 'description': '논리적 사고의 전문가', 'friendCount': 92, 'chatCount': 34},
        {'name': '미래설계사', 'description': '장기적 비전을 가진 설계자', 'friendCount': 65, 'chatCount': 19},
      ],
      'ISFP': [
        {'name': '예술가', 'description': '감성적인 창작자', 'friendCount': 103, 'chatCount': 28},
        {'name': '자유혼', 'description': '개성 넘치는 독립가', 'friendCount': 87, 'chatCount': 31},
        {'name': '감성킹', 'description': '따뜻한 마음의 소유자', 'friendCount': 134, 'chatCount': 42},
      ],
      'ENTP': [
        {'name': '혁신가', 'description': '새로운 아이디어의 창조자', 'friendCount': 145, 'chatCount': 58},
        {'name': '토론왕', 'description': '논리적 토론을 즐기는 사상가', 'friendCount': 98, 'chatCount': 37},
        {'name': '변화추구자', 'description': '끊임없는 변화를 추구하는 혁신가', 'friendCount': 112, 'chatCount': 44},
      ],
      'INFJ': [
        {'name': '통찰자', 'description': '깊은 통찰력을 가진 조언자', 'friendCount': 76, 'chatCount': 25},
        {'name': '공감왕', 'description': '타인의 마음을 이해하는 공감자', 'friendCount': 89, 'chatCount': 33},
        {'name': '비전가', 'description': '미래를 내다보는 비전가', 'friendCount': 67, 'chatCount': 21},
      ],
      'ESTJ': [
        {'name': '관리자', 'description': '체계적인 조직 관리자', 'friendCount': 123, 'chatCount': 41},
        {'name': '책임왕', 'description': '책임감 넘치는 리더', 'friendCount': 98, 'chatCount': 35},
        {'name': '실행가', 'description': '효율적인 실행 전문가', 'friendCount': 87, 'chatCount': 29},
      ],
      'INFP': [
        {'name': '이상주의자', 'description': '순수한 마음의 이상주의자', 'friendCount': 95, 'chatCount': 26},
        {'name': '감성예술가', 'description': '깊은 감성을 가진 예술가', 'friendCount': 78, 'chatCount': 22},
        {'name': '평화주의자', 'description': '조화를 추구하는 평화주의자', 'friendCount': 112, 'chatCount': 38},
      ],
      'ISTP': [
        {'name': '장인', 'description': '손재주가 뛰어난 장인', 'friendCount': 84, 'chatCount': 27},
        {'name': '실용가', 'description': '실용적인 해결사', 'friendCount': 76, 'chatCount': 24},
        {'name': '모험가', 'description': '도전을 즐기는 모험가', 'friendCount': 92, 'chatCount': 31},
      ],
    };
    
    final profiles = userProfiles[selectedMBTI] ?? [
      {'name': '친구1', 'description': '친근한 사용자', 'friendCount': 50, 'chatCount': 15},
      {'name': '친구2', 'description': '활발한 사용자', 'friendCount': 60, 'chatCount': 20},
      {'name': '친구3', 'description': '따뜻한 사용자', 'friendCount': 45, 'chatCount': 18},
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
      'ENFP': '열정적이고 창의적인',
      'INTJ': '전략적이고 분석적인',
      'ISFP': '예술적이고 감성적인',
      'ENTP': '혁신적이고 도전적인',
      'INFJ': '통찰력 있고 공감적인',
      'ESTJ': '체계적이고 책임감 있는',
      'INFP': '이상주의적이고 창의적인',
      'ISTP': '실용적이고 적응력 있는',
    };
    return descriptions[mbti] ?? '친근하고 도움이 되는';
  }

  /// 사용자별 개별 설명 반환
  String _getUserDescription(String userName) {
    final userDescriptions = {
      '열정맨': '새로운 경험을 사랑하는 모험가',
      '창의킹': '아이디어가 넘치는 발명가',
      '에너지봄': '활력이 넘치는 소통왕',
      '전략가': '체계적으로 계획하는 리더',
      '분석왕': '논리적 사고의 전문가',
      '미래설계사': '장기적 비전을 가진 설계자',
      '예술가': '감성적인 창작자',
      '자유혼': '개성 넘치는 독립가',
      '감성킹': '따뜻한 마음의 소유자',
      '혁신가': '새로운 아이디어의 창조자',
      '토론왕': '논리적 토론을 즐기는 사상가',
      '변화추구자': '끊임없는 변화를 추구하는 혁신가',
      '통찰자': '깊은 통찰력을 가진 조언자',
      '공감왕': '타인의 마음을 이해하는 공감자',
      '비전가': '미래를 내다보는 비전가',
      '관리자': '체계적인 조직 관리자',
      '책임왕': '책임감 넘치는 리더',
      '실행가': '효율적인 실행 전문가',
      '이상주의자': '순수한 마음의 이상주의자',
      '감성예술가': '깊은 감성을 가진 예술가',
      '평화주의자': '조화를 추구하는 평화주의자',
      '장인': '손재주가 뛰어난 장인',
      '실용가': '실용적인 해결사',
      '모험가': '도전을 즐기는 모험가',
    };
    return userDescriptions[userName] ?? '친근하고 도움이 되는';
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
      child: Row(
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
          SizedBox(width: 20.w),
          // 사용자 정보
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
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        user.mbtiType!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: _getMBTIColor(user.mbtiType),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _getUserDescription(user.name),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16.sp,
                      color: Colors.red[400],
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '궁합 점수: $compatibilityScore%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '친구 ${user.stats.friendCount}명 • 채팅 ${user.stats.chatCount}개',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 채팅 시작 버튼 (AI 어시스턴트로 이동)
          ElevatedButton(
            onPressed: () {
              // 채팅 요청 발송 안내 스낵바
              Get.snackbar(
                '알림',
                '채팅 요청을 보냈습니다!',
                backgroundColor: const Color(0xFF9C27B0).withOpacity(0.1),
                colorText: const Color(0xFF9C27B0),
              );
              _openInlineAIChat(user.mbtiType ?? 'ENFP');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text(
              '채팅',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
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
