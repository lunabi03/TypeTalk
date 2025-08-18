import 'package:get/get.dart';
import 'package:typetalk/models/recommendation_model.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/services/user_repository.dart';
import 'package:typetalk/services/firestore_service.dart';

/// 추천 알고리즘 서비스
/// MBTI 기반 사용자 및 채팅방 추천을 담당합니다.
class RecommendationService extends GetxService {
  static RecommendationService get instance => Get.find<RecommendationService>();

  final UserRepository _userRepository = Get.find<UserRepository>();
  final DemoFirestoreService _firestore = Get.find<DemoFirestoreService>();
  
  static const String _collectionName = 'recommendations';

  /// MBTI 호환성 매트릭스
  /// 각 MBTI 유형별 호환성 점수를 정의합니다.
  static const Map<String, Map<String, double>> _mbtiCompatibilityMatrix = {
    'ENFP': {
      'INTJ': 95.0, 'INFJ': 90.0, 'ENFJ': 85.0, 'ENTP': 80.0,
      'ENFP': 75.0, 'INFP': 85.0, 'INTP': 80.0, 'ENTJ': 75.0,
      'ISFJ': 70.0, 'ESFJ': 70.0, 'ISFP': 75.0, 'ESFP': 80.0,
      'ISTJ': 60.0, 'ESTJ': 60.0, 'ISTP': 65.0, 'ESTP': 70.0,
    },
    'INTJ': {
      'ENFP': 95.0, 'ENTP': 90.0, 'INFJ': 85.0, 'ENFJ': 80.0,
      'ENTJ': 85.0, 'INTJ': 75.0, 'INTP': 80.0, 'INFP': 75.0,
      'ISFJ': 65.0, 'ESFJ': 60.0, 'ISFP': 70.0, 'ESFP': 65.0,
      'ISTJ': 75.0, 'ESTJ': 70.0, 'ISTP': 75.0, 'ESTP': 60.0,
    },
    'INFJ': {
      'ENFP': 90.0, 'ENTP': 85.0, 'INFP': 90.0, 'ENFJ': 80.0,
      'INTJ': 85.0, 'ENTJ': 75.0, 'INTP': 80.0, 'INFJ': 75.0,
      'ISFJ': 75.0, 'ESFJ': 70.0, 'ISFP': 85.0, 'ESFP': 70.0,
      'ISTJ': 70.0, 'ESTJ': 65.0, 'ISTP': 75.0, 'ESTP': 60.0,
    },
    'ENFJ': {
      'INFP': 95.0, 'ISFP': 90.0, 'ENFP': 85.0, 'INFJ': 80.0,
      'ENFJ': 75.0, 'ENTJ': 80.0, 'INTJ': 80.0, 'INTP': 75.0,
      'ISFJ': 85.0, 'ESFJ': 80.0, 'ESFP': 85.0, 'ENTP': 75.0,
      'ISTJ': 70.0, 'ESTJ': 75.0, 'ISTP': 65.0, 'ESTP': 70.0,
    },
    'ENTP': {
      'INTJ': 90.0, 'INFJ': 85.0, 'ENFJ': 75.0, 'INTP': 85.0,
      'ENTP': 80.0, 'ENFP': 80.0, 'ENTJ': 80.0, 'INFP': 75.0,
      'ISFJ': 65.0, 'ESFJ': 65.0, 'ISFP': 70.0, 'ESFP': 75.0,
      'ISTJ': 60.0, 'ESTJ': 65.0, 'ISTP': 70.0, 'ESTP': 75.0,
    },
    'INFP': {
      'ENFJ': 95.0, 'INFJ': 90.0, 'ENFP': 85.0, 'ISFP': 85.0,
      'INFP': 80.0, 'ENTJ': 75.0, 'INTJ': 75.0, 'ENTP': 75.0,
      'ISFJ': 80.0, 'ESFJ': 75.0, 'ESFP': 80.0, 'INTP': 80.0,
      'ISTJ': 70.0, 'ESTJ': 65.0, 'ISTP': 75.0, 'ESTP': 65.0,
    },
    'INTP': {
      'ENTJ': 90.0, 'ENTP': 85.0, 'INTJ': 80.0, 'INFJ': 80.0,
      'INTP': 85.0, 'ENFP': 80.0, 'INFP': 80.0, 'ENFJ': 75.0,
      'ISFJ': 65.0, 'ESFJ': 60.0, 'ISFP': 75.0, 'ESFP': 65.0,
      'ISTJ': 70.0, 'ESTJ': 65.0, 'ISTP': 80.0, 'ESTP': 70.0,
    },
    'ENTJ': {
      'INTP': 90.0, 'INFP': 75.0, 'INTJ': 85.0, 'ENTP': 80.0,
      'ENTJ': 80.0, 'ENFP': 75.0, 'INFJ': 75.0, 'ENFJ': 80.0,
      'ISFJ': 70.0, 'ESFJ': 75.0, 'ISFP': 70.0, 'ESFP': 70.0,
      'ISTJ': 80.0, 'ESTJ': 85.0, 'ISTP': 75.0, 'ESTP': 80.0,
    },
    'ISFJ': {
      'ESFP': 90.0, 'ENFP': 70.0, 'ENFJ': 85.0, 'INFP': 80.0,
      'ISFJ': 80.0, 'ESFJ': 85.0, 'ISFP': 80.0, 'INFJ': 75.0,
      'ISTJ': 85.0, 'ESTJ': 80.0, 'ISTP': 70.0, 'ESTP': 75.0,
      'INTJ': 65.0, 'ENTJ': 70.0, 'INTP': 65.0, 'ENTP': 65.0,
    },
    'ESFJ': {
      'ISFP': 90.0, 'INFP': 75.0, 'ENFJ': 80.0, 'ISFJ': 85.0,
      'ESFJ': 85.0, 'ESFP': 80.0, 'ENFP': 70.0, 'INFJ': 70.0,
      'ISTJ': 80.0, 'ESTJ': 85.0, 'ISTP': 70.0, 'ESTP': 80.0,
      'INTJ': 60.0, 'ENTJ': 75.0, 'INTP': 60.0, 'ENTP': 65.0,
    },
    'ISFP': {
      'ENFJ': 90.0, 'ESFJ': 90.0, 'ISFJ': 80.0, 'INFP': 85.0,
      'ISFP': 80.0, 'ESFP': 85.0, 'ENFP': 75.0, 'INFJ': 85.0,
      'ISTJ': 75.0, 'ESTJ': 70.0, 'ISTP': 80.0, 'ESTP': 75.0,
      'INTJ': 70.0, 'ENTJ': 70.0, 'INTP': 75.0, 'ENTP': 70.0,
    },
    'ESFP': {
      'ISFJ': 90.0, 'ISTJ': 75.0, 'ESFJ': 80.0, 'ISFP': 85.0,
      'ESFP': 80.0, 'ENFP': 80.0, 'INFP': 80.0, 'ENFJ': 85.0,
      'ESTJ': 75.0, 'ISTP': 75.0, 'ESTP': 85.0, 'INFJ': 70.0,
      'INTJ': 65.0, 'ENTJ': 70.0, 'INTP': 65.0, 'ENTP': 75.0,
    },
    'ISTJ': {
      'ESFP': 75.0, 'ESTP': 70.0, 'ISFJ': 85.0, 'ESFJ': 80.0,
      'ISTJ': 85.0, 'ESTJ': 80.0, 'ISFP': 75.0, 'ISTP': 75.0,
      'INTJ': 75.0, 'ENTJ': 80.0, 'INFJ': 70.0, 'ENFJ': 70.0,
      'INTP': 70.0, 'ENTP': 60.0, 'INFP': 70.0, 'ENFP': 60.0,
    },
    'ESTJ': {
      'ISFP': 70.0, 'ISTP': 70.0, 'ISFJ': 80.0, 'ESFJ': 85.0,
      'ISTJ': 80.0, 'ESTJ': 80.0, 'ESFP': 75.0, 'ESTP': 80.0,
      'INTJ': 70.0, 'ENTJ': 85.0, 'INFJ': 65.0, 'ENFJ': 75.0,
      'INTP': 65.0, 'ENTP': 65.0, 'INFP': 65.0, 'ENFP': 60.0,
    },
    'ISTP': {
      'ESFJ': 70.0, 'ESTJ': 70.0, 'ESFP': 75.0, 'ESTP': 80.0,
      'ISTP': 80.0, 'ISFP': 80.0, 'ISTJ': 75.0, 'ISFJ': 70.0,
      'INTJ': 75.0, 'ENTJ': 75.0, 'INTP': 80.0, 'ENTP': 70.0,
      'INFJ': 75.0, 'ENFJ': 65.0, 'INFP': 75.0, 'ENFP': 65.0,
    },
    'ESTP': {
      'ISFJ': 75.0, 'ISTJ': 70.0, 'ESFJ': 80.0, 'ESTJ': 80.0,
      'ISTP': 80.0, 'ESFP': 85.0, 'ISFP': 75.0, 'ESTP': 80.0,
      'ENTJ': 80.0, 'ENTP': 75.0, 'INTJ': 60.0, 'INTP': 70.0,
      'ENFJ': 70.0, 'INFJ': 60.0, 'ENFP': 70.0, 'INFP': 65.0,
    },
  };

