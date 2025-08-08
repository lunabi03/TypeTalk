import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;

          const double designWidth = 390;
          const double designHeight = 844; // 긴 화면 기준
          final double designAspect = designWidth / designHeight;
          final double screenAspect = screenWidth / screenHeight;

          double imageWidth;
          double imageHeight;
          double offsetX;
          double offsetY;

          if (screenAspect > designAspect) {
            imageHeight = screenHeight;
            imageWidth = imageHeight * designAspect;
            offsetX = (screenWidth - imageWidth) / 2;
            offsetY = 0;
          } else {
            imageWidth = screenWidth;
            imageHeight = imageWidth / designAspect;
            offsetX = 0;
            offsetY = (screenHeight - imageHeight) / 2;
          }

          // 입력창 마이크 버튼 영역 (대략 하단 우측 원형 버튼 위치)
          const double micRight = 24;
          const double micBottom = 20;
          const double micSize = 44;

          final double scaleX = imageWidth / designWidth;
          final double scaleY = imageHeight / designHeight;

          final double micW = micSize * scaleX;
          final double micH = micSize * scaleY;
          final double micX = offsetX + (designWidth - micRight - micSize) * scaleX;
          final double micY = offsetY + (designHeight - micBottom - micSize) * scaleY;

          return Stack(
            children: [
              Positioned(
                left: offsetX,
                top: offsetY,
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  'assets/images/Chat Screen-1.png',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                left: micX,
                top: micY,
                width: micW,
                height: micH,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.snackbar('음성 입력', '마이크 버튼을 눌렀습니다.'),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSentMessage(String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildReceivedMessage(String message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}