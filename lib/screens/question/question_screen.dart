import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/routes/app_routes.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '5/10',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5, // 5/10 진행
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Question Text
            Text(
              '나는 새로운 사람들을\n만나는 것을 즐긴다',
              style: AppTextStyles.h2.copyWith(
                fontSize: 24,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // Answer Options
            _buildAnswerOption('매우 그렇다', false),
            const SizedBox(height: 12),
            _buildAnswerOption('그렇다', false),
            const SizedBox(height: 12),
            _buildAnswerOption('보통이다', true),
            const SizedBox(height: 12),
            _buildAnswerOption('아니다', false),
            const SizedBox(height: 12),
            _buildAnswerOption('전혀 아니다', false),
            const Spacer(),
            // Next Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption(String text, bool isSelected) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}