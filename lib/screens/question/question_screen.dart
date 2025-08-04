import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/app_button.dart';
import 'package:typetalk/routes/app_routes.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('MBTI 검사', style: AppTextStyles.h2),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '질문 1/60',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 24),
              Text(
                '나는 새로운 사람을 만나는 것을...',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: '즐기는 편이다',
                onPressed: () {},
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: '부담스러워한다',
                onPressed: () {},
                isSecondary: true,
                isFullWidth: true,
              ),
              const Spacer(),
              // Progress bar
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.3, // 30% progress
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}