import 'package:typetalk/services/firestore_service.dart';

// 알림 타입 열거형
enum NotificationType {
  message('message'),
  mention('mention'),
  reaction('reaction'),
  invite('invite'),
  system('system');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.message,
    );
  }
}

// 알림 상태 열거형
enum NotificationStatus {
  unread('unread'),
  read('read'),
  dismissed('dismissed');

  const NotificationStatus(this.value);
  final String value;

  static NotificationStatus fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => NotificationStatus.unread,
    );
  }
}

// 알림 메타데이터 모델
class NotificationMetadata {
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic>? customData;
  final int? badgeCount;

  const NotificationMetadata({
    this.imageUrl,
    this.actionUrl,
    this.customData,
    this.badgeCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'customData': customData,
      'badgeCount': badgeCount,
    };
  }

  factory NotificationMetadata.fromMap(Map<String, dynamic> map) {
    return NotificationMetadata(
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
      customData: map['customData'] != null 
          ? Map<String, dynamic>.from(map['customData'])
          : null,
      badgeCount: map['badgeCount'],
    );
  }

  NotificationMetadata copyWith({
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? customData,
    int? badgeCount,
  }) {
    return NotificationMetadata(
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      customData: customData ?? this.customData,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }
}

// 메인 채팅 알림 모델
class ChatNotificationModel {
  final String notificationId;
  final String userId;
  final String chatId;
  final String? messageId;
  final NotificationType type;
  final String title;
  final String body;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final NotificationMetadata metadata;

