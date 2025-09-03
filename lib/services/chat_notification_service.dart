import 'package:get/get.dart';
import 'package:typetalk/models/chat_notification_model.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/services/real_firebase_service.dart';

// 채팅 알림 서비스 클래스
class ChatNotificationService extends GetxService {
  final RealFirebaseService _firestoreService = Get.find<RealFirebaseService>();
  
  // 알림 데이터
  final RxList<ChatNotificationModel> notifications = <ChatNotificationModel>[].obs;
  final RxList<ChatNotificationModel> unreadNotifications = <ChatNotificationModel>[].obs;
  
  // 알림 설정
  final RxBool pushNotificationsEnabled = true.obs;
  final RxBool soundEnabled = true.obs;
  final RxBool vibrationEnabled = true.obs;
  final RxBool showPreview = true.obs;
  
  // 알림 통계
  final RxInt totalNotifications = 0.obs;
  final RxInt unreadCount = 0.obs;
  final RxInt todayNotifications = 0.obs;
  
  // 사용자별 알림 설정
  final RxMap<String, bool> userNotificationSettings = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationSettings();
    _loadNotifications();
  }

  // 알림 설정 로드
  void _loadNotificationSettings() {
    // 실제로는 로컬 저장소나 서버에서 로드
    pushNotificationsEnabled.value = true;
    soundEnabled.value = true;
    vibrationEnabled.value = true;
    showPreview.value = true;
  }

  // 알림 로드
  Future<void> _loadNotifications() async {
    try {
      final notificationsSnapshot = await _firestoreService.getCollectionDocuments('notifications');
      final loadedNotifications = <ChatNotificationModel>[];
      
      for (final snapshot in notificationsSnapshot.docs) {
        final notification = ChatNotificationModel.fromMap(snapshot.data() as Map<String, dynamic>);
        loadedNotifications.add(notification);
      }
      
      notifications.value = loadedNotifications;
      _updateNotificationStats();
      
    } catch (e) {
      print('알림 로드 실패: $e');
    }
  }

  // 알림 통계 업데이트
  void _updateNotificationStats() {
    totalNotifications.value = notifications.length;
    unreadCount.value = notifications.where((n) => n.isUnread).length;
    
    final today = DateTime.now();
    todayNotifications.value = notifications
        .where((n) => n.createdAt.year == today.year &&
                     n.createdAt.month == today.month &&
                     n.createdAt.day == today.day)
        .length;
    
    unreadNotifications.value = notifications.where((n) => n.isUnread).toList();
  }

  // 새 메시지 알림 생성
  Future<void> createMessageNotification({
    required String userId,
    required String chatId,
    required String messageId,
    required String senderName,
    required String messageContent,
  }) async {
    try {
      final notification = ChatNotificationHelper.createMessageNotification(
        userId: userId,
        chatId: chatId,
        messageId: messageId,
        senderName: senderName,
        messageContent: messageContent,
      );
      
      // Firestore에 저장
      await _firestoreService.setDocument('notifications/${notification.notificationId}', notification.toMap());
      
      // 로컬 목록에 추가
      notifications.add(notification);
      _updateNotificationStats();
      
      // 푸시 알림 전송
      if (pushNotificationsEnabled.value) {
        await _sendPushNotification(notification);
      }
      
    } catch (e) {
      print('메시지 알림 생성 실패: $e');
    }
  }

  // 멘션 알림 생성
  Future<void> createMentionNotification({
    required String userId,
    required String chatId,
    required String messageId,
    required String senderName,
    required String messageContent,
  }) async {
    try {
      final notification = ChatNotificationHelper.createMentionNotification(
        userId: userId,
        chatId: chatId,
        messageId: messageId,
        senderName: senderName,
        messageContent: messageContent,
      );
      
      // Firestore에 저장
      await _firestoreService.setDocument('notifications/${notification.notificationId}', notification.toMap());
      
      // 로컬 목록에 추가
      notifications.add(notification);
      _updateNotificationStats();
      
      // 우선순위가 높은 알림이므로 즉시 전송
      if (pushNotificationsEnabled.value) {
        await _sendPushNotification(notification, priority: 'high');
      }
      
    } catch (e) {
      print('멘션 알림 생성 실패: $e');
    }
  }

  // 반응 알림 생성
  Future<void> createReactionNotification({
    required String userId,
    required String chatId,
    required String messageId,
    required String reactorName,
    required String emoji,
  }) async {
    try {
      final notification = ChatNotificationHelper.createReactionNotification(
        userId: userId,
        chatId: chatId,
        messageId: messageId,
        reactorName: reactorName,
        emoji: emoji,
      );
      
      // Firestore에 저장
      await _firestoreService.setDocument('notifications/${notification.notificationId}', notification.toMap());
      
      // 로컬 목록에 추가
      notifications.add(notification);
      _updateNotificationStats();
      
    } catch (e) {
      print('반응 알림 생성 실패: $e');
    }
  }

  // 초대 알림 생성
  Future<void> createInviteNotification({
    required String userId,
    required String chatId,
    required String inviterName,
    required String chatTitle,
  }) async {
    try {
      final notification = ChatNotificationHelper.createInviteNotification(
        userId: userId,
        chatId: chatId,
        inviterName: inviterName,
        chatTitle: chatTitle,
      );
      
      // Firestore에 저장
      await _firestoreService.setDocument('notifications/${notification.notificationId}', notification.toMap());
      
      // 로컬 목록에 추가
      notifications.add(notification);
      _updateNotificationStats();
      
      // 초대는 중요한 알림이므로 즉시 전송
      if (pushNotificationsEnabled.value) {
        await _sendPushNotification(notification, priority: 'high');
      }
      
    } catch (e) {
      print('초대 알림 생성 실패: $e');
    }
  }

  // 시스템 알림 생성
  Future<void> createSystemNotification({
    required String userId,
    required String chatId,
    required String title,
    required String body,
  }) async {
    try {
      final notification = ChatNotificationHelper.createSystemNotification(
        userId: userId,
        chatId: chatId,
        title: title,
        body: body,
      );
      
      // Firestore에 저장
      await _firestoreService.setDocument('notifications/${notification.notificationId}', notification.toMap());
      
      // 로컬 목록에 추가
      notifications.add(notification);
      _updateNotificationStats();
      
    } catch (e) {
      print('시스템 알림 생성 실패: $e');
    }
  }

  // 알림 읽음 표시
  Future<void> markAsRead(String notificationId) async {
    try {
      final notification = notifications.firstWhere((n) => n.notificationId == notificationId);
      final updatedNotification = notification.markAsRead();
      
      // Firestore 업데이트
      await _firestoreService.updateDocument('notifications/$notificationId', {
        'status': updatedNotification.status.value,
        'readAt': updatedNotification.readAt?.toIso8601String(),
      });
      
      // 로컬 목록 업데이트
      final index = notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        notifications[index] = updatedNotification;
        _updateNotificationStats();
      }
      
    } catch (e) {
      print('알림 읽음 표시 실패: $e');
    }
  }

  // 모든 알림 읽음 표시
  Future<void> markAllAsRead() async {
    try {
      for (final notification in unreadNotifications) {
        await markAsRead(notification.notificationId);
      }
    } catch (e) {
      print('모든 알림 읽음 표시 실패: $e');
    }
  }

  // 알림 무시
  Future<void> dismissNotification(String notificationId) async {
    try {
      final notification = notifications.firstWhere((n) => n.notificationId == notificationId);
      final updatedNotification = notification.dismiss();
      
      // Firestore 업데이트
      await _firestoreService.updateDocument('notifications/$notificationId', {
        'status': updatedNotification.status.value,
        'dismissedAt': updatedNotification.dismissedAt?.toIso8601String(),
      });
      
      // 로컬 목록 업데이트
      final index = notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        notifications[index] = updatedNotification;
        _updateNotificationStats();
      }
      
    } catch (e) {
      print('알림 무시 실패: $e');
    }
  }

  // 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Firestore에서 삭제
      await _firestoreService.deleteDocument('notifications/$notificationId');
      
      // 로컬 목록에서 제거
      notifications.removeWhere((n) => n.notificationId == notificationId);
      _updateNotificationStats();
      
    } catch (e) {
      print('알림 삭제 실패: $e');
    }
  }

  // 오래된 알림 정리
  Future<void> cleanupOldNotifications({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final oldNotifications = notifications.where((n) => n.createdAt.isBefore(cutoffDate)).toList();
      
      for (final notification in oldNotifications) {
        await deleteNotification(notification.notificationId);
      }
      
    } catch (e) {
      print('오래된 알림 정리 실패: $e');
    }
  }

  // 푸시 알림 전송 (데모용)
  Future<void> _sendPushNotification(
    ChatNotificationModel notification, {
    String priority = 'normal',
  }) async {
    // 실제로는 푸시 알림 서비스를 사용
    print('푸시 알림 전송: ${notification.title} - ${notification.body}');
    
    // 알림 설정에 따른 처리
    if (soundEnabled.value) {
      print('🔊 알림음 재생');
    }
    
    if (vibrationEnabled.value) {
      print('📳 진동 발생');
    }
    
    if (!showPreview.value) {
      print('🔒 미리보기 숨김');
    }
  }

  // 사용자별 알림 설정 업데이트
  Future<void> updateUserNotificationSettings(String userId, bool enabled) async {
    try {
      userNotificationSettings[userId] = enabled;
      
      // 실제로는 서버에 설정 저장
      print('사용자 $userId 알림 설정: ${enabled ? "활성화" : "비활성화"}');
      
    } catch (e) {
      print('사용자 알림 설정 업데이트 실패: $e');
    }
  }

  // 알림 필터링
  List<ChatNotificationModel> getFilteredNotifications({
    NotificationType? type,
    NotificationStatus? status,
    String? chatId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return notifications.where((notification) {
      if (type != null && notification.type != type) return false;
      if (status != null && notification.status != status) return false;
      if (chatId != null && notification.chatId != chatId) return false;
      if (dateFrom != null && notification.createdAt.isBefore(dateFrom)) return false;
      if (dateTo != null && notification.createdAt.isAfter(dateTo)) return false;
      return true;
    }).toList();
  }

  // 알림 통계 가져오기
  Map<String, dynamic> getNotificationStats() {
    final typeStats = <String, int>{};
    for (final type in NotificationType.values) {
      typeStats[type.value] = notifications.where((n) => n.type == type).length;
    }
    
    return {
      'total': totalNotifications.value,
      'unread': unreadCount.value,
      'today': todayNotifications.value,
      'byType': typeStats,
      'settings': {
        'pushEnabled': pushNotificationsEnabled.value,
        'soundEnabled': soundEnabled.value,
        'vibrationEnabled': vibrationEnabled.value,
        'showPreview': showPreview.value,
      },
    };
  }

  // 알림 설정 토글
  void togglePushNotifications() {
    pushNotificationsEnabled.value = !pushNotificationsEnabled.value;
  }

  void toggleSound() {
    soundEnabled.value = !soundEnabled.value;
  }

  void toggleVibration() {
    vibrationEnabled.value = !vibrationEnabled.value;
  }

  void toggleShowPreview() {
    showPreview.value = !showPreview.value;
  }

  // 알림 서비스 리셋
  void resetService() {
    notifications.clear();
    unreadNotifications.clear();
    totalNotifications.value = 0;
    unreadCount.value = 0;
    todayNotifications.value = 0;
  }
}
