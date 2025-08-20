import 'package:get/get.dart';
import 'package:typetalk/services/fcm_service.dart';
import 'package:typetalk/models/chat_notification_model.dart';

/// FCM 컨트롤러
/// UI에서 FCM 서비스를 사용하기 위한 컨트롤러입니다.
class FCMController extends GetxController {
  static FCMController get instance => Get.find<FCMController>();
  
  final FCMService _fcmService = Get.find<FCMService>();
  
  // 알림 목록
  RxList<ChatNotificationModel> notifications = <ChatNotificationModel>[].obs;
  
  // 읽지 않은 알림 수
  RxInt unreadCount = 0.obs;
  
  // 알림 설정
  RxBool isNotificationEnabled = true.obs;
  RxBool isSoundEnabled = true.obs;
  RxBool isVibrationEnabled = true.obs;
  
  // FCM 상태
  RxBool isFCMInitialized = false.obs;
  RxString fcmToken = ''.obs;
  RxBool hasPermission = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeFCMController();
  }
  
  /// FCM 컨트롤러 초기화
  Future<void> _initializeFCMController() async {
    try {
      // FCM 서비스 상태 동기화
      isNotificationEnabled.bindStream(_fcmService.isNotificationEnabled.stream);
      isSoundEnabled.bindStream(_fcmService.isSoundEnabled.stream);
      isVibrationEnabled.bindStream(_fcmService.isVibrationEnabled.stream);
      fcmToken.bindStream(_fcmService.fcmToken.stream);
      hasPermission.bindStream(_fcmService.hasPermission.stream);
      
      // FCM 초기화 완료 대기
      await Future.delayed(const Duration(seconds: 1));
      isFCMInitialized.value = true;
      
      print('FCM 컨트롤러 초기화 완료');
    } catch (e) {
      print('FCM 컨트롤러 초기화 오류: $e');
    }
  }
  
  /// 채팅 알림 전송
  Future<bool> sendChatNotification({
    required String chatId,
    required String senderId,
    required String senderName,
    required String messageContent,
    required List<String> recipientIds,
    String? chatTitle,
  }) async {
    try {
      final success = await _fcmService.sendChatNotification(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        messageContent: messageContent,
        recipientIds: recipientIds,
        chatTitle: chatTitle,
      );
      
      if (success) {
        print('채팅 알림 전송 성공');
      } else {
        print('채팅 알림 전송 실패');
      }
      
      return success;
    } catch (e) {
      print('채팅 알림 전송 오류: $e');
      return false;
    }
  }
  
  /// 그룹 채팅 초대 알림 전송
  Future<bool> sendInviteNotification({
    required String chatId,
    required String inviterId,
    required String inviterName,
    required String chatTitle,
    required List<String> inviteeIds,
  }) async {
    try {
      final success = await _fcmService.sendInviteNotification(
        chatId: chatId,
        inviterId: inviterId,
        inviterName: inviterName,
        chatTitle: chatTitle,
        inviteeIds: inviteeIds,
      );
      
      if (success) {
        print('초대 알림 전송 성공');
      } else {
        print('초대 알림 전송 실패');
      }
      
      return success;
    } catch (e) {
      print('초대 알림 전송 오류: $e');
      return false;
    }
  }
  
  /// 시스템 알림 전송
  Future<bool> sendSystemNotification({
    required String title,
    required String body,
    required List<String> recipientIds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final success = await _fcmService.sendSystemNotification(
        title: title,
        body: body,
        recipientIds: recipientIds,
        metadata: metadata,
      );
      
      if (success) {
        print('시스템 알림 전송 성공');
      } else {
        print('시스템 알림 전송 실패');
      }
      
      return success;
    } catch (e) {
      print('시스템 알림 전송 오류: $e');
      return false;
    }
  }
  
  /// 채팅방 참여자들에게 일괄 알림 전송
  Future<bool> sendNotificationToChatParticipants({
    required String chatId,
    required String senderId,
    required String senderName,
    required String messageContent,
    required List<String> participantIds,
    String? chatTitle,
  }) async {
    try {
      final success = await _fcmService.sendNotificationToChatParticipants(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        messageContent: messageContent,
        participantIds: participantIds,
        chatTitle: chatTitle,
      );
      
      if (success) {
        print('참여자 일괄 알림 전송 성공');
      } else {
        print('참여자 일괄 알림 전송 실패');
      }
      
      return success;
    } catch (e) {
      print('참여자 일괄 알림 전송 오류: $e');
      return false;
    }
  }
  
  /// 알림 설정 업데이트
  Future<void> updateNotificationSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) async {
    try {
      await _fcmService.updateNotificationSettings(
        enabled: enabled,
        sound: sound,
        vibration: vibration,
      );
      
      print('알림 설정 업데이트 완료');
    } catch (e) {
      print('알림 설정 업데이트 오류: $e');
    }
  }
  
  /// 알림 읽음 처리
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _fcmService.markNotificationAsRead(notificationId);
      
      // 로컬 상태 업데이트
      final index = notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        final notification = notifications[index];
        notifications[index] = notification.copyWith(
          status: NotificationStatus.read,
          readAt: DateTime.now(),
        );
        _updateUnreadCount();
      }
      
      print('알림 읽음 처리 완료: $notificationId');
    } catch (e) {
      print('알림 읽음 처리 오류: $e');
    }
  }
  
  /// 모든 알림 읽음 처리
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _fcmService.markAllNotificationsAsRead();
      
      // 로컬 상태 업데이트
      for (int i = 0; i < notifications.length; i++) {
        if (notifications[i].status.value == 'sent') {
          notifications[i] = notifications[i].copyWith(
            status: NotificationStatus.read,
            readAt: DateTime.now(),
          );
        }
      }
      _updateUnreadCount();
      
      print('모든 알림 읽음 처리 완료');
    } catch (e) {
      print('모든 알림 읽음 처리 오류: $e');
    }
  }
  
  /// FCM 토큰 새로고침
  Future<void> refreshFCMToken() async {
    try {
      await _fcmService.refreshFCMToken();
      print('FCM 토큰 새로고침 완료');
    } catch (e) {
      print('FCM 토큰 새로고침 오류: $e');
    }
  }
  
  /// 알림 권한 상태 확인
  Future<bool> checkNotificationPermission() async {
    try {
      final hasPermission = await _fcmService.checkNotificationPermission();
      print('알림 권한 확인 완료: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('알림 권한 확인 오류: $e');
      return false;
    }
  }
  
  /// 읽지 않은 알림 수 업데이트
  void _updateUnreadCount() {
    unreadCount.value = notifications
        .where((n) => n.status.value == 'sent')
        .length;
  }
  
  /// 알림 목록에 알림 추가
  void addNotification(ChatNotificationModel notification) {
    notifications.insert(0, notification);
    _updateUnreadCount();
  }
  
  /// 알림 목록에서 알림 제거
  void removeNotification(String notificationId) {
    notifications.removeWhere((n) => n.notificationId == notificationId);
    _updateUnreadCount();
  }
  
  /// 알림 목록 새로고침
  Future<void> refreshNotifications() async {
    try {
      // 실제 구현에서는 Firestore에서 알림 목록을 가져옴
      print('알림 목록 새로고침 완료');
    } catch (e) {
      print('알림 목록 새로고침 오류: $e');
    }
  }
  
  /// 테스트 알림 전송
  Future<void> sendTestNotification() async {
    try {
      final success = await sendSystemNotification(
        title: '테스트 알림',
        body: 'FCM 연동이 정상적으로 작동하고 있습니다!',
        recipientIds: ['current_user'],
        metadata: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (success) {
        Get.snackbar(
          '성공',
          '테스트 알림이 전송되었습니다.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          '실패',
          '테스트 알림 전송에 실패했습니다.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('테스트 알림 전송 오류: $e');
      Get.snackbar(
        '오류',
        '테스트 알림 전송 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }
  
  /// FCM 상태 정보 반환
  Map<String, dynamic> getFCMStatus() {
    return {
      'isInitialized': isFCMInitialized.value,
      'hasPermission': hasPermission.value,
      'isEnabled': isNotificationEnabled.value,
      'token': fcmToken.value,
      'unreadCount': unreadCount.value,
      'totalNotifications': notifications.length,
    };
  }
}
