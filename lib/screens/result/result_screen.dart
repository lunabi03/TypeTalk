import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/routes/app_routes.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

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

          // 버튼 좌표(디자인 기준)
          const double left = 24;
          const double right = 24;
          const double height = 56;
          const double bottomPurple = 24; // 하단 여백
          const double spacing = 16;
          const double bottomGray = bottomPurple + height + spacing; // 위 버튼의 바닥 여백

          // 상단 뒤로가기 영역(디자인 기준)
          const double backLeft = 12;
          const double backTop = 16; // 상태바 아래 여백 고려
          const double backSize = 40; // 터치 영역

          final double scaleX = imageWidth / designWidth;
          final double scaleY = imageHeight / designHeight;

          final double purpleWidth = (designWidth - left - right) * scaleX;
          final double purpleHeight = height * scaleY;
          final double purpleX = offsetX + left * scaleX;
          final double purpleY = offsetY + (designHeight - bottomPurple - height) * scaleY;

          final double grayWidth = purpleWidth;
          final double grayHeight = purpleHeight;
          final double grayX = purpleX;
          final double grayY = offsetY + (designHeight - bottomGray - height) * scaleY;

          // 뒤로가기 버튼 스케일 좌표
          final double backX = offsetX + backLeft * scaleX;
          final double backY = offsetY + backTop * scaleY;
          final double backW = backSize * scaleX;
          final double backH = backSize * scaleY;

          return Stack(
            children: [
              Positioned(
                left: offsetX,
                top: offsetY,
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  'assets/images/Result Screen.png',
                  fit: BoxFit.fill,
                ),
              ),
              // 결과 공유하기 버튼 영역
              Positioned(
                left: grayX,
                top: grayY,
                width: grayWidth,
                height: grayHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.snackbar('공유', '결과 공유하기를 눌렀습니다.'),
                  child: const SizedBox.expand(),
                ),
              ),
              // 상세 분석보기(프리미엄) 버튼 영역
              Positioned(
                left: purpleX,
                top: purpleY,
                width: purpleWidth,
                height: purpleHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.snackbar('프리미엄', '상세 분석보기(프리미엄)를 눌렀습니다.'),
                  child: const SizedBox.expand(),
                ),
              ),
              // 상단 뒤로가기 터치 영역
              Positioned(
                left: backX,
                top: backY,
                width: backW,
                height: backH,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(AppRoutes.profile),
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