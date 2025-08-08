import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/screens/chat/chat_screen.dart';
import 'package:typetalk/screens/profile/profile_screen.dart';
import 'package:typetalk/screens/question/question_screen.dart';
import 'package:typetalk/screens/result/result_screen.dart';
import 'package:typetalk/screens/start/start_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        title: 'TypeMate',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Pretendard',
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.start,
        getPages: [
          GetPage(name: AppRoutes.start, page: () => const StartScreen()),
          GetPage(name: AppRoutes.question, page: () => const QuestionScreen()),
          GetPage(name: AppRoutes.result, page: () => const ResultScreen()),
          GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
          GetPage(name: AppRoutes.chat, page: () => const ChatScreen()),
        ],
      ),
    );
  }
}