  /// 사용자별 추천 생성
  Future<List<RecommendationModel>> generateUserRecommendations(String userId) async {
    try {
      print('사용자 추천 생성 시작: $userId');
      
      // 현재 사용자 정보 조회
      final currentUser = await _userRepository.getUser(userId);
      if (currentUser == null || currentUser.mbtiType == null) {
        print('사용자 정보 또는 MBTI 정보가 없습니다: $userId');
        return [];
      }

      // 모든 사용자 조회 (본인 제외)
      final allUsers = await _userRepository.getRecentUsers(limit: 100);
      final otherUsers = allUsers.where((user) => 
        user.uid != userId && user.mbtiType != null).toList();

      if (otherUsers.isEmpty) {
        print('추천할 다른 사용자가 없습니다.');
        return [];
      }

      // 각 사용자에 대한 추천 생성
      final recommendations = <RecommendationModel>[];
      for (final targetUser in otherUsers) {
        final recommendation = RecommendationHelper.createUserRecommendation(
          userId: userId,
          targetUserId: targetUser.uid,
          userMBTI: currentUser.mbtiType!,
          targetMBTI: targetUser.mbtiType!,
          sharedInterests: _findSharedInterests(currentUser, targetUser),
          locationScore: _calculateLocationScore(currentUser, targetUser),
          activityScore: _calculateActivityScore(targetUser),
        );

        // 최소 점수 이상인 경우에만 추천
        if (recommendation.score >= 30.0) {
          recommendations.add(recommendation);
        }
      }

      // 점수순으로 정렬하여 상위 10개만 반환
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      final topRecommendations = recommendations.take(10).toList();

      print('생성된 사용자 추천 수: ${topRecommendations.length}');
      return topRecommendations;
    } catch (e) {
      print('사용자 추천 생성 오류: $e');
      return [];
    }
  }

