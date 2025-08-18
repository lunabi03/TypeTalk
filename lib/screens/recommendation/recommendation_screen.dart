import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/controllers/recommendation_controller.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/app_button.dart';
import 'package:typetalk/models/recommendation_model.dart';

/// 추천 화면
/// 사용자 추천 및 채팅방 추천을 보여주는 메인 화면입니다.
class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recommendationController = Get.put(RecommendationController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '추천',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // 새로고침 버튼
          Obx(() => IconButton(
            onPressed: recommendationController.isRefreshing.value
                ? null
                : () => recommendationController.refreshRecommendations(),
            icon: recommendationController.isRefreshing.value
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.refresh,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
          )),
        ],
      ),
      body: Obx(() {
        if (recommendationController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 헤더 섹션
            _buildHeaderSection(recommendationController, authController),
            
            // 필터 및 정렬 섹션
            _buildFilterSection(recommendationController),
            
            // 추천 목록
            Expanded(
              child: _buildRecommendationList(recommendationController),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: recommendationController.isGenerating.value
            ? null
            : () => recommendationController.generateNewRecommendations(),
        backgroundColor: AppColors.primary,
        icon: recommendationController.isGenerating.value
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          recommendationController.isGenerating.value ? '생성 중...' : '새 추천 생성',
          style: const TextStyle(color: Colors.white),
        ),
      )),
    );
  }

  /// 헤더 섹션
  Widget _buildHeaderSection(RecommendationController controller, AuthController authController) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '나를 위한 추천',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          Obx(() {
            final summary = controller.recommendationSummary;
            return Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '총 추천',
                    '${summary['totalRecommendations']}개',
                    Icons.list_alt,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '새 추천',
                    '${summary['unviewedCount']}개',
                    Icons.new_releases,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '평균 점수',
                    '${summary['averageScore']}점',
                    Icons.star,
                  ),
                ),
              ],
            );
          }),
          
          SizedBox(height: 16.h),
          
          // 내 MBTI 정보
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '내 MBTI: ${authController.currentUserMBTI ?? "미완료"}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (authController.currentUserMBTI == null)
                  AppButton(
                    text: '테스트하기',
                    onPressed: () => Get.toNamed('/question'),
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 아이템
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20.sp,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 필터 섹션
  Widget _buildFilterSection(RecommendationController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          // 타입 필터
          Row(
            children: [
              Text(
                '필터:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() => Row(
                    children: [
                      _buildFilterChip(
                        '전체',
                        'all',
                        controller.selectedType.value,
                        controller.changeRecommendationType,
                      ),
                      SizedBox(width: 8.w),
                      _buildFilterChip(
                        '사용자',
                        'user',
                        controller.selectedType.value,
                        controller.changeRecommendationType,
                      ),
                      SizedBox(width: 8.w),
                      _buildFilterChip(
                        '채팅방',
                        'chat',
                        controller.selectedType.value,
                        controller.changeRecommendationType,
                      ),
                    ],
                  )),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // 정렬 및 추가 필터
          Row(
            children: [
              // 정렬
              Text(
                '정렬:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Obx(() => DropdownButton<String>(
                value: controller.sortBy.value,
                onChanged: (value) => controller.changeSortBy(value!),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'score', child: Text('점수순')),
                  DropdownMenuItem(value: 'date', child: Text('최신순')),
                  DropdownMenuItem(value: 'compatibility', child: Text('호환성순')),
                ],
              )),
              
              const Spacer(),
              
              // 미확인 추천만 보기
              Obx(() => Row(
                children: [
                  Checkbox(
                    value: controller.showOnlyUnviewed.value,
                    onChanged: (_) => controller.toggleShowOnlyUnviewed(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    '새 추천만',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// 필터 칩
  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onTap) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 추천 목록
  Widget _buildRecommendationList(RecommendationController controller) {
    return Obx(() {
      final recommendations = controller.filteredRecommendations;
      
      if (recommendations.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16.h),
              Text(
                '추천이 없습니다',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '새 추천 생성 버튼을 눌러보세요',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        itemCount: recommendations.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          return _buildRecommendationCard(recommendation, controller);
        },
      );
    });
  }

  /// 추천 카드
  Widget _buildRecommendationCard(RecommendationModel recommendation, RecommendationController controller) {
    return GestureDetector(
      onTap: () => controller.showRecommendationDetails(recommendation),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: recommendation.isViewed 
                ? AppColors.border 
                : AppColors.primary.withOpacity(0.3),
            width: recommendation.isViewed ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                // 타입 아이콘
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: recommendation.isUserRecommendation 
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    recommendation.isUserRecommendation 
                        ? Icons.person 
                        : Icons.chat,
                    color: recommendation.isUserRecommendation 
                        ? Colors.blue 
                        : Colors.green,
                    size: 16.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.isUserRecommendation ? '사용자 추천' : '채팅방 추천',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatDate(recommendation.createdAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 점수
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getScoreColor(recommendation.score).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${recommendation.score.toInt()}점',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getScoreColor(recommendation.score),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                // 상태 표시
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: controller.getRecommendationStatusColor(recommendation).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    controller.getRecommendationStatusText(recommendation),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: controller.getRecommendationStatusColor(recommendation),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // 추천 이유
            Text(
              '추천 이유:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            ...recommendation.reasons.take(2).map((reason) => Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      reason,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            
            if (recommendation.reasons.length > 2) ...[
              Text(
                '외 ${recommendation.reasons.length - 2}개',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            SizedBox(height: 12.h),
            
            // 액션 버튼 (미확인 추천만)
            if (!recommendation.hasActionTaken) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: '수락',
                      onPressed: () => controller.acceptRecommendation(recommendation.recommendationId),
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppButton(
                      text: '거절',
                      onPressed: () => controller.rejectRecommendation(recommendation.recommendationId),
                      backgroundColor: AppColors.surface,
                      textColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 점수 색상 반환
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
