import 'package:typetalk/services/firestore_service.dart';

// 메시지 타입 열거형
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  voice('voice'),
  video('video');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

// 미디어 정보 모델
class MessageMedia {
  final String url;
  final String filename;
  final int size;
  final String mimeType;

  MessageMedia({
    required this.url,
    required this.filename,
    required this.size,
    required this.mimeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
    };
  }

  factory MessageMedia.fromMap(Map<String, dynamic> map) {
    return MessageMedia(
      url: map['url'] ?? '',
      filename: map['filename'] ?? '',
      size: map['size'] ?? 0,
      mimeType: map['mimeType'] ?? '',
    );
  }
}

// 메시지 상태 모델
class MessageStatus {
  final bool isEdited;
  final bool isDeleted;
  final List<String> readBy;

  MessageStatus({
    this.isEdited = false,
    this.isDeleted = false,
    this.readBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'readBy': readBy,
    };
  }

  factory MessageStatus.fromMap(Map<String, dynamic> map) {
    return MessageStatus(
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  MessageStatus copyWith({
    bool? isEdited,
    bool? isDeleted,
    List<String>? readBy,
  }) {
    return MessageStatus(
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
    );
  }

  // 읽음 표시 추가
  MessageStatus markAsReadBy(String userId) {
    if (readBy.contains(userId)) return this;
    
    return copyWith(
      readBy: List<String>.from(readBy)..add(userId),
    );
  }
}

// 답글 정보 모델
class MessageReply {
  final String messageId;
  final String content;
  final String senderId;

  MessageReply({
    required this.messageId,
    required this.content,
    required this.senderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'content': content,
      'senderId': senderId,
    };
  }

  factory MessageReply.fromMap(Map<String, dynamic> map) {
    return MessageReply(
      messageId: map['messageId'] ?? '',
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
    );
  }
}

// 메인 메시지 모델
class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderMBTI;
  final String content;
  final String type; // 'text', 'image', 'file', 'system'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MessageMedia? media;
  final MessageStatus status;
  final Map<String, List<String>> reactions;
  final MessageReply? replyTo;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderMBTI,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.updatedAt,
    this.media,
    required this.status,
    this.reactions = const {},
    this.replyTo,
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderMBTI': senderMBTI,
      'content': content,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'media': media?.toMap(),
      'status': status.toMap(),
      'reactions': reactions,
      'replyTo': replyTo?.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderMBTI: map['senderMBTI'],
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
      media: map['media'] != null 
          ? MessageMedia.fromMap(map['media']) 
          : null,
      status: map['status'] != null 
          ? MessageStatus.fromMap(map['status']) 
          : MessageStatus(),
      reactions: map['reactions'] != null 
          ? Map<String, List<String>>.from(
              map['reactions'].map((key, value) => 
                MapEntry(key, List<String>.from(value))))
          : {},
      replyTo: map['replyTo'] != null 
          ? MessageReply.fromMap(map['replyTo']) 
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
  factory MessageModel.fromSnapshot(DemoDocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      throw Exception('메시지 문서가 존재하지 않습니다.');
    }
    return MessageModel.fromMap(snapshot.data);
  }

