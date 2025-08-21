import 'package:typetalk/services/firestore_service.dart';

// MBTI 점수 모델
class MBTIScores {
  final double eI; // 외향성-내향성 (-100 ~ 100)
  final double sN; // 감각-직관 (-100 ~ 100)
  final double tF; // 사고-감정 (-100 ~ 100)
  final double jP; // 판단-인식 (-100 ~ 100)

  MBTIScores({
    required this.eI,
    required this.sN,
    required this.tF,
    required this.jP,
  });

  Map<String, dynamic> toMap() {
    return {
      'E_I': eI,
      'S_N': sN,
      'T_F': tF,
      'J_P': jP,
    };
  }

  factory MBTIScores.fromMap(Map<String, dynamic> map) {
    return MBTIScores(
      eI: (map['E_I'] ?? 0.0).toDouble(),
      sN: (map['S_N'] ?? 0.0).toDouble(),
      tF: (map['T_F'] ?? 0.0).toDouble(),
      jP: (map['J_P'] ?? 0.0).toDouble(),
    );
  }

  // MBTI 타입 계산
  String calculateMBTIType() {
    final e = eI > 0 ? 'E' : 'I';
    final s = sN > 0 ? 'N' : 'S';
    final t = tF > 0 ? 'F' : 'T';
    final j = jP > 0 ? 'P' : 'J';
    return '$e$s$t$j';
  }

  // 성향 강도 (0-100)
  double get extroversionStrength => eI.abs();
  double get intuitionStrength => sN.abs();
  double get feelingStrength => tF.abs();
  double get perceivingStrength => jP.abs();

  @override
  String toString() {
    return 'MBTIScores(E/I: $eI, S/N: $sN, T/F: $tF, J/P: $jP) -> ${calculateMBTIType()}';
  }
}

// MBTI 질문 답변 모델
class MBTIAnswer {
  final String questionId;
  final int answer; // 1-5 점수
  final int timeSpent; // 답변에 소요된 시간(초)

  MBTIAnswer({
    required this.questionId,
    required this.answer,
    required this.timeSpent,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'answer': answer,
      'timeSpent': timeSpent,
    };
  }

  factory MBTIAnswer.fromMap(Map<String, dynamic> map) {
    return MBTIAnswer(
      questionId: map['questionId'] ?? '',
      answer: map['answer'] ?? 3,
      timeSpent: map['timeSpent'] ?? 0,
    );
  }
}

// MBTI 테스트 메타데이터 모델
class MBTITestMetadata {
  final String version;
  final int totalQuestions;
  final int totalTimeSpent;
  final double accuracy; // 답변 일관성 점수 (0-100)

  MBTITestMetadata({
    required this.version,
    required this.totalQuestions,
    required this.totalTimeSpent,
    required this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'totalQuestions': totalQuestions,
      'totalTimeSpent': totalTimeSpent,
      'accuracy': accuracy,
    };
  }

  factory MBTITestMetadata.fromMap(Map<String, dynamic> map) {
    return MBTITestMetadata(
      version: map['version'] ?? '1.0',
      totalQuestions: map['totalQuestions'] ?? 0,
      totalTimeSpent: map['totalTimeSpent'] ?? 0,
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
    );
  }
}

// 메인 MBTI 테스트 모델
class MBTITestModel {
  final String testId;
  final String userId;
  final String result;
  final DateTime completedAt;
  final MBTIScores scores;
  final List<MBTIAnswer> answers;
  final MBTITestMetadata metadata;