  ChatNotificationModel({
    required this.notificationId,
    required this.userId,
    required this.chatId,
    this.messageId,
    required this.type,
    required this.title,
    required this.body,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.readAt,
    this.dismissedAt,
    this.metadata = const NotificationMetadata(),
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'chatId': chatId,
      'messageId': messageId,
      'type': type.value,
      'title': title,
      'body': body,
      'status': status.value,
      'createdAt': createdAt,
      'readAt': readAt,
      'dismissedAt': dismissedAt,
      'metadata': metadata.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory ChatNotificationModel.fromMap(Map<String, dynamic> map) {
    return ChatNotificationModel(
      notificationId: map['notificationId'] ?? '',
      userId: map['userId'] ?? '',
      chatId: map['chatId'] ?? '',
      messageId: map['messageId'],
      type: NotificationType.fromString(map['type'] ?? 'message'),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      status: NotificationStatus.fromString(map['status'] ?? 'unread'),
      createdAt: _parseDateTime(map['createdAt']),
      readAt: map['readAt'] != null ? _parseDateTime(map['readAt']) : null,
      dismissedAt: map['dismissedAt'] != null ? _parseDateTime(map['dismissedAt']) : null,
      metadata: map['metadata'] != null 
          ? NotificationMetadata.fromMap(map['metadata']) 
          : NotificationMetadata(),
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

  // Firestore 문서 스냅샷에서 생성
  factory ChatNotificationModel.fromSnapshot(DemoDocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      throw Exception('알림 문서가 존재하지 않습니다.');
    }
    return ChatNotificationModel.fromMap(snapshot.data);
  }

  // 알림 정보 업데이트
  ChatNotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? chatId,
    String? messageId,
    NotificationType? type,
    String? title,
    String? body,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    NotificationMetadata? metadata,
  }) {
    return ChatNotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // 읽음 표시
  ChatNotificationModel markAsRead() {
    return copyWith(
      status: NotificationStatus.read,
      readAt: DateTime.now(),
    );
  }

  // 무시됨 표시
  ChatNotificationModel dismiss() {
    return copyWith(
      status: NotificationStatus.dismissed,
      dismissedAt: DateTime.now(),
    );
  }

  // 읽지 않은 알림인지 확인
  bool get isUnread => status == NotificationStatus.unread;

  // 읽은 알림인지 확인
  bool get isRead => status == NotificationStatus.read;

  // 무시된 알림인지 확인
  bool get isDismissed => status == NotificationStatus.dismissed;

  // 메시지 알림인지 확인
  bool get isMessageNotification => type == NotificationType.message;

  // 멘션 알림인지 확인
  bool get isMentionNotification => type == NotificationType.mention;

  // 반응 알림인지 확인
  bool get isReactionNotification => type == NotificationType.reaction;

  // 초대 알림인지 확인
  bool get isInviteNotification => type == NotificationType.invite;

  // 시스템 알림인지 확인
  bool get isSystemNotification => type == NotificationType.system;

  // 알림 생성 후 경과 시간
  Duration get age => DateTime.now().difference(createdAt);

  // 알림이 오래되었는지 확인 (24시간)
  bool get isOld => age.inHours > 24;

  @override
  String toString() {
    return 'ChatNotificationModel(notificationId: $notificationId, type: ${type.value}, status: ${status.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatNotificationModel && other.notificationId == notificationId;
  }

  @override
  int get hashCode => notificationId.hashCode;
}

// 채팅 알림 생성 도우미 클래스
class ChatNotificationHelper {
  // 새 메시지 알림 생성
  static ChatNotificationModel createMessageNotification({
    required String userId,
    required String chatId,
    required String messageId,
    required String senderName,
    required String messageContent,
  }) {
    final notificationId = 'notif_${userId}_${messageId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatNotificationModel(
      notificationId: notificationId,
      userId: userId,
      chatId: chatId,
      messageId: messageId,
      type: NotificationType.message,
      title: '$senderName님이 메시지를 보냈습니다',
      body: messageContent.length > 50 
          ? '${messageContent.substring(0, 50)}...' 
          : messageContent,
      createdAt: DateTime.now(),
    );
  }

  // 멘션 알림 생성
  static ChatNotificationModel createMentionNotification({
    required String userId,
    required String chatId,
    required String messageId,
    required String senderName,
    required String messageContent,
  }) {
    final notificationId = 'notif_mention_${userId}_${messageId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatNotificationModel(
      notificationId: notificationId,
      userId: userId,
      chatId: chatId,
      messageId: messageId,
      type: NotificationType.mention,
      title: '$senderName님이 당신을 멘션했습니다',
      body: messageContent.length > 50 
          ? '${messageContent.substring(0, 50)}...' 
          : messageContent,
      createdAt: DateTime.now(),
    );
  }

  // 반응 알림 생성
  static ChatNotificationModel createReactionNotification({
    required String userId,
    required String chatId,
    required String messageId,
    required String reactorName,
    required String emoji,
  }) {
    final notificationId = 'notif_reaction_${userId}_${messageId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatNotificationModel(
      notificationId: notificationId,
      userId: userId,
      chatId: chatId,
      messageId: messageId,
      type: NotificationType.reaction,
      title: '$reactorName님이 반응했습니다',
      body: '$emoji 반응을 받았습니다',
      createdAt: DateTime.now(),
    );
  }

  // 초대 알림 생성
  static ChatNotificationModel createInviteNotification({
    required String userId,
    required String chatId,
    required String inviterName,
    required String chatTitle,
  }) {
    final notificationId = 'notif_invite_${userId}_${chatId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatNotificationModel(
      notificationId: notificationId,
      userId: userId,
      chatId: chatId,
      type: NotificationType.invite,
      title: '$inviterName님이 초대했습니다',
      body: '$chatTitle 채팅방에 초대되었습니다',
      createdAt: DateTime.now(),
    );
  }

  // 시스템 알림 생성
  static ChatNotificationModel createSystemNotification({
    required String userId,
    required String chatId,
    required String title,
    required String body,
  }) {
    final notificationId = 'notif_system_${userId}_${chatId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatNotificationModel(
      notificationId: notificationId,
      userId: userId,
      chatId: chatId,
      type: NotificationType.system,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
  }
}
