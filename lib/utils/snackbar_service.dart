import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 스낵바 중복 표시를 방지하는 서비스
/// - 같은 태그(tag)에 대해 일정 시간(cooldown) 내 중복 호출 시 무시
/// - 이미 스낵바가 떠있는 동안 같은 태그로 또 호출되면 무시
class SnackbarService {
  SnackbarService._();

  static final Map<String, DateTime> _lastShownByTag = {};

  /// 동일 태그 기준으로 한 번만 표시
  /// - tag: 중복 제어용 키 (예: 'login_success')
  /// - cooldown: 같은 태그로 재호출을 무시할 최소 간격
  static void showTagged(
    String tag, {
    required String title,
    required String message,
    Duration cooldown = const Duration(seconds: 2),
    Color backgroundColor = const Color(0xFF4CAF50),
    Color foregroundColor = Colors.white,
    SnackPosition position = SnackPosition.TOP,
  }) {
    final now = DateTime.now();
    final last = _lastShownByTag[tag];

    // 쿨다운 내 재호출이면 무시
    if (last != null && now.difference(last) < cooldown) {
      return;
    }

    // 이미 열려있고 같은 태그를 바로 또 호출하면 무시
    if (Get.isSnackbarOpen == true) {
      // 동일 태그라면 무시 (다른 태그는 기존 스낵바를 유지)
      if (last != null && now.difference(last) < cooldown) {
        return;
      }
    }

    _lastShownByTag[tag] = now;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor.withOpacity(0.9),
      colorText: foregroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
    );
  }

  /// 단순 한 번만 표시(제목+메시지 조합으로 중복 제어)
  static final Map<String, DateTime> _lastShownByKey = {};
  static void showOnce({
    required String title,
    required String message,
    Duration cooldown = const Duration(seconds: 2),
    Color backgroundColor = const Color(0xFF323232),
    Color foregroundColor = Colors.white,
    SnackPosition position = SnackPosition.TOP,
  }) {
    final key = '$title|$message';
    final now = DateTime.now();
    final last = _lastShownByKey[key];
    if (last != null && now.difference(last) < cooldown) return;
    _lastShownByKey[key] = now;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor.withOpacity(0.95),
      colorText: foregroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      isDismissible: true,
    );
  }
}


