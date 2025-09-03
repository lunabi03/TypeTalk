import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/core/theme/app_colors.dart';

/// 다른 사용자의 프로필 화면
class OtherUserProfileScreen extends StatelessWidget {
  final UserModel user;
  
  const OtherUserProfileScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Light blue background
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
        title: Text(
          '프로필',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // 채팅 시작 기능
              Get.snackbar(
                '알림',
                '${user.name}님과 채팅을 시작합니다!',
                backgroundColor: const Color(0xFF9C27B0).withOpacity(0.1),
                colorText: const Color(0xFF9C27B0),
              );
              Get.back();
            },
            icon: const Icon(
              Icons.chat,
              color: Color(0xFF9C27B0),
            ),
            tooltip: '채팅하기',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            
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
                                return _buildDefaultAvatar();
                              },
                            )
                          : _buildDefaultAvatar(),
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
                  
                  // MBTI 유형
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _getMBTIColor(user.mbtiType).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      user.mbtiType ?? '미완료',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: _getMBTIColor(user.mbtiType),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
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
            
                         // 활동 통계 카드
             Container(
               width: double.infinity,
               padding: EdgeInsets.all(20.w),
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
                       children: [
                         Text(
                           '활동 통계',
                           style: TextStyle(
                             fontSize: 16.sp,
                             fontWeight: FontWeight.w600,
                             color: const Color(0xFF1A1A1A),
                           ),
                         ),
                         SizedBox(height: 8.h),
                         Text(
                           '친구 ${user.stats.friendCount}명 · 채팅 ${user.stats.chatCount}개',
                           style: TextStyle(
                             fontSize: 14.sp,
                             color: const Color(0xFF6C757D),
                           ),
                         ),
                       ],
                     ),
                   ),
                   Container(
                     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                     decoration: BoxDecoration(
                       color: const Color(0xFF4CAF50).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12.r),
                     ),
                     child: Text(
                       '활발함',
                       style: TextStyle(
                         fontSize: 12.sp,
                         fontWeight: FontWeight.w600,
                         color: const Color(0xFF4CAF50),
                       ),
                     ),
                   ),
                 ],
               ),
             ),
            
            SizedBox(height: 20.h),
            
            // 채팅 시작 버튼
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    '알림',
                    '${user.name}님과 채팅을 시작합니다!',
                    backgroundColor: const Color(0xFF9C27B0).withOpacity(0.1),
                    colorText: const Color(0xFF9C27B0),
                  );
                  Get.back();
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
                      '채팅 시작하기',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  /// 기본 아바타 위젯
  Widget _buildDefaultAvatar() {
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

     /// MBTI 설명 반환
   String _getMBTIDescription(String? mbtiType) {
     if (mbtiType == null) return 'MBTI 테스트를 완료하지 않았습니다.';
     
     final descriptions = {
       'ENFP': '열정적이고 창의적인 성격으로, 새로운 경험을 사랑하며 사람들과의 소통을 즐깁니다.',
       'INTJ': '전략적이고 분석적인 사고를 가진 독립적인 성격으로, 장기적인 비전을 추구합니다.',
       'ISFP': '예술적이고 감성적인 성격으로, 개인의 가치관을 중요하게 생각하며 조화를 추구합니다.',
       'ENTP': '혁신적이고 도전적인 성격으로, 새로운 아이디어를 창조하고 토론을 즐깁니다.',
       'INFJ': '통찰력 있고 공감적인 성격으로, 타인의 마음을 이해하고 조화를 추구합니다.',
       'ESTJ': '체계적이고 책임감 있는 성격으로, 질서와 규칙을 중시하며 효율성을 추구합니다.',
       'INFP': '이상주의적이고 창의적인 성격으로, 개인의 가치관을 중요하게 생각합니다.',
       'ISTP': '실용적이고 적응력 있는 성격으로, 문제 해결에 능숙하며 독립적입니다.',
     };
     
     return descriptions[mbtiType] ?? 'MBTI 정보를 확인할 수 없습니다.';
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
}
