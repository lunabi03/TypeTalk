import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

          return Stack(
            children: [
              Positioned(
                left: offsetX,
                top: offsetY,
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  'assets/images/Profile Screen.png',
                  fit: BoxFit.fill,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}