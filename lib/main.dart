import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/screens/auth/login_screen.dart';
import 'package:typetalk/screens/auth/signup_screen.dart';
import 'package:typetalk/screens/chat/chat_screen.dart';
import 'package:typetalk/screens/profile/profile_screen.dart';
import 'package:typetalk/screens/profile/profile_edit_screen.dart';
import 'package:typetalk/screens/recommendation/recommendation_screen.dart';
import 'package:typetalk/screens/question/question_screen.dart';
import 'package:typetalk/screens/result/result_screen.dart';
import 'package:typetalk/screens/start/start_screen.dart';
import 'package:typetalk/screens/fcm/fcm_demo_screen.dart';
import 'package:typetalk/screens/chat/find_chat_partner_screen.dart';
import 'package:typetalk/screens/chat/mbti_avatar_selection_screen.dart';
import 'package:typetalk/screens/chat/ai_chat_screen.dart';

// 실제 Firebase 서비스들 (활성화)
import 'package:typetalk/services/real_firebase_service.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/services/real_auth_service.dart';

// 데모 서비스들 (비활성화)
// import 'package:typetalk/services/auth_service.dart';
// import 'package:typetalk/services/firestore_service.dart';
// import 'package:typetalk/services/user_repository.dart';
import 'package:typetalk/services/recommendation_service.dart';
import 'package:typetalk/services/chat_stats_service.dart';
import 'package:typetalk/services/chat_search_service.dart';
import 'package:typetalk/services/chat_notification_service.dart';
import 'package:typetalk/services/chat_invite_service.dart';
import 'package:typetalk/services/notification_service.dart';
import 'package:typetalk/services/fcm_service.dart';
import 'package:typetalk/services/ai_chat_service.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/middleware/auth_middleware.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 - 실제 모드로 실행
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase 초기화 완료 - 실제 모드로 실행합니다.');
    
    // Firebase Auth 서비스가 활성화되어 있는지 확인
    try {
      await FirebaseAuth.instance.authStateChanges().first;
      print('Firebase Auth 서비스 정상 작동 확인');
    } catch (authError) {
      print('Firebase Auth 서비스 오류: $authError');
      throw Exception('Firebase Authentication 서비스가 활성화되지 않았습니다. Firebase 콘솔에서 Authentication 서비스를 활성화해주세요.');
    }
    
  } catch (e) {
    print('Firebase 초기화 실패: $e');
    // Firebase 초기화 실패 시 사용자에게 명확한 오류 메시지 표시
    Get.snackbar(
      'Firebase 오류',
      'Firebase 서비스 초기화에 실패했습니다.\n\n${e.toString()}\n\nFirebase 콘솔에서 다음 서비스들이 활성화되어 있는지 확인해주세요:\n• Authentication\n• Firestore Database\n• Storage',
      duration: const Duration(seconds: 10),
      backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
      colorText: const Color(0xFFFF0000),
    );
    // 앱은 계속 실행하되, Firebase 기능은 제한됨
  }
  
  // 실제 Firebase 서비스들 등록
  Get.put(RealFirebaseService());
  Get.put(RealUserRepository());
  Get.put(RealAuthService());
  Get.put(AuthController()); // AuthController를 먼저 등록
  Get.put(RecommendationService());
  Get.put(ChatStatsService());
  Get.put(ChatSearchService());
  Get.put(ChatNotificationService());
  Get.put(ChatInviteService()); // AuthController 이후에 등록
  Get.put(NotificationService()); // 통합 알림 서비스 등록
  Get.put(FCMService());
  Get.put(AIChatService()); // AI 채팅 서비스 등록
  
  await Future.delayed(const Duration(milliseconds: 500)); // Firebase Auth 상태 로드 대기
  
  runApp(const MyApp());
  
  // 앱 실행 후 AuthController 등록 (GetMaterialApp 컨텍스트 확보 후)
  Get.put(AuthController());
}

// MyApp 클래스

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
        initialRoute: AppRoutes.login, // 로그인 화면부터 시작
        getPages: [
          GetPage(
            name: AppRoutes.login, 
            page: () => const LoginScreen(),
            middlewares: [GuestMiddleware()],
          ),
          GetPage(
            name: AppRoutes.signup, 
            page: () => const SignupScreen(),
            middlewares: [GuestMiddleware()],
          ),
          GetPage(
            name: AppRoutes.start, 
            page: () => const StartScreen(),
            middlewares: [SessionMiddleware()],
          ),
          GetPage(
            name: AppRoutes.question, 
            page: () => const QuestionScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.result, 
            page: () => const ResultScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.profile, 
            page: () => const ProfileScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.profileEdit, 
            page: () => const ProfileEditScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.recommendation, 
            page: () => const RecommendationScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.chat, 
            page: () => const ChatScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.findChatPartner, 
            page: () => const FindChatPartnerScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.fcmDemo, 
            page: () => const FCMDemoScreen(),
            middlewares: [SessionMiddleware()],
          ),
          GetPage(
            name: AppRoutes.mbtiAvatarSelection, 
            page: () => const MBTIAvatarSelectionScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
          GetPage(
            name: AppRoutes.aiChat, 
            page: () => const AIChatScreen(),
            middlewares: [SessionMiddleware(), AuthMiddleware()],
          ),
        ],
      ),
    );
  }
}