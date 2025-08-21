import 'package:typetalk/services/firestore_service.dart';

// 추천 알고리즘 요인 모델
class RecommendationFactors {
  final double mbtiCompatibility; // MBTI 호환성 (0-100)
  final double sharedInterests; // 공통 관심사 (0-100)
  final double activityLevel; // 활동성 (0-100)
  final double location; // 위치 근접성 (0-100)

  RecommendationFactors({
    required this.mbtiCompatibility,
    required this.sharedInterests,
    required this.activityLevel,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'mbtiCompatibility': mbtiCompatibility,
      'sharedInterests': sharedInterests,
      'activityLevel': activityLevel,
      'location': location,
    };
  }

  factory RecommendationFactors.fromMap(Map<String, dynamic> map) {
    return RecommendationFactors(
      mbtiCompatibility: (map['mbtiCompatibility'] ?? 0.0).toDouble(),
      sharedInterests: (map['sharedInterests'] ?? 0.0).toDouble(),
      activityLevel: (map['activityLevel'] ?? 0.0).toDouble(),
      location: (map['location'] ?? 0.0).toDouble(),
    );
  }

  // 총 점수 계산 (가중 평균)
  double calculateTotalScore() {
    return (mbtiCompatibility * 0.4) + 
           (sharedInterests * 0.3) + 
           (activityLevel * 0.2) + 
           (location * 0.1);
  }
}

// 추천 알고리즘 정보 모델
class RecommendationAlgorithm {
  final String version;
  final RecommendationFactors factors;

  RecommendationAlgorithm({
    required this.version,
    required this.factors,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'factors': factors.toMap(),
    };
  }

  factory RecommendationAlgorithm.fromMap(Map<String, dynamic> map) {
    return RecommendationAlgorithm(
      version: map['version'] ?? '1.0',
      factors: map['factors'] != null 
          ? RecommendationFactors.fromMap(map['factors']) 
          : RecommendationFactors(
              mbtiCompatibility: 0, 
              sharedInterests: 0, 
              activityLevel: 0, 
              location: 0),
    );
  }
}

// 메인 추천 모델
class RecommendationModel {
  final String recommendationId;
  final String userId; // 추천 받는 사용자
  final String type; // 'user' | 'chat'
  final String targetId; // 추천 대상 ID
  final double score; // 추천 점수 (0-100)
  final List<String> reasons; // 추천 이유들
  final DateTime createdAt;
  final DateTime? viewedAt; // 조회 시간
  final String? actionTaken; // 'accepted' | 'rejected' | 'ignored'
  final RecommendationAlgorithm algorithm;

