import 'package:get/get.dart';
import 'package:typetalk/services/chat_invite_service.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/services/chat_notification_service.dart';
import 'package:typetalk/models/chat_notification_model.dart' as ChatNotif;

// 통합 알림 관리 서비스
class NotificationService extends GetxController {
  static NotificationService get instance => Get.find<NotificationService>();

  ChatInviteService? get _inviteService => Get.isRegistered<ChatInviteService>() ? Get.find<ChatInviteService>() : null;

  AuthController? get _authController => Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  ChatNotificationService? get _chatNotificationService => Get.isRegistered<ChatNotificationService>() ? Get.find<ChatNotificationService>() : null;

  // 모든 알림 목록
  RxList<NotificationItem> allNotifications = <NotificationItem>[].obs;
  
  // 읽지 않은 알림 개수
  RxInt unreadCount = 0.obs;
  
  // 로딩 상태
  RxBool isLoading = false.obs;

  // 내부 바인딩 상태
  bool _streamsBound = false;

  @override
  void onInit() {
    super.onInit();
    // 알림 목록 로드
    loadAllNotifications();
    // 로그인 상태 변화에 반응하여 알림 로드/스트림 바인딩
    _setupAuthBinding();
    // 앱 시작 시 이미 로그인되어 있으면 즉시 바인딩 및 로드
    final auth = _authController;
    if (auth != null && auth.isLoggedIn) {
      _bindStreamsOnce();
    }
  }

  /// 모든 알림 로드
  Future<void> loadAllNotifications() async {
    try {
      isLoading.value = true;
      
      final authController = _authController;
      if (authController == null) return;
      
      final currentUserId = authController.currentUserId.value;
      if (currentUserId.isEmpty) return;

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
              'source': 'invite',
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
      final chatService = _chatNotificationService;
      if (chatService == null) return;
      // 기존 채팅 소스 알림 제거 후 재적재
      allNotifications.removeWhere((n) => n.data['source'] == 'chat');
      for (final n in chatService.notifications) {
        if (n.userId != userId) continue;
        if (n.status == ChatNotif.NotificationStatus.dismissed) continue;
        allNotifications.add(_mapChatNotificationToItem(n));
      }
    } catch (e) {
      print('채팅 알림 로드 실패: $e');
    }
  }

  // 로그인 상태 바인딩 설정
  void _setupAuthBinding() {
    final auth = _authController;
    if (auth == null) return;
    ever<String>(auth.currentUserId, (uid) async {
      if (uid.isNotEmpty) {
        try {
          await _inviteService?.loadInvites();
        } catch (_) {}
        _bindStreamsOnce();
        await refreshNotifications();
      } else {
        allNotifications.clear();
        _updateUnreadCount();
      }
    });
  }

  // 서비스 스트림을 한 번만 바인딩
  void _bindStreamsOnce() {
    if (_streamsBound) return;
    _streamsBound = true;
    final inviteService = _inviteService;
    if (inviteService != null) {
      ever(inviteService.receivedInvites, (_) {
        _rebuildInviteNotifications();
      });
    }
    final chatService = _chatNotificationService;
    if (chatService != null) {
      ever(chatService.notifications, (_) {
        _rebuildChatNotifications();
      });
    }
  }

  // 초대 알림을 스트림 변경에 맞춰 재구성
  void _rebuildInviteNotifications() {
    final inviteService = _inviteService;
    final auth = _authController;
    if (inviteService == null || auth?.userId == null) return;
    allNotifications.removeWhere((n) => n.type == NotificationType.chatInvite && n.data['source'] == 'invite');
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
            'source': 'invite',
          },
        ));
      }
    }
    _sortNotifications();
    _updateUnreadCount();
  }

  // 채팅 알림을 스트림 변경에 맞춰 재구성
  void _rebuildChatNotifications() {
    final chatService = _chatNotificationService;
    final auth = _authController;
    final userId = auth?.userId;
    if (chatService == null || userId == null) return;
    allNotifications.removeWhere((n) => n.data['source'] == 'chat');
    for (final n in chatService.notifications) {
      if (n.userId != userId) continue;
      if (n.status == ChatNotif.NotificationStatus.dismissed) continue;
      allNotifications.add(_mapChatNotificationToItem(n));
    }
    _sortNotifications();
    _updateUnreadCount();
  }

  // ChatNotificationModel -> NotificationItem 매핑
  NotificationItem _mapChatNotificationToItem(ChatNotif.ChatNotificationModel n) {
    final mappedType = _mapType(n.type);
    return NotificationItem(
      id: 'chat_${n.notificationId}',
      type: mappedType,
      title: n.title,
      message: n.body,
      timestamp: n.createdAt,
      isRead: n.status != ChatNotif.NotificationStatus.unread,
      data: {
        'chatNotificationId': n.notificationId,
        'chatId': n.chatId,
        'source': 'chat',
        'rawType': n.type.value,
      },
    );
  }

  // 외부 알림 타입을 내부 타입으로 변환
  NotificationType _mapType(ChatNotif.NotificationType t) {
    switch (t) {
      case ChatNotif.NotificationType.invite:
      case ChatNotif.NotificationType.chatInvite:
        return NotificationType.chatInvite;
      case ChatNotif.NotificationType.message:
      case ChatNotif.NotificationType.chatMessage:
      case ChatNotif.NotificationType.mention:
      case ChatNotif.NotificationType.reaction:
        return NotificationType.chatMessage;
      case ChatNotif.NotificationType.system:
        return NotificationType.system;
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
        // 채팅 알림이면 원본 서비스에도 읽음 반영
        final chatId = notification.data['chatNotificationId'];
        if (chatId != null) {
          try {
            await _chatNotificationService?.markAsRead(chatId);
          } catch (_) {}
        }
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
      try {
        await _chatNotificationService?.markAllAsRead();
      } catch (_) {}
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
