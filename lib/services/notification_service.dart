import 'package:get/get.dart';
import 'package:typetalk/services/chat_invite_service.dart';
import 'package:typetalk/controllers/auth_controller.dart';

// 통합 알림 관리 서비스
class NotificationService extends GetxController {
  static NotificationService get instance => Get.find<NotificationService>();

  ChatInviteService? get _inviteService => Get.isRegistered<ChatInviteService>() ? Get.find<ChatInviteService>() : null;

  AuthController? get _authController => Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  // 모든 알림 목록
  RxList<NotificationItem> allNotifications = <NotificationItem>[].obs;
  
  // 읽지 않은 알림 개수
  RxInt unreadCount = 0.obs;
  
  // 로딩 상태
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 알림 목록 로드
    loadAllNotifications();
  }

  /// 모든 알림 로드
  Future<void> loadAllNotifications() async {
    try {
      isLoading.value = true;
      
      final authController = _authController;
      if (authController == null) return;
      
      final currentUserId = authController.userId;
      if (currentUserId == null) return;

      // 채팅 초대 알림 로드
      await _loadInviteNotifications(currentUserId);
      
      // 채팅 알림 로드
      await _loadChatNotifications(currentUserId);
      
      // 알림 정렬 (최신순)
      _sortNotifications();
      
      // 읽지 않은 알림 개수 계산
      _updateUnreadCount();
      
    } catch (e) {
      print('알림 로드 실패: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 채팅 초대 알림 로드
  Future<void> _loadInviteNotifications(String userId) async {
    try {
      final inviteService = _inviteService;
      if (inviteService == null) return;
      
      // 받은 초대 알림
      for (final invite in inviteService.receivedInvites) {
        if (invite.isPending) {
          allNotifications.add(NotificationItem(
            id: 'invite_${invite.inviteId}',
            type: NotificationType.chatInvite,
            title: '새로운 채팅 초대',
                         message: invite.metadata.message ?? '안녕하세요! 대화를 나누고 싶어요.',
            timestamp: invite.createdAt,
            isRead: false,
            data: {
              'inviteId': invite.inviteId,
              'chatId': invite.chatId,
              'fromUserId': invite.invitedBy,
            },
          ));
        }
      }
    } catch (e) {
      print('초대 알림 로드 실패: $e');
    }
  }

  /// 채팅 알림 로드
  Future<void> _loadChatNotifications(String userId) async {
    try {
      // 채팅 알림이 있다면 추가
      // 실제 구현에서는 ChatNotificationService에서 알림 데이터를 가져와야 함
      // 현재는 예시로 추가
    } catch (e) {
      print('채팅 알림 로드 실패: $e');
    }
  }

  /// 알림 정렬 (최신순)
  void _sortNotifications() {
    allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 읽지 않은 알림 개수 업데이트
  void _updateUnreadCount() {
    unreadCount.value = allNotifications.where((notification) => !notification.isRead).length;
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    try {
      final notification = allNotifications.firstWhereOrNull((n) => n.id == notificationId);
      if (notification != null) {
        notification.isRead = true;
        _updateUnreadCount();
      }
    } catch (e) {
      print('알림 읽음 처리 실패: $e');
    }
  }

  /// 모든 알림 읽음 처리
  Future<void> markAllAsRead() async {
    try {
      for (final notification in allNotifications) {
        notification.isRead = true;
      }
      _updateUnreadCount();
    } catch (e) {
      print('모든 알림 읽음 처리 실패: $e');
    }
  }

  /// 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      allNotifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
    } catch (e) {
      print('알림 삭제 실패: $e');
    }
  }

  /// 새 알림 추가
  void addNotification(NotificationItem notification) {
    allNotifications.insert(0, notification);
    _updateUnreadCount();
  }

  /// 알림 새로고침
  Future<void> refreshNotifications() async {
    allNotifications.clear();
    await loadAllNotifications();
  }

  /// 특정 타입의 알림만 가져오기
  List<NotificationItem> getNotificationsByType(NotificationType type) {
    return allNotifications.where((n) => n.type == type).toList();
  }

  /// 오늘 받은 알림 개수
  int get todayNotificationCount {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return allNotifications
        .where((n) => n.timestamp.isAfter(startOfDay))
        .length;
  }

  /// 이번 주 받은 알림 개수
  int get thisWeekNotificationCount {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return allNotifications
        .where((n) => n.timestamp.isAfter(startOfWeekDay))
        .length;
  }
}

// 알림 타입 열거형
enum NotificationType {
  chatInvite('chat_invite'),
  chatMessage('chat_message'),
  system('system'),
  friendRequest('friend_request');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

// 알림 아이템 모델
class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic> data;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'data': data,
    };
  }

  // Firestore 문서에서 생성
  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      type: NotificationType.fromString(map['type'] ?? 'system'),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: _parseDateTime(map['timestamp']),
      isRead: map['isRead'] ?? false,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : {},
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // 알림 읽음 처리
  void markAsRead() {
    isRead = true;
  }

  // 알림이 오늘 받은 것인지 확인
  bool get isToday {
    final today = DateTime.now();
    return timestamp.year == today.year &&
           timestamp.month == today.month &&
           timestamp.day == today.day;
  }

  // 알림이 어제 받은 것인지 확인
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
           timestamp.month == yesterday.month &&
           timestamp.day == yesterday.day;
  }

  // 상대적 시간 표시
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  // 알림 아이콘
  String get icon {
    switch (type) {
      case NotificationType.chatInvite:
        return '💬';
      case NotificationType.chatMessage:
        return '📱';
      case NotificationType.system:
        return '🔔';
      case NotificationType.friendRequest:
        return '👥';
    }
  }

  // 알림 색상
  String get color {
    switch (type) {
      case NotificationType.chatInvite:
        return '#FF9800'; // 주황색
      case NotificationType.chatMessage:
        return '#2196F3'; // 파란색
      case NotificationType.system:
        return '#4CAF50'; // 초록색
      case NotificationType.friendRequest:
        return '#9C27B0'; // 보라색
    }
  }
}