  RecommendationModel({
    required this.recommendationId,
    required this.userId,
    required this.type,
    required this.targetId,
    required this.score,
    required this.reasons,
    required this.createdAt,
    this.viewedAt,
    this.actionTaken,
    required this.algorithm,
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'recommendationId': recommendationId,
      'userId': userId,
      'type': type,
      'targetId': targetId,
      'score': score,
      'reasons': reasons,
      'createdAt': createdAt,
      'viewedAt': viewedAt,
      'actionTaken': actionTaken,
      'algorithm': algorithm.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory RecommendationModel.fromMap(Map<String, dynamic> map) {
    return RecommendationModel(
      recommendationId: map['recommendationId'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'user',
      targetId: map['targetId'] ?? '',
      score: (map['score'] ?? 0.0).toDouble(),
      reasons: List<String>.from(map['reasons'] ?? []),
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(),
      viewedAt: map['viewedAt'] is DateTime 
          ? map['viewedAt'] 
          : null,
      actionTaken: map['actionTaken'],
      algorithm: map['algorithm'] != null 
          ? RecommendationAlgorithm.fromMap(map['algorithm']) 
          : RecommendationAlgorithm(
              version: '1.0', 
              factors: RecommendationFactors(
                mbtiCompatibility: 0, 
                sharedInterests: 0, 
                activityLevel: 0, 
                location: 0)),
    );
  }

  // Firestore 문서 스냅샷에서 생성
  factory RecommendationModel.fromSnapshot(dynamic snapshot) {
    if (!snapshot.exists) {
      throw Exception('추천 문서가 존재하지 않습니다.');
    }
    return RecommendationModel.fromMap(snapshot.data);
  }

  // 추천 업데이트
  RecommendationModel copyWith({
    String? recommendationId,
    String? userId,
    String? type,
    String? targetId,
    double? score,
    List<String>? reasons,
    DateTime? createdAt,
    DateTime? viewedAt,
    String? actionTaken,
    RecommendationAlgorithm? algorithm,
  }) {
    return RecommendationModel(
      recommendationId: recommendationId ?? this.recommendationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      score: score ?? this.score,
      reasons: reasons ?? this.reasons,
      createdAt: createdAt ?? this.createdAt,
      viewedAt: viewedAt ?? this.viewedAt,
      actionTaken: actionTaken ?? this.actionTaken,
      algorithm: algorithm ?? this.algorithm,
    );
  }

  // 조회 표시
  RecommendationModel markAsViewed() {
    return copyWith(viewedAt: DateTime.now());
  }

  // 수락 표시
  RecommendationModel accept() {
    return copyWith(
      actionTaken: 'accepted',
      viewedAt: viewedAt ?? DateTime.now(),
    );
  }

  // 거절 표시
  RecommendationModel reject() {
    return copyWith(
      actionTaken: 'rejected',
      viewedAt: viewedAt ?? DateTime.now(),
    );
  }

  // 무시 표시
  RecommendationModel ignore() {
    return copyWith(
      actionTaken: 'ignored',
      viewedAt: viewedAt ?? DateTime.now(),
    );
  }

  // 사용자 추천인지 확인
  bool get isUserRecommendation => type == 'user';

  // 채팅방 추천인지 확인
  bool get isChatRecommendation => type == 'chat';

  // 조회되었는지 확인
  bool get isViewed => viewedAt != null;

  // 액션이 취해졌는지 확인
  bool get hasActionTaken => actionTaken != null;

  // 수락되었는지 확인
  bool get isAccepted => actionTaken == 'accepted';

  // 거절되었는지 확인
  bool get isRejected => actionTaken == 'rejected';

  // 무시되었는지 확인
  bool get isIgnored => actionTaken == 'ignored';

  // 높은 점수인지 확인 (80점 이상)
  bool get isHighScore => score >= 80.0;

  // 중간 점수인지 확인 (50-80점)
  bool get isMediumScore => score >= 50.0 && score < 80.0;

  // 낮은 점수인지 확인 (50점 미만)
  bool get isLowScore => score < 50.0;

  @override
  String toString() {
    return 'RecommendationModel(id: $recommendationId, type: $type, targetId: $targetId, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendationModel && 
           other.recommendationId == recommendationId;
  }

  @override
  int get hashCode => recommendationId.hashCode;
}

// 추천 생성 도우미 클래스
class RecommendationHelper {
  // 사용자 추천 생성
  static RecommendationModel createUserRecommendation({
    required String userId,
    required String targetUserId,
    required String userMBTI,
    required String targetMBTI,
    List<String>? sharedInterests,
    double? locationScore,
    double? activityScore,
  }) {
    final recommendationId = 'rec_user_${DateTime.now().millisecondsSinceEpoch}';
    
    // MBTI 호환성 계산
    final mbtiCompatibility = _calculateMBTICompatibility(userMBTI, targetMBTI);
    
    // 공통 관심사 점수
    final sharedInterestScore = _calculateSharedInterestScore(sharedInterests ?? []);
    
    // 추천 요인들
    final factors = RecommendationFactors(
      mbtiCompatibility: mbtiCompatibility,
      sharedInterests: sharedInterestScore,
      activityLevel: activityScore ?? 50.0,
      location: locationScore ?? 50.0,
    );
    
    // 총 점수 계산
    final totalScore = factors.calculateTotalScore();
    
    // 추천 이유 생성
    final reasons = _generateUserRecommendationReasons(
      mbtiCompatibility, sharedInterestScore, userMBTI, targetMBTI);
    
    return RecommendationModel(
      recommendationId: recommendationId,
      userId: userId,
      type: 'user',
      targetId: targetUserId,
      score: totalScore,
      reasons: reasons,
      createdAt: DateTime.now(),
      algorithm: RecommendationAlgorithm(version: '1.0', factors: factors),
    );
  }

  // 채팅방 추천 생성
  static RecommendationModel createChatRecommendation({
    required String userId,
    required String chatId,
    required String userMBTI,
    required List<String> chatTargetMBTI,
    required String chatTitle,
    int? participantCount,
    bool? isActive,
  }) {
    final recommendationId = 'rec_chat_${DateTime.now().millisecondsSinceEpoch}';
    
    // MBTI 호환성 계산 (채팅방 대상 MBTI와의 평균 호환성)
    final mbtiCompatibility = _calculateChatMBTICompatibility(userMBTI, chatTargetMBTI);
    
    // 활동성 점수 (참여자 수와 활성도 기반)
    final activityScore = _calculateChatActivityScore(participantCount ?? 0, isActive ?? true);
    
    // 추천 요인들
    final factors = RecommendationFactors(
      mbtiCompatibility: mbtiCompatibility,
      sharedInterests: 70.0, // 채팅방은 MBTI 기반이므로 기본적으로 높은 관심사 점수
      activityLevel: activityScore,
      location: 100.0, // 온라인 채팅방이므로 위치는 최대 점수
    );
    
    // 총 점수 계산
    final totalScore = factors.calculateTotalScore();
    
    // 추천 이유 생성
    final reasons = _generateChatRecommendationReasons(
      mbtiCompatibility, chatTitle, userMBTI, chatTargetMBTI);
    
    return RecommendationModel(
      recommendationId: recommendationId,
      userId: userId,
      type: 'chat',
      targetId: chatId,
      score: totalScore,
      reasons: reasons,
      createdAt: DateTime.now(),
      algorithm: RecommendationAlgorithm(version: '1.0', factors: factors),
    );
  }

  // MBTI 호환성 계산
  static double _calculateMBTICompatibility(String mbti1, String mbti2) {
    if (mbti1.length != 4 || mbti2.length != 4) return 50.0;
    
    double score = 0.0;
    
    // E/I 호환성 (반대가 더 호환)
    score += mbti1[0] != mbti2[0] ? 25.0 : 15.0;
    
    // S/N 호환성 (같은 것이 더 호환)
    score += mbti1[1] == mbti2[1] ? 35.0 : 10.0;
    
    // T/F 호환성 (같은 것이 약간 더 호환)
    score += mbti1[2] == mbti2[2] ? 20.0 : 15.0;
    
    // J/P 호환성 (반대가 더 호환)
    score += mbti1[3] != mbti2[3] ? 25.0 : 15.0;
    
    return score.clamp(0.0, 100.0);
  }

  // 채팅방 MBTI 호환성 계산
  static double _calculateChatMBTICompatibility(String userMBTI, List<String> chatMBTI) {
    if (chatMBTI.isEmpty) return 50.0;
    
    double totalScore = 0.0;
    for (final targetMBTI in chatMBTI) {
      totalScore += _calculateMBTICompatibility(userMBTI, targetMBTI);
    }
    
    return totalScore / chatMBTI.length;
  }

  // 공통 관심사 점수 계산
  static double _calculateSharedInterestScore(List<String> sharedInterests) {
    // 공통 관심사 개수에 따른 점수
    switch (sharedInterests.length) {
      case 0: return 0.0;
      case 1: return 30.0;
      case 2: return 60.0;
      case 3: return 80.0;
      default: return 100.0;
    }
  }

  // 채팅방 활동성 점수 계산
  static double _calculateChatActivityScore(int participantCount, bool isActive) {
    double score = 0.0;
    
    // 참여자 수 기반 점수 (적당한 인원이 좋음)
    if (participantCount <= 2) {
      score += 20.0;
    } else if (participantCount <= 5) {
      score += 80.0;
    } else if (participantCount <= 10) {
      score += 60.0;
    } else {
      score += 30.0;
    }
    
    // 활성도 기반 점수
    score += isActive ? 20.0 : 0.0;
    
    return score.clamp(0.0, 100.0);
  }

  // 사용자 추천 이유 생성
  static List<String> _generateUserRecommendationReasons(
    double mbtiScore, double interestScore, String userMBTI, String targetMBTI) {
    final reasons = <String>[];
    
    if (mbtiScore >= 80) {
      reasons.add('MBTI 성격이 매우 잘 맞습니다 ($userMBTI ↔ $targetMBTI)');
    } else if (mbtiScore >= 60) {
      reasons.add('MBTI 성격이 잘 맞습니다 ($userMBTI ↔ $targetMBTI)');
    }
    
    if (interestScore >= 60) {
      reasons.add('공통 관심사가 많습니다');
    }
    
    if (reasons.isEmpty) {
      reasons.add('새로운 인연을 만나보세요');
    }
    
    return reasons;
  }

  // 채팅방 추천 이유 생성
  static List<String> _generateChatRecommendationReasons(
    double mbtiScore, String chatTitle, String userMBTI, List<String> targetMBTI) {
    final reasons = <String>[];
    
    if (mbtiScore >= 80) {
      reasons.add('당신의 MBTI($userMBTI)와 매우 잘 맞는 채팅방입니다');
    } else if (mbtiScore >= 60) {
      reasons.add('당신의 MBTI($userMBTI)와 잘 맞는 채팅방입니다');
    }
    
    if (targetMBTI.isNotEmpty) {
      reasons.add('${targetMBTI.join(', ')} 타입들과 대화해보세요');
    }
    
    reasons.add('활발한 채팅방입니다');
    
    return reasons;
  }
}