  // 메시지 업데이트
  MessageModel copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderMBTI,
    String? content,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageMedia? media,
    MessageStatus? status,
    Map<String, List<String>>? reactions,
    MessageReply? replyTo,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderMBTI: senderMBTI ?? this.senderMBTI,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      media: media ?? this.media,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  // 메시지 편집
  MessageModel edit(String newContent) {
    return copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
      status: status.copyWith(isEdited: true),
    );
  }

  // 메시지 삭제
  MessageModel delete() {
    return copyWith(
      content: '삭제된 메시지입니다.',
      updatedAt: DateTime.now(),
      status: status.copyWith(isDeleted: true),
    );
  }

  // 읽음 표시
  MessageModel markAsRead(String userId) {
    return copyWith(
      status: status.markAsReadBy(userId),
    );
  }

  // 반응 추가
  MessageModel addReaction(String emoji, String userId) {
    final newReactions = Map<String, List<String>>.from(reactions);
    
    if (newReactions.containsKey(emoji)) {
      if (!newReactions[emoji]!.contains(userId)) {
        newReactions[emoji] = List<String>.from(newReactions[emoji]!)..add(userId);
      }
    } else {
      newReactions[emoji] = [userId];
    }
    
    return copyWith(reactions: newReactions);
  }

  // 반응 제거
  MessageModel removeReaction(String emoji, String userId) {
    if (!reactions.containsKey(emoji)) {
      return this;
    }
    
    final newReactions = Map<String, List<String>>.from(reactions);
    newReactions[emoji] = List<String>.from(newReactions[emoji]!)..remove(userId);
    
    // 반응이 비어있으면 이모지 자체를 제거
    if (newReactions[emoji]!.isEmpty) {
      newReactions.remove(emoji);
    }
    
    return copyWith(reactions: newReactions);
  }

  // 텍스트 메시지인지 확인
  bool get isTextMessage => type == 'text';

  // 이미지 메시지인지 확인
  bool get isImageMessage => type == 'image';

  // 파일 메시지인지 확인
  bool get isFileMessage => type == 'file';

  // 시스템 메시지인지 확인
  bool get isSystemMessage => type == 'system';

  // 편집된 메시지인지 확인
  bool get isEdited => status.isEdited;

  // 삭제된 메시지인지 확인
  bool get isDeleted => status.isDeleted;

  // 답글 메시지인지 확인
  bool get isReply => replyTo != null;

  // 미디어가 있는 메시지인지 확인
  bool get hasMedia => media != null;

  // 반응이 있는 메시지인지 확인
  bool get hasReactions => reactions != null && reactions!.isNotEmpty;

  // 특정 사용자가 읽었는지 확인
  bool isReadBy(String userId) => status.readBy.contains(userId);

  // 읽은 사용자 수
  int get readCount => status.readBy.length;

  // 특정 반응의 수
  int getReactionCount(String emoji) {
    return reactions?[emoji]?.length ?? 0;
  }

  // 사용자가 특정 반응을 했는지 확인
  bool hasUserReacted(String emoji, String userId) {
    return reactions?[emoji]?.contains(userId) ?? false;
  }

  @override
  String toString() {
    return 'MessageModel(messageId: $messageId, chatId: $chatId, type: $type, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}

// 메시지 생성 도우미 클래스
class MessageCreationHelper {
  // 텍스트 메시지 생성
  static MessageModel createTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderMBTI,
    required String content,
    MessageReply? replyTo,
  }) {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    
    return MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderMBTI: senderMBTI,
      content: content,
      type: 'text',
      createdAt: DateTime.now(),
      status: MessageStatus(),
      replyTo: replyTo,
    );
  }

  // 이미지 메시지 생성
  static MessageModel createImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderMBTI,
    required String imageUrl,
    required String filename,
    required int fileSize,
    String caption = '',
  }) {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    
    return MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderMBTI: senderMBTI,
      content: caption.isEmpty ? '이미지를 전송했습니다.' : caption,
      type: 'image',
      createdAt: DateTime.now(),
      status: MessageStatus(),
      media: MessageMedia(
        url: imageUrl,
        filename: filename,
        size: fileSize,
        mimeType: 'image/jpeg',
      ),
    );
  }

  // 파일 메시지 생성
  static MessageModel createFileMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderMBTI,
    required String fileUrl,
    required String filename,
    required int fileSize,
    required String mimeType,
  }) {
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    
    return MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderMBTI: senderMBTI,
      content: '파일을 전송했습니다: $filename',
      type: 'file',
      createdAt: DateTime.now(),
      status: MessageStatus(),
      media: MessageMedia(
        url: fileUrl,
        filename: filename,
        size: fileSize,
        mimeType: mimeType,
      ),
    );
  }

  // 시스템 메시지 생성
  static MessageModel createSystemMessage({
    required String chatId,
    required String content,
  }) {
    final messageId = 'sys_${DateTime.now().millisecondsSinceEpoch}';
    
    return MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: 'system',
      senderName: '시스템',
      content: content,
      type: 'system',
      createdAt: DateTime.now(),
      status: MessageStatus(),
    );
  }

  // 사용자 입장 시스템 메시지
  static MessageModel createUserJoinedMessage({
    required String chatId,
    required String userName,
  }) {
    return createSystemMessage(
      chatId: chatId,
      content: '$userName님이 채팅방에 참여했습니다.',
    );
  }

  // 사용자 퇴장 시스템 메시지
  static MessageModel createUserLeftMessage({
    required String chatId,
    required String userName,
  }) {
    return createSystemMessage(
      chatId: chatId,
      content: '$userName님이 채팅방을 나갔습니다.',
    );
  }

  // 채팅방 생성 시스템 메시지
  static MessageModel createChatCreatedMessage({
    required String chatId,
    required String creatorName,
  }) {
    return createSystemMessage(
      chatId: chatId,
      content: '$creatorName님이 채팅방을 생성했습니다.',
    );
  }
}

