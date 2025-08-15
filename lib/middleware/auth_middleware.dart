import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/routes/app_routes.dart';

// 인증이 필요한 페이지를 보호하는 미들웨어
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    // 로그인이 필요한 페이지들
    final protectedRoutes = [
      AppRoutes.profile,
      AppRoutes.chat,
      AppRoutes.question,
      AppRoutes.result,
    ];

    // 현재 라우트가 보호된 라우트이고 로그인되지 않은 경우
    if (protectedRoutes.contains(route) && !authController.isLoggedIn) {
      Get.snackbar('알림', '로그인이 필요한 서비스입니다.');
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}

// 로그인된 사용자가 접근하면 안 되는 페이지를 보호하는 미들웨어
class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    // 게스트 전용 페이지들 (로그인된 사용자는 접근 불가)
    final guestOnlyRoutes = [
      AppRoutes.login,
      AppRoutes.signup,
    ];

    // 현재 라우트가 게스트 전용이고 이미 로그인된 경우
    if (guestOnlyRoutes.contains(route) && authController.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.start);
    }

    return null;
  }
}

// 세션 유효성을 확인하는 미들웨어
class SessionMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    // 세션이 유효하지 않은 경우 강제 로그아웃
    if (authController.isLoggedIn && !authController.isSessionValid()) {
      authController.forceLogout(reason: '세션이 만료되어 자동 로그아웃되었습니다.');
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}
