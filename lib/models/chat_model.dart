import 'package:typetalk/services/firestore_service.dart';

// 채팅방 설정 모델
class ChatSettings {
  final bool isPrivate;
  final bool allowInvites;
  final bool moderatedMode;
  final bool autoDelete;
  final int? autoDeleteDays;

  ChatSettings({
    this.isPrivate = false,
    this.allowInvites = true,
    this.moderatedMode = false,
    this.autoDelete = false,
    this.autoDeleteDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'isPrivate': isPrivate,
      'allowInvites': allowInvites,
      'moderatedMode': moderatedMode,
      'autoDelete': autoDelete,
      'autoDeleteDays': autoDeleteDays,
    };
  }

  factory ChatSettings.fromMap(Map<String, dynamic> map) {
    return ChatSettings(
      isPrivate: map['isPrivate'] ?? false,
      allowInvites: map['allowInvites'] ?? true,
      moderatedMode: map['moderatedMode'] ?? false,
      autoDelete: map['autoDelete'] ?? false,
      autoDeleteDays: map['autoDeleteDays'],
    );
  }

  ChatSettings copyWith({
    bool? isPrivate,
    bool? allowInvites,
    bool? moderatedMode,
    bool? autoDelete,
    int? autoDeleteDays,
  }) {
    return ChatSettings(
      isPrivate: isPrivate ?? this.isPrivate,
      allowInvites: allowInvites ?? this.allowInvites,
      moderatedMode: moderatedMode ?? this.moderatedMode,
      autoDelete: autoDelete ?? this.autoDelete,
      autoDeleteDays: autoDeleteDays ?? this.autoDeleteDays,
    );
  }
}

// 채팅방 통계 모델
class ChatStats {
  final int messageCount;
  final int activeMembers;
  final DateTime lastActivity;
  final int totalParticipants;
  final int onlineParticipants;
  final Map<String, int> messageTypeCount;
  final Map<String, int> reactionCount;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;

  ChatStats({
    this.messageCount = 0,
    this.activeMembers = 0,
    required this.lastActivity,
    this.totalParticipants = 0,
    this.onlineParticipants = 0,
    this.messageTypeCount = const {},
    this.reactionCount = const {},
    this.firstMessageAt,
    this.lastMessageAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageCount': messageCount,
      'activeMembers': activeMembers,
      'lastActivity': lastActivity,
      'totalParticipants': totalParticipants,
      'onlineParticipants': onlineParticipants,
      'messageTypeCount': messageTypeCount,
      'reactionCount': reactionCount,
      'firstMessageAt': firstMessageAt,
      'lastMessageAt': lastMessageAt,
    };
  }