  /// 채팅방별 추천 생성
  Future<List<RecommendationModel>> generateChatRecommendations(String userId) async {
    try {
      print('채팅방 추천 생성 시작: $userId');
      
      // 현재 사용자 정보 조회
      final currentUser = await _userRepository.getUser(userId);
      if (currentUser == null || currentUser.mbtiType == null) {
        print('사용자 정보 또는 MBTI 정보가 없습니다: $userId');
        return [];
      }

      // 모든 채팅방 조회
      final allChats = await _getAllChats();
      if (allChats.isEmpty) {
        print('추천할 채팅방이 없습니다.');
        return [];
      }

      // 각 채팅방에 대한 추천 생성
      final recommendations = <RecommendationModel>[];
      for (final chat in allChats) {
        // 이미 참여 중인 채팅방은 제외
        if (chat.participants.contains(userId)) continue;

        final recommendation = RecommendationHelper.createChatRecommendation(
          userId: userId,
          chatId: chat.chatId,
          userMBTI: currentUser.mbtiType!,
          chatTargetMBTI: chat.targetMBTI ?? [],
          chatTitle: chat.title,
          participantCount: chat.participantCount,
          isActive: _isChatActive(chat),
        );

        // 최소 점수 이상인 경우에만 추천
        if (recommendation.score >= 40.0) {
          recommendations.add(recommendation);
        }
      }

      // 점수순으로 정렬하여 상위 5개만 반환
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      final topRecommendations = recommendations.take(5).toList();

      print('생성된 채팅방 추천 수: ${topRecommendations.length}');
      return topRecommendations;
    } catch (e) {
      print('채팅방 추천 생성 오류: $e');
      return [];
    }
  }

