import 'package:typetalk/services/firestore_service.dart';

// 초대 상태 열거형
enum InviteStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired'),
  cancelled('cancelled');

  const InviteStatus(this.value);
  final String value;

  static InviteStatus fromString(String value) {
    return InviteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InviteStatus.pending,
    );
  }
}

// 초대 타입 열거형
enum InviteType {
  direct('direct'),      // 직접 초대
  link('link'),         // 링크 초대
  recommendation('recommendation'); // 추천 기반 초대

  const InviteType(this.value);
  final String value;

  static InviteType fromString(String value) {
    return InviteType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InviteType.direct,
    );
  }
}

// 초대 메타데이터 모델
class InviteMetadata {
  final String? message;
  final String? inviteCode;
  final DateTime? expiresAt;
  final int? maxUses;
  final int currentUses;
  final List<String>? allowedMBTI;
  final bool requireApproval;

  InviteMetadata({
    this.message,
    this.inviteCode,
    this.expiresAt,
    this.maxUses,
    this.currentUses = 0,
    this.allowedMBTI,
    this.requireApproval = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'inviteCode': inviteCode,
      'expiresAt': expiresAt,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'allowedMBTI': allowedMBTI,
      'requireApproval': requireApproval,
    };
  }

  factory InviteMetadata.fromMap(Map<String, dynamic> map) {
    return InviteMetadata(
      message: map['message'],
      inviteCode: map['inviteCode'],
      expiresAt: map['expiresAt'] != null ? _parseDateTime(map['expiresAt']) : null,
      maxUses: map['maxUses'],
      currentUses: map['currentUses'] ?? 0,
      allowedMBTI: map['allowedMBTI'] != null 
          ? List<String>.from(map['allowedMBTI']) 
          : null,
      requireApproval: map['requireApproval'] ?? false,
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

  InviteMetadata copyWith({
    String? message,
    String? inviteCode,
    DateTime? expiresAt,
    int? maxUses,
    int? currentUses,
    List<String>? allowedMBTI,
    bool? requireApproval,
  }) {
    return InviteMetadata(
      message: message ?? this.message,
      inviteCode: inviteCode ?? this.inviteCode,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      allowedMBTI: allowedMBTI ?? this.allowedMBTI,
      requireApproval: requireApproval ?? this.requireApproval,
    );
  }

  // 사용 횟수 증가
  InviteMetadata incrementUses() {
    return copyWith(currentUses: currentUses + 1);
  }

  // 초대가 만료되었는지 확인
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // 초대가 사용 제한에 도달했는지 확인
  bool get isUsageLimitReached {
    if (maxUses == null) return false;
    return currentUses >= maxUses!;
  }

  // 초대가 유효한지 확인
  bool get isValid => !isExpired && !isUsageLimitReached;

  // MBTI 제한이 있는지 확인
  bool get hasMBTIRestriction => allowedMBTI != null && allowedMBTI!.isNotEmpty;

  // 특정 MBTI가 허용되는지 확인
  bool isMBTIAllowed(String mbti) {
    if (!hasMBTIRestriction) return true;
    return allowedMBTI!.contains(mbti);
  }
}

// 메인 채팅 초대 모델
class ChatInviteModel {
  final String inviteId;
  final String chatId;
  final String invitedBy;
  final String? invitedUserId;
  final String? invitedUserEmail;
  final InviteType type;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final InviteMetadata metadata;

  ChatInviteModel({
    required this.inviteId,
    required this.chatId,
    required this.invitedBy,
    this.invitedUserId,
    this.invitedUserEmail,
    this.type = InviteType.direct,
    this.status = InviteStatus.pending,
    required this.createdAt,
    this.respondedAt,
    required this.metadata,
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'inviteId': inviteId,
      'chatId': chatId,
      'invitedBy': invitedBy,
      'invitedUserId': invitedUserId,
      'invitedUserEmail': invitedUserEmail,
      'type': type.value,
      'status': status.value,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
      'metadata': metadata.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory ChatInviteModel.fromMap(Map<String, dynamic> map) {
    return ChatInviteModel(
      inviteId: map['inviteId'] ?? '',
      chatId: map['chatId'] ?? '',
      invitedBy: map['invitedBy'] ?? '',
      invitedUserId: map['invitedUserId'],
      invitedUserEmail: map['invitedUserEmail'],
      type: InviteType.fromString(map['type'] ?? 'direct'),
      status: InviteStatus.fromString(map['status'] ?? 'pending'),
      createdAt: _parseDateTime(map['createdAt']),
      respondedAt: map['respondedAt'] != null ? _parseDateTime(map['respondedAt']) : null,
      metadata: map['metadata'] != null 
          ? InviteMetadata.fromMap(map['metadata']) 
          : InviteMetadata(),
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
  factory ChatInviteModel.fromSnapshot(dynamic snapshot) {
    if (!snapshot.exists) {
      throw Exception('초대 문서가 존재하지 않습니다.');
    }
    return ChatInviteModel.fromMap(snapshot.data());
  }

  // 초대 정보 업데이트
  ChatInviteModel copyWith({
    String? inviteId,
    String? chatId,
    String? invitedBy,
    String? invitedUserId,
    String? invitedUserEmail,
    InviteType? type,
    InviteStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    InviteMetadata? metadata,
  }) {
    return ChatInviteModel(
      inviteId: inviteId ?? this.inviteId,
      chatId: chatId ?? this.chatId,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // 초대 수락
  ChatInviteModel accept() {
    return copyWith(
      status: InviteStatus.accepted,
      respondedAt: DateTime.now(),
      metadata: metadata.incrementUses(),
    );
  }

  // 초대 거절
  ChatInviteModel decline() {
    return copyWith(
      status: InviteStatus.declined,
      respondedAt: DateTime.now(),
    );
  }

  // 초대 취소
  ChatInviteModel cancel() {
    return copyWith(
      status: InviteStatus.cancelled,
      respondedAt: DateTime.now(),
    );
  }

  // 초대 만료
  ChatInviteModel expire() {
    return copyWith(
      status: InviteStatus.expired,
      respondedAt: DateTime.now(),
    );
  }

  // 사용자 ID 설정
  ChatInviteModel setInvitedUserId(String userId) {
    return copyWith(invitedUserId: userId);
  }

  // 이메일 초대인지 확인
  bool get isEmailInvite => invitedUserEmail != null && invitedUserId == null;

  // 사용자 ID 초대인지 확인
  bool get isUserInvite => invitedUserId != null;

  // 링크 초대인지 확인
  bool get isLinkInvite => type == InviteType.link;

  // 직접 초대인지 확인
  bool get isDirectInvite => type == InviteType.direct;

  // 추천 기반 초대인지 확인
  bool get isRecommendationInvite => type == InviteType.recommendation;

  // 대기 중인 초대인지 확인
  bool get isPending => status == InviteStatus.pending;

  // 수락된 초대인지 확인
  bool get isAccepted => status == InviteStatus.accepted;

  // 거절된 초대인지 확인
  bool get isDeclined => status == InviteStatus.declined;

  // 취소된 초대인지 확인
  bool get isCancelled => status == InviteStatus.cancelled;

  // 만료된 초대인지 확인
  bool get isExpired => status == InviteStatus.expired;

  // 응답된 초대인지 확인
  bool get isResponded => respondedAt != null;

  // 초대가 유효한지 확인
  bool get isValid => metadata.isValid && isPending;

  // 초대 메시지가 있는지 확인
  bool get hasMessage => metadata.message != null && metadata.message!.isNotEmpty;

  // 초대 코드가 있는지 확인
  bool get hasInviteCode => metadata.inviteCode != null;

  // 사용 제한이 있는지 확인
  bool get hasUsageLimit => metadata.maxUses != null;

  // MBTI 제한이 있는지 확인
  bool get hasMBTIRestriction => metadata.hasMBTIRestriction;

  // 승인이 필요한지 확인
  bool get requiresApproval => metadata.requireApproval;

  @override
  String toString() {
    return 'ChatInviteModel(inviteId: $inviteId, chatId: $chatId, status: ${status.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatInviteModel && other.inviteId == inviteId;
  }

  @override
  int get hashCode => inviteId.hashCode;
}

// 채팅 초대 생성 도우미 클래스
class ChatInviteHelper {
  // 직접 사용자 초대 생성
  static ChatInviteModel createDirectUserInvite({
    required String chatId,
    required String invitedBy,
    required String invitedUserId,
    String? message,
    List<String>? allowedMBTI,
    bool requireApproval = false,
  }) {
    final inviteId = 'invite_${chatId}_${invitedUserId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatInviteModel(
      inviteId: inviteId,
      chatId: chatId,
      invitedBy: invitedBy,
      invitedUserId: invitedUserId,
      type: InviteType.direct,
      createdAt: DateTime.now(),
      metadata: InviteMetadata(
        message: message,
        allowedMBTI: allowedMBTI,
        requireApproval: requireApproval,
      ),
    );
  }

  // 이메일 초대 생성
  static ChatInviteModel createEmailInvite({
    required String chatId,
    required String invitedBy,
    required String invitedUserEmail,
    String? message,
    List<String>? allowedMBTI,
    bool requireApproval = false,
  }) {
    final inviteId = 'invite_${chatId}_email_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatInviteModel(
      inviteId: inviteId,
      chatId: chatId,
      invitedBy: invitedBy,
      invitedUserEmail: invitedUserEmail,
      type: InviteType.direct,
      createdAt: DateTime.now(),
      metadata: InviteMetadata(
        message: message,
        allowedMBTI: allowedMBTI,
        requireApproval: requireApproval,
      ),
    );
  }

  // 링크 초대 생성
  static ChatInviteModel createLinkInvite({
    required String chatId,
    required String invitedBy,
    String? message,
    String? inviteCode,
    DateTime? expiresAt,
    int? maxUses,
    List<String>? allowedMBTI,
    bool requireApproval = false,
  }) {
    final inviteId = 'invite_${chatId}_link_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatInviteModel(
      inviteId: inviteId,
      chatId: chatId,
      invitedBy: invitedBy,
      type: InviteType.link,
      createdAt: DateTime.now(),
      metadata: InviteMetadata(
        message: message,
        inviteCode: inviteCode ?? _generateInviteCode(),
        expiresAt: expiresAt,
        maxUses: maxUses,
        allowedMBTI: allowedMBTI,
        requireApproval: requireApproval,
      ),
    );
  }

  // 추천 기반 초대 생성
  static ChatInviteModel createRecommendationInvite({
    required String chatId,
    required String invitedBy,
    required String invitedUserId,
    String? message,
    List<String>? allowedMBTI,
    bool requireApproval = false,
  }) {
    final inviteId = 'invite_${chatId}_rec_${invitedUserId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatInviteModel(
      inviteId: inviteId,
      chatId: chatId,
      invitedBy: invitedBy,
      invitedUserId: invitedUserId,
      type: InviteType.recommendation,
      createdAt: DateTime.now(),
      metadata: InviteMetadata(
        message: message,
        allowedMBTI: allowedMBTI,
        requireApproval: requireApproval,
      ),
    );
  }

  // 초대 코드 생성
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    
    for (int i = 0; i < 8; i++) {
      final index = (random + i) % chars.length;
      code.write(chars[index]);
    }
    
    return code.toString();
  }
}
