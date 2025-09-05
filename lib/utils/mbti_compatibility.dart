/// MBTI 궁합 점수 계산 유틸리티
class MBTICompatibility {
  /// MBTI 궁합 점수 계산
  /// 
  /// [userMBTI] 사용자의 MBTI
  /// [partnerMBTI] 상대방의 MBTI
  /// 
  /// 반환값: 0-100 사이의 궁합 점수
  static int calculateCompatibility(String userMBTI, String partnerMBTI) {
    if (userMBTI.isEmpty || partnerMBTI.isEmpty) return 50;
    
    // MBTI를 구성 요소로 분해
    final userComponents = _parseMBTI(userMBTI);
    final partnerComponents = _parseMBTI(partnerMBTI);
    
    if (userComponents == null || partnerComponents == null) return 50;
    
    int score = 0;
    
    // 1. 에너지 방향 (E/I) - 25점
    if (userComponents['energy'] == partnerComponents['energy']) {
      score += 15; // 같은 에너지 방향
    } else {
      score += 20; // 상호 보완적
    }
    
    // 2. 인식 기능 (S/N) - 25점
    if (userComponents['perception'] == partnerComponents['perception']) {
      score += 20; // 같은 인식 방식
    } else {
      score += 15; // 상호 보완적
    }
    
    // 3. 판단 기능 (T/F) - 25점
    if (userComponents['judgment'] == partnerComponents['judgment']) {
      score += 18; // 같은 판단 방식
    } else {
      score += 22; // 상호 보완적 (더 높은 점수)
    }
    
    // 4. 생활 양식 (J/P) - 25점
    if (userComponents['lifestyle'] == partnerComponents['lifestyle']) {
      score += 20; // 같은 생활 양식
    } else {
      score += 18; // 상호 보완적
    }
    
    // 5. 특별한 궁합 조합 보너스
    score += _getSpecialCompatibilityBonus(userMBTI, partnerMBTI);
    
    // 점수를 0-100 범위로 제한
    return score.clamp(0, 100);
  }
  
  /// MBTI를 구성 요소로 분해
  static Map<String, String>? _parseMBTI(String mbti) {
    if (mbti.length != 4) return null;
    
    return {
      'energy': mbti[0], // E/I
      'perception': mbti[1], // S/N
      'judgment': mbti[2], // T/F
      'lifestyle': mbti[3], // J/P
    };
  }
  
  /// 특별한 궁합 조합 보너스 점수
  static int _getSpecialCompatibilityBonus(String userMBTI, String partnerMBTI) {
    // 잘 알려진 궁합 조합들
    final compatibilityPairs = [
      ['ENFP', 'INTJ'], ['INTJ', 'ENFP'],
      ['ENFP', 'INFJ'], ['INFJ', 'ENFP'],
      ['ENTP', 'INFJ'], ['INFJ', 'ENTP'],
      ['ENTJ', 'INFP'], ['INFP', 'ENTJ'],
      ['ESTJ', 'ISFP'], ['ISFP', 'ESTJ'],
      ['ESFJ', 'ISTP'], ['ISTP', 'ESFJ'],
      ['ESTP', 'ISFJ'], ['ISFJ', 'ESTP'],
      ['ESFP', 'ISTJ'], ['ISTJ', 'ESFP'],
      ['INTP', 'ENTJ'], ['ENTJ', 'INTP'],
      ['INTP', 'ESTJ'], ['ESTJ', 'INTP'],
      ['INTJ', 'ENTP'], ['ENTP', 'INTJ'],
      ['INFJ', 'ENTP'], ['ENTP', 'INFJ'],
    ];
    
    // 정확히 일치하는 조합이 있는지 확인
    for (final pair in compatibilityPairs) {
      if ((userMBTI == pair[0] && partnerMBTI == pair[1]) ||
          (userMBTI == pair[1] && partnerMBTI == pair[0])) {
        return 10; // 특별한 궁합 보너스
      }
    }
    
    // 같은 MBTI인 경우
    if (userMBTI == partnerMBTI) {
      return 5; // 같은 유형 보너스
    }
    
    return 0;
  }
  
  /// 궁합 점수에 따른 설명 텍스트
  static String getCompatibilityDescription(int score) {
    if (score >= 90) return '완벽한 궁합!';
    if (score >= 80) return '매우 좋은 궁합';
    if (score >= 70) return '좋은 궁합';
    if (score >= 60) return '괜찮은 궁합';
    if (score >= 50) return '보통 궁합';
    if (score >= 40) return '조금 어려운 궁합';
    return '어려운 궁합';
  }
  
  /// 궁합 점수에 따른 색상
  static int getCompatibilityColor(int score) {
    if (score >= 80) return 0xFF4CAF50; // 초록색
    if (score >= 60) return 0xFFFF9800; // 주황색
    if (score >= 40) return 0xFFFF5722; // 빨간색
    return 0xFF9E9E9E; // 회색
  }
}

