import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/services/recommendation_service.dart';
import 'package:typetalk/models/recommendation_model.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/services/real_user_repository.dart';

/// 추천 및 매칭 관리 컨트롤러
/// 사용자 추천, 채팅방 추천, 매칭 기능을 담당합니다.
class RecommendationController extends GetxController {
  static RecommendationController get instance => Get.find<RecommendationController>();

  final AuthController _authController = Get.find<AuthController>();
  final RecommendationService _recommendationService = Get.find<RecommendationService>();
  final RealUserRepository _userRepository = Get.find<RealUserRepository>();

  // 추천 데이터
  RxList<RecommendationModel> userRecommendations = <RecommendationModel>[].obs;
  RxList<RecommendationModel> chatRecommendations = <RecommendationModel>[].obs;
  RxList<RecommendationModel> allRecommendations = <RecommendationModel>[].obs;

  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isGenerating = false.obs;
  RxBool isRefreshing = false.obs;

  // 필터 및 정렬
  RxString selectedType = 'all'.obs; // 'all', 'user', 'chat'
  RxString sortBy = 'score'.obs; // 'score', 'date', 'compatibility'
  RxBool showOnlyUnviewed = false.obs;

  // 추천 통계
  RxMap<String, dynamic> recommendationStats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecommendations();
    _loadRecommendationStats();
  }

  /// 추천 목록 로드
  Future<void> _loadRecommendations() async {
    try {
      isLoading.value = true;
      
      final userId = _authController.userId;
      if (userId == null) {
        print('로그인된 사용자가 없습니다.');
        return;
      }

      // 모든 추천 조회
      final recommendations = await _recommendationService.getUserRecommendations(userId);
      allRecommendations.assignAll(recommendations);

      // 타입별로 분류
      userRecommendations.assignAll(
        recommendations.where((r) => r.type == 'user').toList()
      );
      chatRecommendations.assignAll(
        recommendations.where((r) => r.type == 'chat').toList()
      );

      print('추천 로드 완료: ${recommendations.length}개');
    } catch (e) {
      print('추천 로드 오류: $e');
      Get.snackbar(
        '오류',
        '추천 목록을 불러오는 중 오류가 발생했습니다.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 추천 통계 로드
  Future<void> _loadRecommendationStats() async {
    try {
      final userId = _authController.userId;
      if (userId == null) return;

      final stats = await _recommendationService.getRecommendationStats(userId);
      recommendationStats.assignAll(stats);
    } catch (e) {
      print('추천 통계 로드 오류: $e');
    }
  }

  /// 새로운 추천 생성
  Future<void> generateNewRecommendations() async {
    try {
      isGenerating.value = true;
      
      final userId = _authController.userId;
      if (userId == null) {
        Get.snackbar('오류', '로그인이 필요합니다.');
        return;
      }

      // 새로운 추천 생성 및 저장
      await _recommendationService.generateAndSaveRecommendations(userId);

      // 추천 목록 새로고침
      await _loadRecommendations();
      await _loadRecommendationStats();

      Get.snackbar(
        '완료',
        '새로운 추천이 생성되었습니다!',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      print('추천 생성 오류: $e');
      Get.snackbar(
        '오류',
        '추천 생성 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isGenerating.value = false;
    }
  }

  /// 추천 새로고침
  Future<void> refreshRecommendations() async {
    try {
      isRefreshing.value = true;
      await _loadRecommendations();
      await _loadRecommendationStats();
    } catch (e) {
      print('추천 새로고침 오류: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  /// 추천 조회 표시
  Future<void> markRecommendationAsViewed(String recommendationId) async {
    try {
      await _recommendationService.markRecommendationAsViewed(recommendationId);
      
      // 로컬 상태 업데이트
      _updateLocalRecommendation(recommendationId, (rec) => rec.markAsViewed());
    } catch (e) {
      print('추천 조회 표시 오류: $e');
    }
  }

  /// 추천 수락
  Future<void> acceptRecommendation(String recommendationId) async {
    try {
      await _recommendationService.acceptRecommendation(recommendationId);
      
      // 로컬 상태 업데이트
      _updateLocalRecommendation(recommendationId, (rec) => rec.accept());

      Get.snackbar(
        '수락',
        '추천을 수락했습니다!',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      // 통계 새로고침
      await _loadRecommendationStats();
    } catch (e) {
      print('추천 수락 오류: $e');
      Get.snackbar(
        '오류',
        '추천 수락 중 오류가 발생했습니다.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  /// 추천 거절
  Future<void> rejectRecommendation(String recommendationId) async {
    try {
      await _recommendationService.rejectRecommendation(recommendationId);
      
      // 로컬 상태 업데이트
      _updateLocalRecommendation(recommendationId, (rec) => rec.reject());

      Get.snackbar(
        '거절',
        '추천을 거절했습니다.',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
      );

      // 통계 새로고침
      await _loadRecommendationStats();
    } catch (e) {
      print('추천 거절 오류: $e');
      Get.snackbar(
        '오류',
        '추천 거절 중 오류가 발생했습니다.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  /// 로컬 추천 상태 업데이트
  void _updateLocalRecommendation(String recommendationId, 
      RecommendationModel Function(RecommendationModel) updateFunction) {
    
    // 전체 목록에서 업데이트
    final allIndex = allRecommendations.indexWhere((r) => r.recommendationId == recommendationId);
    if (allIndex != -1) {
      allRecommendations[allIndex] = updateFunction(allRecommendations[allIndex]);
    }

    // 사용자 추천 목록에서 업데이트
    final userIndex = userRecommendations.indexWhere((r) => r.recommendationId == recommendationId);
    if (userIndex != -1) {
      userRecommendations[userIndex] = updateFunction(userRecommendations[userIndex]);
    }

    // 채팅방 추천 목록에서 업데이트
    final chatIndex = chatRecommendations.indexWhere((r) => r.recommendationId == recommendationId);
    if (chatIndex != -1) {
      chatRecommendations[chatIndex] = updateFunction(chatRecommendations[chatIndex]);
    }
  }

  /// 필터링된 추천 목록 반환
  List<RecommendationModel> get filteredRecommendations {
    List<RecommendationModel> recommendations;
    
    // 타입별 필터링
    switch (selectedType.value) {
      case 'user':
        recommendations = userRecommendations.toList();
        break;
      case 'chat':
        recommendations = chatRecommendations.toList();
        break;
      default:
        recommendations = allRecommendations.toList();
    }

    // 조회 여부 필터링
    if (showOnlyUnviewed.value) {
      recommendations = recommendations.where((r) => !r.isViewed).toList();
    }

    // 정렬
    switch (sortBy.value) {
      case 'score':
        recommendations.sort((a, b) => b.score.compareTo(a.score));
        break;
      case 'date':
        recommendations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'compatibility':
        recommendations.sort((a, b) => 
          b.algorithm.factors.mbtiCompatibility.compareTo(a.algorithm.factors.mbtiCompatibility));
        break;
    }

    return recommendations;
  }

  /// 추천 타입 변경
  void changeRecommendationType(String type) {
    selectedType.value = type;
  }

  /// 정렬 방식 변경
  void changeSortBy(String sort) {
    sortBy.value = sort;
  }

  /// 조회하지 않은 추천만 보기 토글
  void toggleShowOnlyUnviewed() {
    showOnlyUnviewed.value = !showOnlyUnviewed.value;
  }

  /// 특정 사용자 정보 조회
  Future<UserModel?> getUserInfo(String userId) async {
    try {
      return await _userRepository.getUser(userId);
    } catch (e) {
      print('사용자 정보 조회 오류: $e');
      return null;
    }
  }

  /// MBTI 호환성 점수 조회
  double getMBTICompatibilityScore(String mbti1, String mbti2) {
    return _recommendationService.getMBTICompatibilityScore(mbti1, mbti2);
  }

  /// 추천 상세 정보 표시
  void showRecommendationDetails(RecommendationModel recommendation) {
    // 조회 표시
    if (!recommendation.isViewed) {
      markRecommendationAsViewed(recommendation.recommendationId);
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  recommendation.isUserRecommendation ? '사용자 추천' : '채팅방 추천',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 점수
            Row(
              children: [
                const Text('추천 점수: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${recommendation.score.toInt()}점',
                  style: TextStyle(
                    color: recommendation.isHighScore 
                        ? Colors.green 
                        : recommendation.isMediumScore 
                            ? Colors.orange 
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 추천 이유
            const Text('추천 이유:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...recommendation.reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.blue)),
                  Expanded(child: Text(reason)),
                ],
              ),
            )),
            
            const SizedBox(height: 20),
            
            // 액션 버튼
            if (!recommendation.hasActionTaken) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        acceptRecommendation(recommendation.recommendationId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('수락'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        rejectRecommendation(recommendation.recommendationId);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('거절'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: recommendation.isAccepted 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recommendation.isAccepted ? '수락함' : '거절함',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: recommendation.isAccepted ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 추천 통계 요약
  Map<String, dynamic> get recommendationSummary {
    final stats = recommendationStats;
    return {
      'totalRecommendations': stats['total'] ?? 0,
      'unviewedCount': allRecommendations.where((r) => !r.isViewed).length,
      'highScoreCount': allRecommendations.where((r) => r.isHighScore).length,
      'averageScore': stats['averageScore']?.toStringAsFixed(1) ?? '0.0',
      'acceptanceRate': stats['total'] > 0 
          ? ((stats['acceptedCount'] ?? 0) / stats['total'] * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// 오늘의 추천 목록
  List<RecommendationModel> get todayRecommendations {
    final today = DateTime.now();
    return allRecommendations.where((r) {
      final diff = today.difference(r.createdAt).inDays;
      return diff == 0;
    }).toList();
  }

  /// 높은 점수 추천 목록
  List<RecommendationModel> get highScoreRecommendations {
    return allRecommendations.where((r) => r.isHighScore).toList();
  }

  /// 조회하지 않은 추천 개수
  int get unviewedCount {
    return allRecommendations.where((r) => !r.isViewed).length;
  }

  /// 추천 상태 텍스트
  String getRecommendationStatusText(RecommendationModel recommendation) {
    if (!recommendation.isViewed) {
      return '새로운 추천';
    } else if (recommendation.isAccepted) {
      return '수락함';
    } else if (recommendation.isRejected) {
      return '거절함';
    } else {
      return '확인함';
    }
  }

  /// 추천 상태 색상
  Color getRecommendationStatusColor(RecommendationModel recommendation) {
    if (!recommendation.isViewed) {
      return Colors.blue;
    } else if (recommendation.isAccepted) {
      return Colors.green;
    } else if (recommendation.isRejected) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
