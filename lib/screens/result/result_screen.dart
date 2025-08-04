import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/app_button.dart';
import 'package:typetalk/core/widgets/app_card.dart';
import 'package:typetalk/routes/app_routes.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  '당신의 MBTI는',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 24),
                Text(
                  'ENFP',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primary,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 40),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('성격 특징', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      _buildTraitItem('열정적이고 창의적인 성격'),
                      _buildTraitItem('새로운 가능성을 탐색하는 것을 좋아함'),
                      _buildTraitItem('사람들과의 교류를 즐김'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('잘 맞는 유형', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      _buildMatchItem('INTJ', '94%'),
                      _buildMatchItem('INFJ', '89%'),
                      _buildMatchItem('ENTJ', '85%'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  text: '프로필 설정하기',
                  onPressed: () => Get.toNamed(AppRoutes.profile),
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTraitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  Widget _buildMatchItem(String mbti, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(mbti, style: AppTextStyles.body),
          Text(
            percentage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}