  /// 추천 저장
  Future<void> saveRecommendation(RecommendationModel recommendation) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(recommendation.recommendationId)
          .set(recommendation.toMap());
      
      print('추천 저장 완료: ${recommendation.recommendationId}');
    } catch (e) {
      print('추천 저장 실패: $e');
      throw Exception('추천 저장 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 사용자의 추천 목록 조회
  Future<List<RecommendationModel>> getUserRecommendations(String userId, {
    String? type,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      query = query.limit(limit);

      final snapshots = await query.get();
      return snapshots
          .map((snapshot) => RecommendationModel.fromSnapshot(snapshot))
          .toList();
    } catch (e) {
      print('추천 조회 실패: $e');
      throw Exception('추천 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 추천 업데이트 (조회, 수락, 거절 등)
  Future<void> updateRecommendation(RecommendationModel recommendation) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(recommendation.recommendationId)
          .update(recommendation.toMap());
      
      print('추천 업데이트 완료: ${recommendation.recommendationId}');
    } catch (e) {
      print('추천 업데이트 실패: $e');
      throw Exception('추천 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 추천 조회 표시
  Future<void> markRecommendationAsViewed(String recommendationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(recommendationId)
          .update({
            'viewedAt': DateTime.now(),
          });
      
      print('추천 조회 표시 완료: $recommendationId');
    } catch (e) {
      print('추천 조회 표시 실패: $e');
    }
  }

  /// 추천 수락
  Future<void> acceptRecommendation(String recommendationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(recommendationId)
          .update({
            'actionTaken': 'accepted',
            'viewedAt': DateTime.now(),
          });
      
      print('추천 수락 완료: $recommendationId');
    } catch (e) {
      print('추천 수락 실패: $e');
      throw Exception('추천 수락 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 추천 거절
  Future<void> rejectRecommendation(String recommendationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(recommendationId)
          .update({
            'actionTaken': 'rejected',
            'viewedAt': DateTime.now(),
          });
      
      print('추천 거절 완료: $recommendationId');
    } catch (e) {
      print('추천 거절 실패: $e');
      throw Exception('추천 거절 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 전체 추천 생성 및 저장
  Future<void> generateAndSaveRecommendations(String userId) async {
    try {
      print('전체 추천 생성 시작: $userId');
      
      // 사용자 추천 생성
      final userRecommendations = await generateUserRecommendations(userId);
      for (final recommendation in userRecommendations) {
        await saveRecommendation(recommendation);
      }

      // 채팅방 추천 생성
      final chatRecommendations = await generateChatRecommendations(userId);
      for (final recommendation in chatRecommendations) {
        await saveRecommendation(recommendation);
      }

      print('전체 추천 생성 완료: 사용자 ${userRecommendations.length}개, 채팅방 ${chatRecommendations.length}개');
    } catch (e) {
      print('전체 추천 생성 실패: $e');
      throw Exception('추천 생성 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// MBTI 호환성 점수 조회
  double getMBTICompatibilityScore(String mbti1, String mbti2) {
    final matrix = _mbtiCompatibilityMatrix[mbti1];
    if (matrix == null) return 50.0;
    return matrix[mbti2] ?? 50.0;
  }

  /// 공통 관심사 찾기
  List<String> _findSharedInterests(UserModel user1, UserModel user2) {
    // 실제 구현에서는 사용자의 관심사 데이터를 기반으로 계산
    // 현재는 더미 데이터 반환
    final interests = <String>[];
    
    // MBTI가 비슷하면 공통 관심사가 있다고 가정
    if (user1.mbtiType?.substring(1, 3) == user2.mbtiType?.substring(1, 3)) {
      interests.add('성격 유형 분석');
    }
    
    return interests;
  }

  /// 위치 점수 계산
  double _calculateLocationScore(UserModel user1, UserModel user2) {
    // 실제 구현에서는 GPS 좌표나 지역 정보를 기반으로 계산
    // 현재는 더미 점수 반환
    return 75.0;
  }

  /// 활동성 점수 계산
  double _calculateActivityScore(UserModel user) {
    final stats = user.stats;
    double score = 0.0;
    
    // 채팅 수 기반 점수
    if (stats.chatCount > 10) {
      score += 40.0;
    } else if (stats.chatCount > 5) {
      score += 30.0;
    } else {
      score += 20.0;
    }
    
    // 최근 로그인 기반 점수
    final daysSinceLogin = DateTime.now().difference(stats.lastLoginAt).inDays;
    if (daysSinceLogin <= 1) {
      score += 40.0;
    } else if (daysSinceLogin <= 7) {
      score += 30.0;
    } else {
      score += 10.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// 모든 채팅방 조회
  Future<List<ChatModel>> _getAllChats() async {
    try {
      final snapshots = await _firestore
          .collection('chats')
          .orderBy('updatedAt', descending: true)
          .get();
      
      return snapshots
          .map((snapshot) => ChatModel.fromSnapshot(snapshot))
          .toList();
    } catch (e) {
      print('채팅방 조회 오류: $e');
      return [];
    }
  }

  /// 채팅방 활성도 확인
  bool _isChatActive(ChatModel chat) {
    final hoursSinceLastActivity = DateTime.now()
        .difference(chat.stats?.lastActivity ?? chat.updatedAt)
        .inHours;
    
    return hoursSinceLastActivity <= 24; // 24시간 이내 활동이 있으면 활성
  }

  /// 추천 통계 조회
  Future<Map<String, dynamic>> getRecommendationStats(String userId) async {
    try {
      final recommendations = await getUserRecommendations(userId);
      
      final stats = {
        'total': recommendations.length,
        'userRecommendations': recommendations.where((r) => r.type == 'user').length,
        'chatRecommendations': recommendations.where((r) => r.type == 'chat').length,
        'viewedCount': recommendations.where((r) => r.isViewed).length,
        'acceptedCount': recommendations.where((r) => r.isAccepted).length,
        'rejectedCount': recommendations.where((r) => r.isRejected).length,
        'averageScore': recommendations.isEmpty 
            ? 0.0 
            : recommendations.map((r) => r.score).reduce((a, b) => a + b) / recommendations.length,
      };
      
      return stats;
    } catch (e) {
      print('추천 통계 조회 오류: $e');
      return {};
    }
  }

  /// 오래된 추천 정리
  Future<void> cleanupOldRecommendations({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final oldRecommendations = await _firestore
          .collection(_collectionName)
          .where('createdAt', isLessThan: cutoffDate)
          .get();
      
      for (final recommendation in oldRecommendations) {
        await _firestore
            .collection(_collectionName)
            .doc(recommendation.id)
            .delete();
      }
      
      print('오래된 추천 정리 완료: ${oldRecommendations.length}개');
    } catch (e) {
      print('추천 정리 오류: $e');
    }
  }
}
