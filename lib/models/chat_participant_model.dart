import 'package:typetalk/services/firestore_service.dart';

// 참여자 역할 열거형
enum ParticipantRole {
  admin('admin'),
  moderator('moderator'),
  member('member');

  const ParticipantRole(this.value);
  final String value;

  static ParticipantRole fromString(String value) {
    return ParticipantRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ParticipantRole.member,
    );
  }
}

// 참여자 상태 모델
class ParticipantStatus {
  final bool isActive;
  final bool isMuted;
  final String? lastReadMessageId;
  final DateTime lastSeenAt;
  final bool isTyping;

  ParticipantStatus({
    this.isActive = true,
    this.isMuted = false,
    this.lastReadMessageId,
    required this.lastSeenAt,
    this.isTyping = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'isMuted': isMuted,
      'lastReadMessageId': lastReadMessageId,
      'lastSeenAt': lastSeenAt,
      'isTyping': isTyping,
    };
  }

  factory ParticipantStatus.fromMap(Map<String, dynamic> map) {
    return ParticipantStatus(
      isActive: map['isActive'] ?? true,
      isMuted: map['isMuted'] ?? false,
      lastReadMessageId: map['lastReadMessageId'],
      lastSeenAt: _parseDateTime(map['lastSeenAt']),
      isTyping: map['isTyping'] ?? false,
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

  ParticipantStatus copyWith({
    bool? isActive,
    bool? isMuted,
    String? lastReadMessageId,
    DateTime? lastSeenAt,
    bool? isTyping,
  }) {
    return ParticipantStatus(
      isActive: isActive ?? this.isActive,
      isMuted: isMuted ?? this.isMuted,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  // 읽음 표시 업데이트
  ParticipantStatus updateLastRead(String messageId) {
    return copyWith(
      lastReadMessageId: messageId,
      lastSeenAt: DateTime.now(),
    );
  }

  // 타이핑 상태 업데이트
  ParticipantStatus setTyping(bool typing) {
    return copyWith(isTyping: typing);
  }

  // 음소거 상태 토글
  ParticipantStatus toggleMute() {
    return copyWith(isMuted: !isMuted);
  }

  // 활성 상태 업데이트
  ParticipantStatus setActive(bool active) {
    return copyWith(
      isActive: active,
      lastSeenAt: DateTime.now(),
    );
  }
}

// 참여자 설정 모델
class ParticipantSettings {
  final bool notifications;
  final String? nickname;
  final bool showMBTI;
  final bool showOnlineStatus;

  ParticipantSettings({
    this.notifications = true,
    this.nickname,
    this.showMBTI = true,
    this.showOnlineStatus = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'notifications': notifications,
      'nickname': nickname,
      'showMBTI': showMBTI,
      'showOnlineStatus': showOnlineStatus,
    };
  }

  factory ParticipantSettings.fromMap(Map<String, dynamic> map) {
    return ParticipantSettings(
      notifications: map['notifications'] ?? true,
      nickname: map['nickname'],
      showMBTI: map['showMBTI'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
    );
  }

  ParticipantSettings copyWith({
    bool? notifications,
    String? nickname,
    bool? showMBTI,
    bool? showOnlineStatus,
  }) {
    return ParticipantSettings(
      notifications: notifications ?? this.notifications,
      nickname: nickname ?? this.nickname,
      showMBTI: showMBTI ?? this.showMBTI,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
    );
  }
}

// 참여자 통계 모델
class ParticipantStats {
  final int messageCount;
  final int reactionsGiven;
  final int reactionsReceived;
  final int filesShared;
  final DateTime firstMessageAt;
  final DateTime lastMessageAt;

  ParticipantStats({
    this.messageCount = 0,
    this.reactionsGiven = 0,
    this.reactionsReceived = 0,
    this.filesShared = 0,
    DateTime? firstMessageAt,
    DateTime? lastMessageAt,
  }) : 
    firstMessageAt = firstMessageAt ?? DateTime.now(),
    lastMessageAt = lastMessageAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'messageCount': messageCount,
      'reactionsGiven': reactionsGiven,
      'reactionsReceived': reactionsReceived,
      'filesShared': filesShared,
      'firstMessageAt': firstMessageAt,
      'lastMessageAt': lastMessageAt,
    };
  }

  factory ParticipantStats.fromMap(Map<String, dynamic> map) {
    return ParticipantStats(
      messageCount: map['messageCount'] ?? 0,
      reactionsGiven: map['reactionsGiven'] ?? 0,
      reactionsReceived: map['reactionsReceived'] ?? 0,
      filesShared: map['filesShared'] ?? 0,
      firstMessageAt: _parseDateTime(map['firstMessageAt']),
      lastMessageAt: _parseDateTime(map['lastMessageAt']),
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

  ParticipantStats copyWith({
    int? messageCount,
    int? reactionsGiven,
    int? reactionsReceived,
    int? filesShared,
    DateTime? firstMessageAt,
    DateTime? lastMessageAt,
  }) {
    return ParticipantStats(
      messageCount: messageCount ?? this.messageCount,
      reactionsGiven: reactionsGiven ?? this.reactionsGiven,
      reactionsReceived: reactionsReceived ?? this.reactionsReceived,
      filesShared: filesShared ?? this.filesShared,
      firstMessageAt: firstMessageAt ?? this.firstMessageAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  // 메시지 수 증가
  ParticipantStats incrementMessageCount() {
    return copyWith(
      messageCount: messageCount + 1,
      lastMessageAt: DateTime.now(),
    );
  }

  // 반응 수 증가
  ParticipantStats incrementReactionsGiven() {
    return copyWith(reactionsGiven: reactionsGiven + 1);
  }

  ParticipantStats incrementReactionsReceived() {
    return copyWith(reactionsReceived: reactionsReceived + 1);
  }

  // 파일 공유 수 증가
  ParticipantStats incrementFilesShared() {
    return copyWith(filesShared: filesShared + 1);
  }
}

// 메인 채팅 참여자 모델
class ChatParticipantModel {
  final String participantId;
  final String chatId;
  final String userId;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final ParticipantStatus status;
  final ParticipantSettings settings;
  final ParticipantStats stats;

  ChatParticipantModel({
    required this.participantId,
    required this.chatId,
    required this.userId,
    this.role = ParticipantRole.member,
    required this.joinedAt,
    this.leftAt,
    required this.status,
    required this.settings,
    required this.stats,
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'chatId': chatId,
      'userId': userId,
      'role': role.value,
      'joinedAt': joinedAt,
      'leftAt': leftAt,
      'status': status.toMap(),
      'settings': settings.toMap(),
      'stats': stats.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory ChatParticipantModel.fromMap(Map<String, dynamic> map) {
    return ChatParticipantModel(
      participantId: map['participantId'] ?? '',
      chatId: map['chatId'] ?? '',
      userId: map['userId'] ?? '',
      role: ParticipantRole.fromString(map['role'] ?? 'member'),
      joinedAt: _parseDateTime(map['joinedAt']),
      leftAt: map['leftAt'] != null ? _parseDateTime(map['leftAt']) : null,
      status: map['status'] != null 
          ? ParticipantStatus.fromMap(map['status']) 
          : ParticipantStatus(lastSeenAt: DateTime.now()),
      settings: map['settings'] != null 
          ? ParticipantSettings.fromMap(map['settings']) 
          : ParticipantSettings(),
      stats: map['stats'] != null 
          ? ParticipantStats.fromMap(map['stats']) 
          : ParticipantStats(),
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
  factory ChatParticipantModel.fromSnapshot(dynamic snapshot) {
    if (!snapshot.exists) {
      throw Exception('참여자 문서가 존재하지 않습니다.');
    }
    return ChatParticipantModel.fromMap(snapshot.data());
  }

  // 참여자 정보 업데이트
  ChatParticipantModel copyWith({
    String? participantId,
    String? chatId,
    String? userId,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    ParticipantStatus? status,
    ParticipantSettings? settings,
    ParticipantStats? stats,
  }) {
    return ChatParticipantModel(
      participantId: participantId ?? this.participantId,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
    );
  }

  // 역할 변경
  ChatParticipantModel changeRole(ParticipantRole newRole) {
    return copyWith(role: newRole);
  }

  // 채팅방 나가기
  ChatParticipantModel leave() {
    return copyWith(
      leftAt: DateTime.now(),
      status: status.setActive(false),
    );
  }

  // 읽음 표시 업데이트
  ChatParticipantModel updateLastRead(String messageId) {
    return copyWith(
      status: status.updateLastRead(messageId),
    );
  }

  // 타이핑 상태 업데이트
  ChatParticipantModel setTyping(bool typing) {
    return copyWith(
      status: status.setTyping(typing),
    );
  }

  // 메시지 수 증가
  ChatParticipantModel incrementMessageCount() {
    return copyWith(
      stats: stats.incrementMessageCount(),
    );
  }

  // 반응 수 증가
  ChatParticipantModel incrementReactionsGiven() {
    return copyWith(
      stats: stats.incrementReactionsGiven(),
    );
  }

  ChatParticipantModel incrementReactionsReceived() {
    return copyWith(
      stats: stats.incrementReactionsReceived(),
    );
  }

  // 파일 공유 수 증가
  ChatParticipantModel incrementFilesShared() {
    return copyWith(
      stats: stats.incrementFilesShared(),
    );
  }

  // 관리자인지 확인
  bool get isAdmin => role == ParticipantRole.admin;

  // 중재자인지 확인
  bool get isModerator => role == ParticipantRole.moderator || role == ParticipantRole.admin;

  // 활성 상태인지 확인
  bool get isActive => status.isActive && leftAt == null;

  // 음소거 상태인지 확인
  bool get isMuted => status.isMuted;

  // 타이핑 중인지 확인
  bool get isTyping => status.isTyping;

  // 채팅방을 나간 상태인지 확인
  bool get hasLeft => leftAt != null;

  // 참여 기간
  Duration get participationDuration {
    final endTime = leftAt ?? DateTime.now();
    return endTime.difference(joinedAt);
  }

  @override
  String toString() {
    return 'ChatParticipantModel(userId: $userId, role: ${role.value}, chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParticipantModel && other.participantId == participantId;
  }

  @override
  int get hashCode => participantId.hashCode;
}

// 채팅 참여자 생성 도우미 클래스
class ChatParticipantHelper {
  // 새로운 참여자 생성
  static ChatParticipantModel createParticipant({
    required String chatId,
    required String userId,
    ParticipantRole role = ParticipantRole.member,
    ParticipantSettings? settings,
  }) {
    final participantId = 'participant_${chatId}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatParticipantModel(
      participantId: participantId,
      chatId: chatId,
      userId: userId,
      role: role,
      joinedAt: DateTime.now(),
      status: ParticipantStatus(lastSeenAt: DateTime.now()),
      settings: settings ?? ParticipantSettings(),
      stats: ParticipantStats(),
    );
  }

  // 채팅방 생성자 (관리자) 생성
  static ChatParticipantModel createCreator({
    required String chatId,
    required String userId,
    ParticipantSettings? settings,
  }) {
    return createParticipant(
      chatId: chatId,
      userId: userId,
      role: ParticipantRole.admin,
      settings: settings,
    );
  }

  // 중재자 생성
  static ChatParticipantModel createModerator({
    required String chatId,
    required String userId,
    ParticipantSettings? settings,
  }) {
    return createParticipant(
      chatId: chatId,
      userId: userId,
      role: ParticipantRole.moderator,
      settings: settings,
    );
  }
}