  MBTITestModel({
    required this.testId,
    required this.userId,
    required this.result,
    required this.completedAt,
    required this.scores,
    required this.answers,
    required this.metadata,
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'userId': userId,
      'result': result,
      'completedAt': completedAt,
      'scores': scores.toMap(),
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'metadata': metadata.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory MBTITestModel.fromMap(Map<String, dynamic> map) {
    return MBTITestModel(
      testId: map['testId'] ?? '',
      userId: map['userId'] ?? '',
      result: map['result'] ?? '',
      completedAt: map['completedAt'] is DateTime 
          ? map['completedAt'] 
          : DateTime.now(),
      scores: map['scores'] != null 
          ? MBTIScores.fromMap(map['scores']) 
          : MBTIScores(eI: 0, sN: 0, tF: 0, jP: 0),
      answers: map['answers'] != null 
          ? List<MBTIAnswer>.from(
              map['answers'].map((answer) => MBTIAnswer.fromMap(answer)))
          : [],
      metadata: map['metadata'] != null 
          ? MBTITestMetadata.fromMap(map['metadata']) 
          : MBTITestMetadata(
              version: '1.0', 
              totalQuestions: 0, 
              totalTimeSpent: 0, 
              accuracy: 0.0),
    );
  }

  // Firestore 문서 스냅샷에서 생성
  factory MBTITestModel.fromSnapshot(DemoDocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      throw Exception('MBTI 테스트 문서가 존재하지 않습니다.');
    }
    return MBTITestModel.fromMap(snapshot.data);
  }

  @override
  String toString() {
    return 'MBTITestModel(testId: $testId, userId: $userId, result: $result, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MBTITestModel && other.testId == testId;
  }

  @override
  int get hashCode => testId.hashCode;
}

// MBTI 호환성 계산기
class MBTICompatibilityCalculator {
  // 두 MBTI 타입 간의 호환성 점수 계산 (0-100)
  static double calculateCompatibility(String mbti1, String mbti2) {
    if (mbti1.length != 4 || mbti2.length != 4) {
      return 50.0; // 기본값
    }

    double score = 0.0;
    
    // E/I 호환성
    if (mbti1[0] == mbti2[0]) {
      score += 15; // 같은 성향
    } else {
      score += 25; // 보완 관계
    }
    
    // S/N 호환성
    if (mbti1[1] == mbti2[1]) {
      score += 35; // 정보 처리 방식이 같으면 높은 점수
    } else {
      score += 10; // 다르면 낮은 점수
    }
    
    // T/F 호환성
    if (mbti1[2] == mbti2[2]) {
      score += 20; // 의사결정 방식이 같으면 좋음
    } else {
      score += 15; // 다르면 약간 낮음
    }
    
    // J/P 호환성
    if (mbti1[3] == mbti2[3]) {
      score += 15; // 생활 방식이 같으면 좋음
    } else {
      score += 25; // 보완 관계
    }
    
    return score.clamp(0.0, 100.0);
  }

  // MBTI 카테고리별 그룹화
  static String getMBTICategory(String mbti) {
    if (mbti.length != 4) return 'UNKNOWN';
    
    final intuition = mbti[1] == 'N';
    final thinking = mbti[2] == 'T';
    
    if (intuition && thinking) return 'NT'; // 분석가
    if (intuition && !thinking) return 'NF'; // 외교관
    if (!intuition && thinking) return 'ST'; // 관리자
    if (!intuition && !thinking) return 'SF'; // 탐험가
    
    return 'UNKNOWN';
  }

  // 추천 MBTI 타입들 반환
  static List<String> getRecommendedMBTITypes(String mbti) {
    final category = getMBTICategory(mbti);
    
    switch (category) {
      case 'NT':
        return ['NT', 'NF']; // 직관형들과 잘 맞음
      case 'NF':
        return ['NF', 'NT']; // 직관형들과 잘 맞음
      case 'ST':
        return ['ST', 'SF']; // 감각형들과 잘 맞음
      case 'SF':
        return ['SF', 'ST']; // 감각형들과 잘 맞음
      default:
        return ['NT', 'NF', 'ST', 'SF']; // 모든 타입
    }
  }

  // 가장 호환성이 높은 MBTI 타입들
  static List<String> getMostCompatibleTypes(String mbti) {
    final compatibilityMap = <String, double>{};
    
    final allTypes = [
      'INTJ', 'INTP', 'ENTJ', 'ENTP', // NT
      'INFJ', 'INFP', 'ENFJ', 'ENFP', // NF
      'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', // SJ
      'ISTP', 'ISFP', 'ESTP', 'ESFP', // SP
    ];
    
    for (final type in allTypes) {
      compatibilityMap[type] = calculateCompatibility(mbti, type);
    }
    
    // 호환성 점수 기준으로 정렬
    final sortedTypes = compatibilityMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 상위 5개 타입 반환
    return sortedTypes.take(5).map((e) => e.key).toList();
  }
}

// MBTI 질문 모델
class MBTIQuestion {
  final String questionId;
  final String question;
  final String category; // 'E_I', 'S_N', 'T_F', 'J_P'
  final List<String> options;
  final List<int> scores; // 각 옵션에 대한 점수

  MBTIQuestion({
    required this.questionId,
    required this.question,
    required this.category,
    required this.options,
    required this.scores,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'question': question,
      'category': category,
      'options': options,
      'scores': scores,
    };
  }

