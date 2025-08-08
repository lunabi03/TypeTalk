import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/routes/app_routes.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;

          const double designWidth = 390;
          const double designHeight = 844;
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

          // 버튼의 디자인 좌표(스크린샷 기준)
          const double buttonLeft = 24;
          const double buttonRight = 24;
          const double buttonHeight = 60;
          const double buttonBottom = 120; // 하단 내비+여백 고려한 근사값

          final double scaleX = imageWidth / designWidth;
          final double scaleY = imageHeight / designHeight;
          final double buttonWidthScaled = (designWidth - buttonLeft - buttonRight) * scaleX;
          final double buttonHeightScaled = buttonHeight * scaleY;
          final double buttonX = offsetX + buttonLeft * scaleX;
          final double buttonY = offsetY + (designHeight - buttonBottom - buttonHeight) * scaleY;

          return Stack(
            children: [
              Positioned(
                left: offsetX,
                top: offsetY,
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  'assets/images/Start Screen.png',
                  fit: BoxFit.fill, // 주어진 박스 내에서만 채움 (비율은 박스에서 보장)
                ),
              ),
              Positioned(
                left: buttonX,
                top: buttonY,
                width: buttonWidthScaled,
                height: buttonHeightScaled,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(AppRoutes.question),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
}