  factory ChatStats.fromMap(Map<String, dynamic> map) {
    return ChatStats(
      messageCount: map['messageCount'] ?? 0,
      activeMembers: map['activeMembers'] ?? 0,
      lastActivity: _parseDateTime(map['lastActivity']),
      totalParticipants: map['totalParticipants'] ?? 0,
      onlineParticipants: map['onlineParticipants'] ?? 0,
      messageTypeCount: map['messageTypeCount'] != null 
          ? Map<String, int>.from(map['messageTypeCount'])
          : {},
      reactionCount: map['reactionCount'] != null 
          ? Map<String, int>.from(map['reactionCount'])
          : {},
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

  ChatStats copyWith({
    int? messageCount,
    int? activeMembers,
    DateTime? lastActivity,
    int? totalParticipants,
    int? onlineParticipants,
    Map<String, int>? messageTypeCount,
    Map<String, int>? reactionCount,
    DateTime? firstMessageAt,
    DateTime? lastMessageAt,
  }) {
    return ChatStats(
      messageCount: messageCount ?? this.messageCount,
      activeMembers: activeMembers ?? this.activeMembers,
      lastActivity: lastActivity ?? this.lastActivity,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      onlineParticipants: onlineParticipants ?? this.onlineParticipants,
      messageTypeCount: messageTypeCount ?? this.messageTypeCount,
      reactionCount: reactionCount ?? this.reactionCount,
      firstMessageAt: firstMessageAt ?? this.firstMessageAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  // 메시지 수 증가
  ChatStats incrementMessageCount(String messageType) {
    final newMessageTypeCount = Map<String, int>.from(messageTypeCount);
    newMessageTypeCount[messageType] = (newMessageTypeCount[messageType] ?? 0) + 1;
    
    return copyWith(
      messageCount: messageCount + 1,
      lastActivity: DateTime.now(),
      messageTypeCount: newMessageTypeCount,
      firstMessageAt: firstMessageAt ?? DateTime.now(),
      lastMessageAt: DateTime.now(),
    );
  }

  // 참여자 수 업데이트
  ChatStats updateParticipantCount(int total, int online) {
    return copyWith(
      totalParticipants: total,
      onlineParticipants: online,
      lastActivity: DateTime.now(),
    );
  }

  // 반응 수 업데이트
  ChatStats updateReactionCount(String emoji, int count) {
    final newReactionCount = Map<String, int>.from(reactionCount);
    newReactionCount[emoji] = count;
    
    return copyWith(
      reactionCount: newReactionCount,
      lastActivity: DateTime.now(),
    );
  }

  // 활성 멤버 수 업데이트
  ChatStats updateActiveMembers(int count) {
    return copyWith(
      activeMembers: count,
      lastActivity: DateTime.now(),
    );
  }

  // 평균 메시지 길이 계산
  double get averageMessageLength {
    if (messageCount == 0) return 0.0;
    // 실제 구현에서는 메시지 길이를 추적해야 함
    return 0.0;
  }

  // 참여율 계산
  double get participationRate {
    if (totalParticipants == 0) return 0.0;
    return (activeMembers / totalParticipants) * 100;
  }

  // 온라인 참여율 계산
  double get onlineRate {
    if (totalParticipants == 0) return 0.0;
    return (onlineParticipants / totalParticipants) * 100;
  }
}

// 마지막 메시지 정보 모델
class LastMessage {
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final String type;

  LastMessage({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.type = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp,
      'type': type,
    };
  }

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      timestamp: _parseDateTime(map['timestamp']),
      type: map['type'] ?? 'text',
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
}

// 메인 채팅방 모델
class ChatModel {
  final String chatId;
  final String type; // 'group' | 'private'
  final String title;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> participants;
  final int participantCount;
  final int? maxParticipants;
  final List<String>? targetMBTI;
  final String? mbtiCategory;
  final ChatSettings settings;
  final ChatStats stats;
  final LastMessage? lastMessage;

  ChatModel({
    required this.chatId,
    required this.type,
    required this.title,
    this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    required this.participantCount,
    this.maxParticipants,
    this.targetMBTI,
    this.mbtiCategory,
    required this.settings,
    required this.stats,
    this.lastMessage,
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'type': type,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'participants': participants,
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'targetMBTI': targetMBTI,
      'mbtiCategory': mbtiCategory,
      'settings': settings.toMap(),
      'stats': stats.toMap(),
      'lastMessage': lastMessage?.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      type: map['type'] ?? 'group',
      title: map['title'] ?? '',
      description: map['description'],
      createdBy: map['createdBy'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      participants: List<String>.from(map['participants'] ?? []),
      participantCount: map['participantCount'] ?? 0,
      maxParticipants: map['maxParticipants'],
      targetMBTI: map['targetMBTI'] != null 
          ? List<String>.from(map['targetMBTI']) 
          : null,
      mbtiCategory: map['mbtiCategory'],
      settings: map['settings'] != null 
          ? ChatSettings.fromMap(map['settings']) 
          : ChatSettings(),
      stats: map['stats'] != null 
          ? ChatStats.fromMap(map['stats']) 
          : ChatStats(lastActivity: DateTime.now()),
      lastMessage: map['lastMessage'] != null 
          ? LastMessage.fromMap(map['lastMessage']) 
          : null,
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
  factory ChatModel.fromSnapshot(DemoDocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      throw Exception('채팅방 문서가 존재하지 않습니다.');
    }
    return ChatModel.fromMap(snapshot.data);
  }

  // 채팅방 정보 업데이트
  ChatModel copyWith({
    String? chatId,
    String? type,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? participants,
    int? participantCount,
    int? maxParticipants,
    List<String>? targetMBTI,
    String? mbtiCategory,
    ChatSettings? settings,
    ChatStats? stats,
    LastMessage? lastMessage,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      participants: participants ?? this.participants,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      targetMBTI: targetMBTI ?? this.targetMBTI,
      mbtiCategory: mbtiCategory ?? this.mbtiCategory,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  // 참여자 추가
  ChatModel addParticipant(String userId) {
    if (participants.contains(userId)) {
      return this;
    }
    
    final newParticipants = List<String>.from(participants)..add(userId);
    return copyWith(
      participants: newParticipants,
      participantCount: newParticipants.length,
      updatedAt: DateTime.now(),
    );
  }

  // 참여자 제거
  ChatModel removeParticipant(String userId) {
    if (!participants.contains(userId)) {
      return this;
    }
    
    final newParticipants = List<String>.from(participants)..remove(userId);
    return copyWith(
      participants: newParticipants,
      participantCount: newParticipants.length,
      updatedAt: DateTime.now(),
    );
  }

  // 마지막 메시지 업데이트
  ChatModel updateLastMessage(LastMessage message) {
    return copyWith(
      lastMessage: message,
      stats: stats.copyWith(
        messageCount: stats.messageCount + 1,
        lastActivity: DateTime.now(),
      ),
      updatedAt: DateTime.now(),
    );
  }

  // 활성 멤버 수 업데이트
  ChatModel updateActiveMembers(int count) {
    return copyWith(
      stats: stats.copyWith(activeMembers: count),
      updatedAt: DateTime.now(),
    );
  }

  // 그룹 채팅방인지 확인
  bool get isGroupChat => type == 'group';

  // 개인 채팅방인지 확인
  bool get isPrivateChat => type == 'private';

  // 공개 채팅방인지 확인
  bool get isPublic => !settings.isPrivate;

  // 참여 가능한지 확인
  bool canJoin(int currentParticipants) {
    if (maxParticipants != null) {
      return currentParticipants < maxParticipants!;
    }
    return true;
  }

  // MBTI 호환성 확인
  bool isCompatibleWithMBTI(String userMBTI) {
    if (targetMBTI == null || targetMBTI!.isEmpty) {
      return true; // 제한이 없으면 모든 MBTI 허용
    }
    return targetMBTI!.contains(userMBTI);
  }

  @override
  String toString() {
    return 'ChatModel(chatId: $chatId, title: $title, type: $type, participants: ${participants.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel && other.chatId == chatId;
  }

  @override
  int get hashCode => chatId.hashCode;
}

// 채팅방 생성 도우미 클래스
class ChatCreationHelper {
  // MBTI 기반 그룹 채팅방 생성
  static ChatModel createMBTIGroupChat({
    required String title,
    required String createdBy,
    required List<String> targetMBTI,
    String? description,
    int? maxParticipants,
    ChatSettings? settings,
  }) {
    final chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    final mbtiCategory = _getMBTICategory(targetMBTI);
    
    return ChatModel(
      chatId: chatId,
      type: 'group',
      title: title,
      description: description,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      participants: [createdBy],
      participantCount: 1,
      maxParticipants: maxParticipants,
      targetMBTI: targetMBTI,
      mbtiCategory: mbtiCategory,
      settings: settings ?? ChatSettings(),
      stats: ChatStats(lastActivity: DateTime.now()),
    );
  }

  // 개인 채팅방 생성
  static ChatModel createPrivateChat({
    required String user1Id,
    required String user2Id,
  }) {
    final chatId = 'private_${user1Id}_${user2Id}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatModel(
      chatId: chatId,
      type: 'private',
      title: '개인 채팅',
      createdBy: user1Id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      participants: [user1Id, user2Id],
      participantCount: 2,
      maxParticipants: 2,
      settings: ChatSettings(isPrivate: true, allowInvites: false),
      stats: ChatStats(lastActivity: DateTime.now()),
    );
  }

  // MBTI 카테고리 결정
  static String _getMBTICategory(List<String> mbtiTypes) {
    if (mbtiTypes.isEmpty) return 'ALL';
    
    final categories = <String>{};
    for (final mbti in mbtiTypes) {
      if (mbti.length >= 2) {
        final category = mbti.substring(1, 3); // NT, NF, ST, SF
        categories.add(category);
      }
    }
    
    if (categories.length == 1) {
      return categories.first;
    } else if (categories.contains('NT') && categories.contains('NF')) {
      return 'N'; // 직관형
    } else if (categories.contains('ST') && categories.contains('SF')) {
      return 'S'; // 감각형
    } else {
      return 'MIXED';
    }
  }
}

