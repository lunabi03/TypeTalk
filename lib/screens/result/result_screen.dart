import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:share_plus/share_plus.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 고정 영역 (Hero + ResultCard)
            SizedBox(
              height: 400.h, // Hero 영역 + ResultCard 높이
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 배경 이미지 (Hero 영역)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 320.h,
                    child: Builder(
                      builder: (context) {
                        final double dpr = MediaQuery.of(context).devicePixelRatio;
                        final double widthPx = MediaQuery.of(context).size.width * dpr;
                        final double heightPx = 320.h * dpr;
                        return Image.asset(
                          'assets/images/img_ENFP.png',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          cacheWidth: widthPx.round(),
                          cacheHeight: heightPx.round(),
                        );
                      },
                    ),
                  ),
                  
                  // 홈 버튼
                  Positioned(
                    top: 4,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.home, color: Colors.black87),
                      onPressed: () => Get.offAllNamed('/'),
                    ),
                  ),
                  
                  // ResultCard (Hero 영역 아래에 고정)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 0,
                    child: const _ResultCard(),
                  ),
                ],
              ),
            ),

            // 스크롤 가능한 내용 부분 (MBTI 설명 + 궁합 정보)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 설명 텍스트
                    Text(
                      _descriptionFor(Get.arguments?['type'] as String?),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // 궁합 정보 섹션
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 궁합 제목
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: const Color(0xFFE91E63),
                                size: 24.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'MBTI 궁합',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 20.h),
                          
                          // 최고 궁합
                          _buildCompatibilitySection(
                            '최고 궁합',
                            _getBestCompatibility(Get.arguments?['type'] as String?),
                            const Color(0xFF4CAF50),
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          // 좋은 궁합
                          _buildCompatibilitySection(
                            '좋은 궁합',
                            _getGoodCompatibility(Get.arguments?['type'] as String?),
                            const Color(0xFF2196F3),
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          // 보통 궁합
                          _buildCompatibilitySection(
                            '보통 궁합',
                            _getNormalCompatibility(Get.arguments?['type'] as String?),
                            const Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 고정된 버튼 영역 (스크롤되지 않음)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _shareMBTIResult(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE1E3E6),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        '결과 공유하기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveMBTIResult(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        '프로필에 저장하기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 48.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MBTI 결과를 다른 앱으로 공유
  void _shareMBTIResult() {
    final mbtiType = Get.arguments?['type'] as String?;
    if (mbtiType == null || mbtiType.isEmpty) {
      Get.snackbar('오류', 'MBTI 결과를 찾을 수 없습니다.');
      return;
    }

    try {
      // MBTI 결과 정보 가져오기
      final info = _typeInfo[mbtiType] ?? _typeInfo['DEFAULT']!;
      final compatibility = _getBestCompatibility(mbtiType);
      
      // 공유할 텍스트 구성
      final shareText = '''
🎯 나의 MBTI 유형: $mbtiType

📝 성향 설명:
${info['desc']}

💪 강점:
${info['strength']}

⚠️ 주의점:
${info['watchout']}

💕 최고 궁합:
${compatibility['types']} - ${compatibility['reason']}

#MBTI #TypeMate #${mbtiType}
      '''.trim();

      // 공유 실행
      Share.share(
        shareText,
        subject: '나의 MBTI 결과: $mbtiType',
      );
      
    } catch (e) {
      Get.snackbar('오류', '결과 공유 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // MBTI 결과를 Firebase에 저장하고 프로필로 이동
  void _saveMBTIResult() async {
    final mbtiType = Get.arguments?['type'] as String?;
    if (mbtiType == null || mbtiType.isEmpty) {
      Get.snackbar('오류', 'MBTI 결과를 찾을 수 없습니다.');
      return;
    }

    try {
      final authController = Get.find<AuthController>();
      
      // MBTI 결과를 Firebase에 저장
      await authController.updateUserMBTI(mbtiType);
      
      // 성공 메시지 표시
      Get.snackbar(
        '성공', 
        'MBTI 결과가 프로필에 저장되었습니다!',
        duration: const Duration(seconds: 2),
      );
      
      // 잠시 후 프로필 화면으로 이동
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/profile');
      });
      
    } catch (e) {
      Get.snackbar('오류', 'MBTI 결과 저장에 실패했습니다: ${e.toString()}');
    }
  }
  
  /// 궁합 섹션 위젯
  Widget _buildCompatibilitySection(String title, Map<String, String> compatibility, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            compatibility['types'] ?? '',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            compatibility['reason'] ?? '',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.4,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '당신의 MBTI 유형은',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black54,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _titleFor(Get.arguments?['type'] as String?, Get.arguments?['title'] as String?),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

String _titleFor(String? type, String? providedTitle) {
  if (providedTitle != null && providedTitle.isNotEmpty) return providedTitle;
  if (type == null || type.isEmpty) return '결과를 확인하세요';
  return '$type 결과';
}

String _descriptionFor(String? type) {
  final info = _typeInfo[type ?? ''] ?? _typeInfo['DEFAULT']!;
  return '${info['desc']}\n\n강점: ${info['strength']}\n주의점: ${info['watchout']}';
}

// 궁합 정보 반환 함수들
Map<String, String> _getBestCompatibility(String? type) {
  return _compatibilityInfo[type ?? '']?['best'] ?? _compatibilityInfo['DEFAULT']!['best']!;
}

Map<String, String> _getGoodCompatibility(String? type) {
  return _compatibilityInfo[type ?? '']?['good'] ?? _compatibilityInfo['DEFAULT']!['good']!;
}

Map<String, String> _getNormalCompatibility(String? type) {
  return _compatibilityInfo[type ?? '']?['normal'] ?? _compatibilityInfo['DEFAULT']!['normal']!;
}

// 16가지 유형별 부가 설명
const Map<String, Map<String, String>> _typeInfo = {
  'ISTJ': {
    'desc': '책임감이 강하고 체계적인 성향으로\n원칙을 지키며 일을 끝까지 완수합니다.\n\nISTJ는 현실적이고 실용적인 성향을 가지고 있으며, 전통과 질서를 중시합니다. 계획을 세우고 그에 따라 체계적으로 일을 처리하는 것을 선호하며, 신뢰할 수 있는 동료로 인정받습니다.',
    'strength': '신뢰성, 치밀함, 현실감각, 책임감, 인내심, 논리적 사고, 효율성, 정확성',
    'watchout': '융통성 부족, 변화 적응 지연, 감정 표현 부족, 완벽주의적 성향, 타인의 감정 고려 부족'
  },
  'ISFJ': {
    'desc': '헌신적이고 배려심이 깊어\n주변을 든든하게 지켜주는 조력자입니다.\n\nISFJ는 따뜻하고 공감능력이 뛰어나며, 다른 사람의 필요를 먼저 생각합니다. 안정적이고 조화로운 환경을 만들기 위해 노력하며, 전통과 가치를 소중히 여깁니다.',
    'strength': '성실함, 공감능력, 세심함, 헌신, 인내심, 실용성, 배려, 안정감',
    'watchout': '자기희생 과다, 자기표현 부족, 과도한 책임감, 변화 두려움, 갈등 회피'
  },
  'INFJ': {
    'desc': '통찰력과 이상을 바탕으로\n의미 있는 변화를 이끄는 조용한 리더입니다.\n\nINFJ는 깊은 통찰력과 창의성을 가지고 있으며, 사람들의 잠재력을 발견하고 성장을 돕는 것을 좋아합니다. 이상주의적이면서도 현실적인 접근을 통해 의미 있는 변화를 만들어냅니다.',
    'strength': '비전, 공감, 깊이 있는 사고, 창의성, 통찰력, 영감, 헌신, 이상주의',
    'watchout': '완벽주의, 에너지 소진, 과도한 이상주의, 감정적 민감성, 타인 기대 부담'
  },
  'INTJ': {
    'desc': '전략적이고 분석적인 사고로\n장기 목표를 설계하고 효율적으로 실현합니다.\n\nINTJ는 독창적이고 독립적인 사고를 가지고 있으며, 복잡한 문제를 체계적으로 분석하고 해결합니다. 장기적인 비전을 가지고 효율적인 전략을 수립하여 목표를 달성합니다.',
    'strength': '전략, 독립성, 계획력, 분석력, 창의성, 결단력, 효율성, 지적 호기심',
    'watchout': '감정표현 부족, 융화 어려움, 완벽주의, 타인 감정 무시, 과도한 독립성'
  },
  'ISTP': {
    'desc': '문제 해결에 강하고 실용적인 접근으로\n상황을 차분히 분석해 해결책을 찾습니다.\n\nISTP는 논리적이고 실용적인 성향을 가지고 있으며, 위기 상황에서도 침착하게 대응합니다. 문제의 핵심을 파악하고 효율적인 해결책을 찾아내는 능력이 뛰어납니다.',
    'strength': '분석력, 유연성, 위기대응, 실용성, 논리적 사고, 적응력, 문제해결, 침착함',
    'watchout': '감정 소통 부족, 장기계획 미흡, 규칙 준수 어려움, 감정 표현 부족, 관계 유지 어려움'
  },
  'ISFP': {
    'desc': '따뜻하고 온화하며\n자신과 주변의 조화를 소중히 여깁니다.\n\nISFP는 예술적 감각과 공감능력을 가지고 있으며, 아름다움과 조화를 추구합니다. 다른 사람의 감정에 민감하게 반응하며, 평화로운 환경을 만들기 위해 노력합니다.',
    'strength': '공감, 미적감각, 겸손함, 따뜻함, 인내심, 현실적, 유연성, 평화 추구',
    'watchout': '결정 지연, 갈등 회피, 자기표현 부족, 계획성 부족, 타인 의존성'
  },
  'INFP': {
    'desc': '가치와 이상을 중시하며\n의미 있는 일에 진심을 다합니다.\n\nINFP는 창의적이고 이상주의적인 성향을 가지고 있으며, 자신의 가치관과 일치하는 일에 깊은 열정을 보입니다. 다른 사람의 성장과 발전을 돕는 것을 좋아하며, 의미 있는 변화를 만들어냅니다.',
    'strength': '창의성, 진정성, 공감, 이상주의, 열정, 영감, 유연성, 깊이 있는 사고',
    'watchout': '현실 실행력 부족, 과몰입, 감정적 민감성, 완벽주의, 우선순위 설정 어려움'
  },
  'INTP': {
    'desc': '논리적 탐구심이 강하고\n새로운 아이디어를 구조적으로 이해합니다.\n\nINTP는 독창적이고 분석적인 사고를 가지고 있으며, 복잡한 개념과 이론을 탐구하는 것을 즐깁니다. 문제를 논리적으로 분석하고 혁신적인 해결책을 찾아내는 능력이 뛰어납니다.',
    'strength': '논리, 호기심, 문제해결, 창의성, 분석력, 독립성, 깊이 있는 사고, 혁신',
    'watchout': '완성 지연, 소통 단절, 실용성 부족, 감정 표현 부족, 일상적 업무 기피'
  },
  'ESTP': {
    'desc': '대담하고 에너지 넘치며\n현장 중심으로 기회를 포착합니다.\n\nESTP는 실용적이고 적응력이 뛰어나며, 즉흥적이고 모험을 즐깁니다. 현실적인 문제를 빠르게 파악하고 실용적인 해결책을 제시하며, 위기 상황에서도 침착하게 대응합니다.',
    'strength': '결단력, 적응력, 실행력, 현실감각, 유연성, 위기대응, 에너지, 실용성',
    'watchout': '성급함, 장기적 고려 부족, 규칙 준수 어려움, 감정 표현 부족, 계획성 부족'
  },
  'ESFP': {
    'desc': '활기차고 사람들과 어울리며\n순간의 즐거움을 만들어냅니다.\n\nESFP는 사교적이고 낙천적인 성향을 가지고 있으며, 사람들과 어울리는 것을 좋아합니다. 현재의 즐거움을 중시하며, 긍정적인 에너지로 주변을 밝게 만듭니다.',
    'strength': '사교성, 낙천성, 현장감, 공감, 적응력, 에너지, 실용성, 낙관주의',
    'watchout': '계획성 부족, 과도한 자극 추구, 장기적 목표 부족, 감정적 변동, 집중력 부족'
  },
  'ENFP': {
    'desc': '열정적이고 창의적이며\n다양한 가능성을 발견해 영감을 전합니다.\n\nENFP는 창의적이고 열정적인 성향을 가지고 있으며, 새로운 가능성과 아이디어를 발견하는 것을 즐깁니다. 사람들에게 영감을 주고 변화를 이끄는 능력이 뛰어나며, 다양한 관점을 고려합니다.',
    'strength': '창의성, 공감, 추진력, 열정, 영감, 유연성, 통찰력, 적응력',
    'watchout': '지속성 부족, 산만함, 완성도 저하, 우선순위 설정 어려움, 감정적 변동'
  },
  'ENTP': {
    'desc': '아이디어로 세상을 도전하며\n새로운 관점을 제시합니다.\n\nENTP는 창의적이고 혁신적인 사고를 가지고 있으며, 기존의 관습과 규칙에 도전하는 것을 즐깁니다. 논리적이고 분석적인 접근으로 새로운 아이디어를 발전시키며, 다양한 가능성을 탐구합니다.',
    'strength': '발상 전환, 설득력, 기민함, 창의성, 논리, 적응력, 혁신, 호기심',
    'watchout': '완성도 저하, 논쟁 과다, 감정 표현 부족, 일상적 업무 기피, 감정적 민감성 부족'
  },
  'ESTJ': {
    'desc': '조직적이고 실용적인 리더십으로\n목표를 체계적으로 달성합니다.\n\nESTJ는 체계적이고 실용적인 성향을 가지고 있으며, 질서와 규칙을 중시합니다. 효율적인 조직 운영과 목표 달성을 위해 체계적으로 일을 처리하며, 명확한 기준과 절차를 제시합니다.',
    'strength': '결단력, 책임감, 실행력, 조직력, 실용성, 효율성, 리더십, 신뢰성',
    'watchout': '경직성, 유연성 부족, 감정 고려 부족, 변화 저항, 타인 감정 무시'
  },
  'ESFJ': {
    'desc': '배려와 조화를 중시하며\n사람 중심의 관계를 이끕니다.\n\nESFJ는 사교적이고 배려심이 깊으며, 사람들과의 관계를 소중히 여깁니다. 조화로운 환경을 만들기 위해 노력하며, 다른 사람의 필요를 파악하고 적절한 도움을 제공합니다.',
    'strength': '조정능력, 친화력, 성실함, 공감, 배려, 협력, 실용성, 안정감',
    'watchout': '자기희생 과다, 비판에 민감, 갈등 회피, 변화 두려움, 타인 기대 부담'
  },
  'ENFJ': {
    'desc': '공감과 비전으로 팀을 이끄는\n영향력 있는 코치형 리더입니다.\n\nENFJ는 공감능력과 리더십을 가지고 있으며, 다른 사람의 성장과 발전을 돕는 것을 좋아합니다. 팀의 잠재력을 발견하고 영감을 주어 목표 달성을 이끌어내며, 조화로운 관계를 만듭니다.',
    'strength': '리더십, 공감, 조직화, 영감, 배려, 설득력, 협력, 비전',
    'watchout': '과도한 책임, 감정 소모, 자기희생, 완벽주의, 타인 기대 부담'
  },
  'ENTJ': {
    'desc': '목표 지향적이며 체계적인 추진으로\n큰 그림을 현실로 만듭니다.\n\nENTJ는 전략적이고 목표 지향적인 성향을 가지고 있으며, 큰 비전을 체계적으로 실현합니다. 효율적인 의사결정과 실행력을 바탕으로 조직을 이끌며, 명확한 방향성을 제시합니다.',
    'strength': '전략, 추진력, 의사결정, 리더십, 효율성, 분석력, 결단력, 비전',
    'watchout': '엄격함, 감정 고려 부족, 타인 감정 무시, 완벽주의, 과도한 통제'
  },
  'DEFAULT': {
    'desc': '당신의 성향을 바탕으로 도출된 결과입니다.\n강점을 살리고 약점을 보완할 수 있는 방향을 함께 찾아봅시다.\n\nMBTI는 성격의 한 측면을 보여주는 도구일 뿐입니다. 각 유형의 특징을 이해하고 자신의 강점을 활용하면서도 개선할 수 있는 부분에 대해 노력하는 것이 중요합니다.',
    'strength': '성장 가능성, 학습 의지, 자기 이해, 적응력, 발전 의지',
    'watchout': '과도한 일반화 지양, 고정관념 경계, 지속적 성장 추구'
  },
};

// 16가지 유형별 궁합 정보
const Map<String, Map<String, Map<String, String>>> _compatibilityInfo = {
  'ISTJ': {
    'best': {
      'types': 'ESFP, ENFP',
      'reason': 'ISTJ의 안정성과 체계성을 ESFP/ENFP의 활기찬 에너지와 열정이 보완해주며, 서로의 차이점을 통해 균형잡힌 관계를 형성합니다.'
    },
    'good': {
      'types': 'ISFJ, ESTJ, ENTJ',
      'reason': '비슷한 가치관과 실용적인 성향으로 안정적이고 신뢰할 수 있는 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': 'ISTP, ISFP, ESTP, ESFJ',
      'reason': '일부 공통점이 있지만 서로 다른 접근 방식으로 인해 적응이 필요한 관계입니다.'
    }
  },
  'ISFJ': {
    'best': {
      'types': 'ESFP, ESTP',
      'reason': 'ISFJ의 따뜻함과 배려심이 ESFP/ESTP의 활발함과 실용성을 지원하며, 서로의 강점을 균형있게 활용할 수 있습니다.'
    },
    'good': {
      'types': 'ISTJ, ESFJ, ISFP',
      'reason': '공감능력과 실용성을 공유하여 따뜻하고 안정적인 관계를 형성할 수 있습니다.'
    },
    'normal': {
      'types': 'INFJ, ISFP, ESTJ, ENFJ',
      'reason': '비슷한 가치관을 가지고 있지만 의사소통 방식의 차이로 인해 이해가 필요한 관계입니다.'
    }
  },
  'INFJ': {
    'best': {
      'types': 'ENFP, ENTP',
      'reason': 'INFJ의 깊은 통찰력과 이상주의가 ENFP/ENTP의 창의성과 혁신 정신과 결합되어 영감을 주는 관계를 만듭니다.'
    },
    'good': {
      'types': 'INFP, ENFJ, INTJ',
      'reason': '비전과 가치관을 공유하며 깊이 있는 대화와 성장을 이끌어낼 수 있습니다.'
    },
    'normal': {
      'types': 'ISFJ, ISFP, INTP, ENTJ',
      'reason': '일부 공통 관심사가 있지만 사고 방식의 차이로 인해 상호 이해가 필요한 관계입니다.'
    }
  },
  'INTJ': {
    'best': {
      'types': 'ENFP, ENTP',
      'reason': 'INTJ의 전략적 사고와 독립성이 ENFP/ENTP의 창의성과 적응력과 결합되어 혁신적인 아이디어를 만들어냅니다.'
    },
    'good': {
      'types': 'INFJ, INTP, ENTJ',
      'reason': '논리적 사고와 장기적 비전을 공유하여 효율적이고 목표 지향적인 관계를 형성할 수 있습니다.'
    },
    'normal': {
      'types': 'ISTJ, ISTP, INTJ, ESTJ',
      'reason': '비슷한 사고 방식을 가지고 있지만 감정적 소통의 부족으로 인해 관계 발전에 제한이 있을 수 있습니다.'
    }
  },
  'ISTP': {
    'best': {
      'types': 'ESFJ, ENFJ',
      'reason': 'ISTP의 실용적 문제해결 능력이 ESFJ/ENFJ의 사교성과 배려심과 결합되어 균형잡힌 관계를 형성합니다.'
    },
    'good': {
      'types': 'ESTP, ISFP, ISTJ',
      'reason': '실용성과 적응력을 공유하여 효율적이고 유연한 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': 'INTP, ESTP, ISFP, ENTJ',
      'reason': '일부 공통 관심사가 있지만 장기적 계획과 감정적 소통의 차이로 인해 발전이 제한될 수 있습니다.'
    }
  },
  'ISFP': {
    'best': {
      'types': 'ENFJ, ENTJ',
      'reason': 'ISFP의 예술적 감각과 공감능력이 ENFJ/ENTJ의 리더십과 비전과 결합되어 창의적이고 영감을 주는 관계를 만듭니다.'
    },
    'good': {
      'types': 'ISFJ, ESFP, ISFP',
      'reason': '공감능력과 미적 감각을 공유하여 따뜻하고 조화로운 관계를 형성할 수 있습니다.'
    },
    'normal': {
      'types': 'ISTP, INFP, ESFJ, ESTP',
      'reason': '비슷한 가치관을 가지고 있지만 의사결정과 계획성의 차이로 인해 상호 보완이 필요한 관계입니다.'
    }
  },
  'INFP': {
    'best': {
      'types': 'ENFJ, ENTJ',
      'reason': 'INFP의 이상주의와 창의성이 ENFJ/ENTJ의 리더십과 실행력과 결합되어 의미 있는 변화를 만들어내는 관계입니다.'
    },
    'good': {
      'types': 'INFJ, ENFP, INFP',
      'reason': '가치관과 창의성을 공유하며 깊이 있는 대화와 성장을 이끌어낼 수 있습니다.'
    },
    'normal': {
      'types': 'ISFP, INTP, ENFP, ESFJ',
      'reason': '일부 공통 관심사가 있지만 현실적 실행력과 계획성의 차이로 인해 균형이 필요한 관계입니다.'
    }
  },
  'INTP': {
    'best': {
      'types': 'ENFJ, ESFJ',
      'reason': 'INTP의 논리적 분석 능력이 ENFJ/ESFJ의 공감능력과 조직력을 지원하여 혁신적인 해결책을 만들어냅니다.'
    },
    'good': {
      'types': 'INTJ, INFP, INTP',
      'reason': '논리적 사고와 창의성을 공유하여 깊이 있는 지적 교류와 성장을 이끌어낼 수 있습니다.'
    },
    'normal': {
      'types': 'ISTP, ISTJ, ENTP, ENTJ',
      'reason': '비슷한 사고 방식을 가지고 있지만 감정적 소통과 실용적 실행력의 부족으로 인해 관계 발전에 제한이 있을 수 있습니다.'
    }
  },
  'ESTP': {
    'best': {
      'types': 'ISFJ, INFJ',
      'reason': 'ESTP의 실용적 실행력이 ISFJ/INFJ의 배려심과 통찰력을 지원하여 균형잡힌 관계를 형성합니다.'
    },
    'good': {
      'types': 'ISTP, ESFP, ESTP',
      'reason': '실용성과 적응력을 공유하여 활발하고 효율적인 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': 'ESTJ, ESFP, ISTP, ENTP',
      'reason': '일부 공통 관심사가 있지만 장기적 계획과 감정적 소통의 차이로 인해 발전이 제한될 수 있습니다.'
    }
  },
  'ESFP': {
    'best': {
      'types': 'ISTJ, INTJ',
      'reason': 'ESFP의 활기찬 에너지와 사교성이 ISTJ/INTJ의 체계성과 계획성을 보완하여 균형잡힌 관계를 형성합니다.'
    },
    'good': {
      'types': 'ISFJ, ESTP, ESFP',
      'reason': '사교성과 실용성을 공유하여 즐겁고 활발한 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': 'ENFP, ESFJ, ISFP, ESTP',
      'reason': '비슷한 성향을 가지고 있지만 장기적 목표와 계획성의 차이로 인해 상호 보완이 필요한 관계입니다.'
    }
  },
  'ENFP': {
    'best': {
      'types': 'ISTJ, INTJ',
      'reason': 'ENFP의 창의성과 열정이 ISTJ/INTJ의 체계성과 전략적 사고를 보완하여 혁신적인 아이디어를 만들어냅니다.'
    },
    'good': {
      'types': 'INFP, ENFJ, ENFP',
      'reason': '창의성과 열정을 공유하며 영감을 주고받는 활발한 관계를 형성할 수 있습니다.'
    },
    'normal': {
      'types': 'ESFP, ENTP, INFJ, ESFJ',
      'reason': '일부 공통 관심사가 있지만 실행력과 계획성의 차이로 인해 균형이 필요한 관계입니다.'
    }
  },
  'ENTP': {
    'best': {
      'types': 'ISFJ, INFJ',
      'reason': 'ENTP의 혁신적 사고와 도전 정신이 ISFJ/INFJ의 안정성과 배려심과 결합되어 창의적인 변화를 만들어냅니다.'
    },
    'good': {
      'types': 'INTJ, ENFP, ENTP',
      'reason': '창의성과 혁신 정신을 공유하여 도전적이고 흥미로운 관계를 형성할 수 있습니다.'
    },
    'normal': {
      'types': 'ESTP, ISTP, ENFP, ENTJ',
      'reason': '비슷한 성향을 가지고 있지만 감정적 소통과 안정성의 차이로 인해 상호 이해가 필요한 관계입니다.'
    }
  },
  'ESTJ': {
    'best': {
      'types': 'ISFP, INFP',
      'reason': 'ESTJ의 체계적 조직력이 ISFP/INFP의 창의성과 공감능력을 지원하여 효율적이고 따뜻한 관계를 형성합니다.'
    },
    'good': {
      'types': 'ISTJ, ESFJ, ESTJ',
      'reason': '체계성과 실용성을 공유하여 안정적이고 효율적인 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': 'ENTJ, ISTP, ESTP, ESFJ',
      'reason': '비슷한 가치관을 가지고 있지만 유연성과 감정적 소통의 차이로 인해 발전이 제한될 수 있습니다.'
    }
  },
  'ESFJ': {
    'best': {
      'types': 'INTP, ISTP',
      'reason': 'ESFJ의 사교성과 배려심이 INTP/ISTP의 논리적 사고와 실용성을 지원하여 균형잡힌 관계를 형성합니다.'
    },
    'good': {
      'types': 'ISFJ, ESTJ, ESFJ',
      'reason': '사교성과 배려심을 공유하여 따뜻하고 조화로운 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': 'ENFJ, ISFP, ESFP, ESTP',
      'reason': '비슷한 성향을 가지고 있지만 리더십과 독립성의 차이로 인해 상호 보완이 필요한 관계입니다.'
    }
  },
  'ENFJ': {
    'best': {
      'types': 'ISFP, INFP',
      'reason': 'ENFJ의 리더십과 영감이 ISFP/INFP의 창의성과 공감능력과 결합되어 의미 있는 변화를 만들어내는 관계입니다.'
    },
    'good': {
      'types': 'INFJ, ENFP, ENFJ',
      'reason': '리더십과 공감능력을 공유하며 영감을 주고받는 활발한 관계를 형성할 수 있습니다.'
    },
    'normal': {
      'types': 'ESFJ, ISFJ, ENFP, ENTJ',
      'reason': '일부 공통 관심사가 있지만 독립성과 실용성의 차이로 인해 균형이 필요한 관계입니다.'
    }
  },
  'ENTJ': {
    'best': {
      'types': 'ISFP, INFP',
      'reason': 'ENTJ의 전략적 리더십이 ISFP/INFP의 창의성과 공감능력을 지원하여 혁신적이고 의미 있는 관계를 형성합니다.'
    },
    'good': {
      'types': 'INTJ, ENFJ, ENTJ',
      'reason': '전략적 사고와 리더십을 공유하여 효율적이고 목표 지향적인 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': 'ESTJ, ISTJ, ENTP, ENFJ',
      'reason': '비슷한 성향을 가지고 있지만 감정적 소통과 유연성의 차이로 인해 상호 이해가 필요한 관계입니다.'
    }
  },
  'DEFAULT': {
    'best': {
      'types': '모든 유형',
      'reason': 'MBTI는 성격의 한 측면일 뿐이며, 개인의 성장과 노력에 따라 모든 유형과 좋은 관계를 형성할 수 있습니다.'
    },
    'good': {
      'types': '대부분의 유형',
      'reason': '상호 이해와 존중을 바탕으로 대부분의 MBTI 유형과 조화로운 관계를 만들 수 있습니다.'
    },
    'normal': {
      'types': '일부 유형',
      'reason': '개인의 성향과 상황에 따라 관계의 질이 달라질 수 있으며, 지속적인 소통과 이해가 중요합니다.'
    }
  },
};