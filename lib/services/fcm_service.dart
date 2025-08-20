import 'dart:convert';
import 'package:get/get.dart';
import 'package:typetalk/models/chat_notification_model.dart';
import 'package:typetalk/services/firestore_service.dart';

/// Firebase Cloud Messaging (FCM) 서비스
/// 푸시 알림 전송, 수신, 토큰 관리를 담당합니다.
class FCMService extends GetxService {
  static FCMService get instance => Get.find<FCMService>();
  
  final DemoFirestoreService _firestore = Get.find<DemoFirestoreService>();
  
  // FCM 토큰
  RxString fcmToken = ''.obs;
  
  // 알림 설정
  RxBool isNotificationEnabled = true.obs;
  RxBool isSoundEnabled = true.obs;
  RxBool isVibrationEnabled = true.obs;
  
  // 알림 권한 상태
  RxBool hasPermission = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeFCM();
  }
  
  /// FCM 초기화
  Future<void> _initializeFCM() async {
    try {
      // 실제 FCM 구현에서는 여기서 Firebase 초기화 및 토큰 획득
      await _requestNotificationPermission();
      await _getFCMToken();
      await _setupMessageHandlers();
      
      print('FCM 서비스 초기화 완료');
    } catch (e) {
      print('FCM 초기화 오류: $e');
    }
  }
  
  /// 알림 권한 요청
  Future<void> _requestNotificationPermission() async {
    try {
      // 실제 구현에서는 Firebase Messaging 권한 요청
      hasPermission.value = true;
      print('알림 권한 획득 완료');
    } catch (e) {
      print('알림 권한 요청 오류: $e');
      hasPermission.value = false;
    }
  }
  
  /// FCM 토큰 획득
  Future<void> _getFCMToken() async {
    try {
      // 실제 구현에서는 Firebase Messaging에서 토큰 획득
      fcmToken.value = 'demo_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      
      // 토큰을 Firestore에 저장
      await _saveFCMToken(fcmToken.value);
      
      print('FCM 토큰 획득 완료: ${fcmToken.value}');
    } catch (e) {
      print('FCM 토큰 획득 오류: $e');
    }
  }
  
  /// FCM 토큰을 Firestore에 저장
  Future<void> _saveFCMToken(String token) async {
    try {
      // 실제 구현에서는 사용자 문서에 FCM 토큰 저장
      await _firestore.users.doc('current_user').set({
        'fcmToken': token,
        'lastTokenUpdate': DateTime.now().toIso8601String(),
      });
      print('FCM 토큰 저장 완료');
    } catch (e) {
      print('FCM 토큰 저장 오류: $e');
    }
  }
  
  /// 메시지 핸들러 설정
  Future<void> _setupMessageHandlers() async {
    try {
      // 실제 구현에서는 Firebase Messaging 메시지 핸들러 설정
      print('메시지 핸들러 설정 완료');
    } catch (e) {
      print('메시지 핸들러 설정 오류: $e');
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
      if (!hasPermission.value) {
        print('알림 권한이 없습니다.');
        return false;
      }
      
      // 실제 구현에서는 FCM 서버에 알림 전송 요청
      final notification = ChatNotificationModel(
        notificationId: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: recipientIds.first, // 첫 번째 수신자를 userId로 사용
        chatId: chatId,
        messageId: null,
        type: NotificationType.chatMessage,
        title: chatTitle ?? '새 메시지',
        body: '$senderName: $messageContent',
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
        readAt: null,
        dismissedAt: null,
        metadata: NotificationMetadata(
          chatId: chatId,
          senderName: senderName,
          messagePreview: messageContent.length > 50 
              ? '${messageContent.substring(0, 50)}...' 
              : messageContent,
        ),
      );
      
      // 알림을 Firestore에 저장
      await _firestore.notifications.add(notification.toMap());
      
      // 실제 FCM 전송 (모의 구현)
      await _simulateFCMDelivery(notification);
      
      print('채팅 알림 전송 완료: ${notification.notificationId}');
      return true;
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
      if (!hasPermission.value) {
        print('알림 권한이 없습니다.');
        return false;
      }
      
      final notification = ChatNotificationModel(
        notificationId: 'invite_${DateTime.now().millisecondsSinceEpoch}',
        userId: inviteeIds.first, // 첫 번째 초대자를 userId로 사용
        chatId: chatId,
        messageId: null,
        type: NotificationType.chatInvite,
        title: '채팅방 초대',
        body: '$inviterName님이 "$chatTitle" 채팅방에 초대했습니다.',
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
        readAt: null,
        dismissedAt: null,
        metadata: NotificationMetadata(
          chatId: chatId,
          chatTitle: chatTitle,
          inviterName: inviterName,
        ),
      );
      
      // 알림을 Firestore에 저장
      await _firestore.notifications.add(notification.toMap());
      
      // 실제 FCM 전송 (모의 구현)
      await _simulateFCMDelivery(notification);
      
      print('초대 알림 전송 완료: ${notification.notificationId}');
      return true;
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
      if (!hasPermission.value) {
        print('알림 권한이 없습니다.');
        return false;
      }
      
      final notification = ChatNotificationModel(
        notificationId: 'system_${DateTime.now().millisecondsSinceEpoch}',
        userId: recipientIds.first, // 첫 번째 수신자를 userId로 사용
        chatId: '',
        messageId: null,
        type: NotificationType.system,
        title: title,
        body: body,
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
        readAt: null,
        dismissedAt: null,
        metadata: metadata != null 
            ? NotificationMetadata.fromMap(metadata) 
            : NotificationMetadata(),
      );
      
      // 알림을 Firestore에 저장
      await _firestore.notifications.add(notification.toMap());
      
      // 실제 FCM 전송 (모의 구현)
      await _simulateFCMDelivery(notification);
      
      print('시스템 알림 전송 완료: ${notification.notificationId}');
      return true;
    } catch (e) {
      print('시스템 알림 전송 오류: $e');
      return false;
    }
  }
  
  /// FCM 전송 모의 구현 (실제로는 FCM 서버 API 호출)
  Future<void> _simulateFCMDelivery(ChatNotificationModel notification) async {
    try {
      // 실제 구현에서는 FCM 서버에 HTTP 요청
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 알림 상태를 전송됨으로 업데이트
      await _firestore.notifications.doc(notification.notificationId).update({
        'status': NotificationStatus.sent.value,
      });
      
      print('FCM 전송 완료: ${notification.notificationId}');
    } catch (e) {
      print('FCM 전송 오류: $e');
      
      // 전송 실패 시 상태 업데이트
      await _firestore.notifications.doc(notification.notificationId).update({
        'status': NotificationStatus.failed.value,
      });
    }
  }
  
  /// 알림 설정 업데이트
  Future<void> updateNotificationSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) async {
    try {
      if (enabled != null) isNotificationEnabled.value = enabled;
      if (sound != null) isSoundEnabled.value = sound;
      if (vibration != null) isVibrationEnabled.value = vibration;
      
      // 설정을 Firestore에 저장
      await _firestore.users.doc('current_user').update({
        'notificationSettings': {
          'enabled': isNotificationEnabled.value,
          'sound': isSoundEnabled.value,
          'vibration': isVibrationEnabled.value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      });
      
      print('알림 설정 업데이트 완료');
    } catch (e) {
      print('알림 설정 업데이트 오류: $e');
    }
  }
  
  /// 특정 사용자에게 알림 전송
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      return await sendSystemNotification(
        title: title,
        body: body,
        recipientIds: [userId],
        metadata: metadata,
      );
    } catch (e) {
      print('사용자 알림 전송 오류: $e');
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
      // 발신자를 제외한 참여자들에게 알림 전송
      final recipientIds = participantIds
          .where((id) => id != senderId)
          .toList();
      
      if (recipientIds.isEmpty) {
        print('알림을 받을 참여자가 없습니다.');
        return true;
      }
      
      return await sendChatNotification(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        messageContent: messageContent,
        recipientIds: recipientIds,
        chatTitle: chatTitle,
      );
    } catch (e) {
      print('참여자 일괄 알림 전송 오류: $e');
      return false;
    }
  }
  
  /// 알림 읽음 처리
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.notifications.doc(notificationId).update({
        'status': NotificationStatus.read.value,
        'readAt': DateTime.now().toIso8601String(),
      });
      
      print('알림 읽음 처리 완료: $notificationId');
    } catch (e) {
      print('알림 읽음 처리 오류: $e');
    }
  }
  
  /// 모든 알림 읽음 처리
  Future<void> markAllNotificationsAsRead() async {
    try {
      final notifications = await _firestore.notifications
          .where('userId', isEqualTo: 'current_user')
          .where('status', isEqualTo: NotificationStatus.sent.value)
          .get();
      
      for (final doc in notifications) {
        await _firestore.notifications.doc(doc.id).update({
          'status': NotificationStatus.read.value,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
      
      print('모든 알림 읽음 처리 완료');
    } catch (e) {
      print('모든 알림 읽음 처리 오류: $e');
    }
  }
  
  /// FCM 토큰 새로고침
  Future<void> refreshFCMToken() async {
    try {
      await _getFCMToken();
      print('FCM 토큰 새로고침 완료');
    } catch (e) {
      print('FCM 토큰 새로고침 오류: $e');
    }
  }
  
  /// 알림 권한 상태 확인
  Future<bool> checkNotificationPermission() async {
    try {
      // 실제 구현에서는 Firebase Messaging 권한 상태 확인
      hasPermission.value = true;
      return hasPermission.value;
    } catch (e) {
      print('알림 권한 확인 오류: $e');
      hasPermission.value = false;
      return false;
    }
  }
}
