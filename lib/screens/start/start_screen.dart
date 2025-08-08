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

          // 하단 네비게이션 바의 중앙(프로필) 버튼 영역 (디자인 축 기준 3등분)
          const double navHeight = 88; // 바 높이 근사값
          final double navTopDesign = designHeight - navHeight;
          final double thirdWidthDesign = designWidth / 3;
          final double profileLeftDesign = thirdWidthDesign; // 중앙 1/3 시작점

          final double profileX = offsetX + profileLeftDesign * scaleX;
          final double profileY = offsetY + navTopDesign * scaleY;
          final double profileW = thirdWidthDesign * scaleX;
          final double profileH = navHeight * scaleY;

          // 우측 1/3: 채팅 버튼 영역
          final double chatLeftDesign = thirdWidthDesign * 2;
          final double chatX = offsetX + chatLeftDesign * scaleX;
          final double chatY = profileY;
          final double chatW = thirdWidthDesign * scaleX;
          final double chatH = profileH;

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
              // 하단 프로필 버튼 터치 영역
              Positioned(
                left: profileX,
                top: profileY,
                width: profileW,
                height: profileH,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(AppRoutes.profile),
                  child: const SizedBox.expand(),
                ),
              ),
              // 하단 채팅 버튼 터치 영역
              Positioned(
                left: chatX,
                top: chatY,
                width: chatW,
                height: chatH,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(AppRoutes.chat),
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