  factory MBTIQuestion.fromMap(Map<String, dynamic> map) {
    return MBTIQuestion(
      questionId: map['questionId'] ?? '',
      question: map['question'] ?? '',
      category: map['category'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      scores: List<int>.from(map['scores'] ?? []),
    );
  }
}

// MBTI 테스트 생성 도우미
class MBTITestHelper {
  // 샘플 MBTI 질문들
  static List<MBTIQuestion> getSampleQuestions() {
    return [
      // E/I 질문들
      MBTIQuestion(
        questionId: 'ei_1',
        question: '새로운 사람들과의 만남에 대해 어떻게 느끼시나요?',
        category: 'E_I',
        options: [
          '매우 어색하고 불편하다',
          '약간 불편하지만 적응할 수 있다',
          '보통이다',
          '편안하고 자연스럽다',
          '매우 즐겁고 에너지가 난다',
        ],
        scores: [-40, -20, 0, 20, 40],
      ),
      
      // S/N 질문들
      MBTIQuestion(
        questionId: 'sn_1',
        question: '문제를 해결할 때 어떤 방식을 선호하시나요?',
        category: 'S_N',
        options: [
          '구체적인 사실과 경험에 의존한다',
          '주로 경험을 바탕으로 하되 직감도 고려한다',
          '사실과 직감을 균형있게 사용한다',
          '직감을 주로 사용하되 사실도 확인한다',
          '직감과 가능성을 중시한다',
        ],
        scores: [-40, -20, 0, 20, 40],
      ),
      
      // T/F 질문들
      MBTIQuestion(
        questionId: 'tf_1',
        question: '중요한 결정을 내릴 때 무엇을 더 중시하시나요?',
        category: 'T_F',
        options: [
          '논리적 분석과 객관적 사실',
          '주로 논리를 따르되 감정도 고려한다',
          '논리와 감정을 균형있게 고려한다',
          '감정을 중시하되 논리도 확인한다',
          '사람들의 감정과 가치관',
        ],
        scores: [-40, -20, 0, 20, 40],
      ),
      
      // J/P 질문들
      MBTIQuestion(
        questionId: 'jp_1',
        question: '일정과 계획에 대한 당신의 태도는?',
        category: 'J_P',
        options: [
          '철저한 계획과 일정 준수가 필수다',
          '계획은 중요하지만 유연성도 필요하다',
          '상황에 따라 계획하거나 즉흥적으로 한다',
          '대략적인 계획만 세우고 상황에 맞춰 한다',
          '즉흥적이고 자유로운 것을 선호한다',
        ],
        scores: [-40, -20, 0, 20, 40],
      ),
    ];
  }

  // MBTI 테스트 결과 생성
  static MBTITestModel createTestResult({
    required String userId,
    required List<MBTIAnswer> answers,
  }) {
    final testId = 'mbti_${DateTime.now().millisecondsSinceEpoch}';
    
    // 점수 계산
    final scores = _calculateScores(answers);
    final result = scores.calculateMBTIType();
    
    // 메타데이터 생성
    final totalTimeSpent = answers.fold<int>(
      0, (sum, answer) => sum + answer.timeSpent);
    final accuracy = _calculateAccuracy(answers);
    
    final metadata = MBTITestMetadata(
      version: '1.0',
      totalQuestions: answers.length,
      totalTimeSpent: totalTimeSpent,
      accuracy: accuracy,
    );
    
    return MBTITestModel(
      testId: testId,
      userId: userId,
      result: result,
      completedAt: DateTime.now(),
      scores: scores,
      answers: answers,
      metadata: metadata,
    );
  }

  // 점수 계산 로직
  static MBTIScores _calculateScores(List<MBTIAnswer> answers) {
    final questions = getSampleQuestions();
    final questionMap = {for (var q in questions) q.questionId: q};
    
    double eI = 0, sN = 0, tF = 0, jP = 0;
    int eICount = 0, sNCount = 0, tFCount = 0, jPCount = 0;
    
    for (final answer in answers) {
      final question = questionMap[answer.questionId];
      if (question == null) continue;
      
      final scoreIndex = answer.answer - 1; // 1-5 -> 0-4
      if (scoreIndex < 0 || scoreIndex >= question.scores.length) continue;
      
      final score = question.scores[scoreIndex].toDouble();
      
      switch (question.category) {
        case 'E_I':
          eI += score;
          eICount++;
          break;
        case 'S_N':
          sN += score;
          sNCount++;
          break;
        case 'T_F':
          tF += score;
          tFCount++;
          break;
        case 'J_P':
          jP += score;
          jPCount++;
          break;
      }
    }
    
    // 평균 계산
    return MBTIScores(
      eI: eICount > 0 ? eI / eICount : 0,
      sN: sNCount > 0 ? sN / sNCount : 0,
      tF: tFCount > 0 ? tF / tFCount : 0,
      jP: jPCount > 0 ? jP / jPCount : 0,
    );
  }

  // 답변 일관성 계산
  static double _calculateAccuracy(List<MBTIAnswer> answers) {
    if (answers.length < 4) return 0.0;
    
    // 간단한 일관성 계산: 응답 시간과 답변 패턴 분석
    final avgTime = answers.fold<int>(0, (sum, a) => sum + a.timeSpent) / answers.length;
    final timeVariance = answers
        .map((a) => (a.timeSpent - avgTime).abs())
        .fold<double>(0, (sum, diff) => sum + diff) / answers.length;
    
    // 시간 일관성이 높을수록 정확도가 높다고 가정
    final timeScore = (100 - (timeVariance / avgTime * 100)).clamp(0.0, 100.0);
    
    return timeScore;
  }
}

