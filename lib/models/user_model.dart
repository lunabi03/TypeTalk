import 'package:typetalk/services/firestore_service.dart';

// 사용자 선호 설정 모델
class UserPreferences {
  final bool notifications;
  final bool darkMode;
  final String language;

  UserPreferences({
    this.notifications = true,
    this.darkMode = false,
    this.language = 'ko',
  });

  Map<String, dynamic> toMap() {
    return {
      'notifications': notifications,
      'darkMode': darkMode,
      'language': language,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      notifications: map['notifications'] ?? true,
      darkMode: map['darkMode'] ?? false,
      language: map['language'] ?? 'ko',
    );
  }

  UserPreferences copyWith({
    bool? notifications,
    bool? darkMode,
    String? language,
  }) {
    return UserPreferences(
      notifications: notifications ?? this.notifications,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
    );
  }
}

// 사용자 통계 모델
class UserStats {
  final int chatCount;
  final int friendCount;
  final DateTime lastLoginAt;

  UserStats({
    this.chatCount = 0,
    this.friendCount = 0,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatCount': chatCount,
      'friendCount': friendCount,
      'lastLoginAt': lastLoginAt,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      chatCount: map['chatCount'] ?? 0,
      friendCount: map['friendCount'] ?? 0,
      lastLoginAt: map['lastLoginAt'] is DateTime 
          ? map['lastLoginAt'] 
          : DateTime.now(),
    );
  }

  UserStats copyWith({
    int? chatCount,
    int? friendCount,
    DateTime? lastLoginAt,
  }) {
    return UserStats(
      chatCount: chatCount ?? this.chatCount,
      friendCount: friendCount ?? this.friendCount,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

// 메인 사용자 모델
class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? mbtiType;
  final int mbtiTestCount;
  final String? profileImageUrl;
  final String? bio;
  final String? loginProvider;
  final UserPreferences preferences;
  final UserStats stats;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.mbtiType,
    this.mbtiTestCount = 0,
    this.profileImageUrl,
    this.bio,
    this.loginProvider,
    UserPreferences? preferences,
    UserStats? stats,
  }) : preferences = preferences ?? UserPreferences(),
       stats = stats ?? UserStats(lastLoginAt: DateTime.now());

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'mbtiType': mbtiType,
      'mbtiTestCount': mbtiTestCount,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'loginProvider': loginProvider,
      'preferences': preferences.toMap(),
      'stats': stats.toMap(),
    };
  }

  // Firestore 문서에서 생성
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime 
          ? map['updatedAt'] 
          : DateTime.now(),
      mbtiType: map['mbtiType'],
      mbtiTestCount: map['mbtiTestCount'] ?? 0,
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      loginProvider: map['loginProvider'],
      preferences: map['preferences'] != null 
          ? UserPreferences.fromMap(map['preferences']) 
          : UserPreferences(),
      stats: map['stats'] != null 
          ? UserStats.fromMap(map['stats']) 
          : UserStats(lastLoginAt: DateTime.now()),
    );
  }

  // Firestore 문서 스냅샷에서 생성
  factory UserModel.fromSnapshot(DemoDocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      throw Exception('사용자 문서가 존재하지 않습니다.');
    }
    return UserModel.fromMap(snapshot.data);
  }

  // 업데이트된 사용자 모델 생성
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mbtiType,
    int? mbtiTestCount,
    String? profileImageUrl,
    String? bio,
    String? loginProvider,
    UserPreferences? preferences,
    UserStats? stats,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      mbtiType: mbtiType ?? this.mbtiType,
      mbtiTestCount: mbtiTestCount ?? this.mbtiTestCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      loginProvider: loginProvider ?? this.loginProvider,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }

  // MBTI 결과 업데이트
  UserModel updateMBTI(String newMbtiType) {
    return copyWith(
      mbtiType: newMbtiType,
      mbtiTestCount: mbtiTestCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  // 프로필 업데이트
  UserModel updateProfile({
    String? name,
    String? bio,
    String? profileImageUrl,
  }) {
    return copyWith(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      updatedAt: DateTime.now(),
    );
  }

  // 설정 업데이트
  UserModel updatePreferences(UserPreferences newPreferences) {
    return copyWith(
      preferences: newPreferences,
      updatedAt: DateTime.now(),
    );
  }

  // 통계 업데이트
  UserModel updateStats(UserStats newStats) {
    return copyWith(
      stats: newStats,
      updatedAt: DateTime.now(),
    );
  }

  // 로그인 시간 업데이트
  UserModel updateLastLogin() {
    return copyWith(
      stats: stats.copyWith(lastLoginAt: DateTime.now()),
      updatedAt: DateTime.now(),
    );
  }

  // 채팅 카운트 증가
  UserModel incrementChatCount() {
    return copyWith(
      stats: stats.copyWith(chatCount: stats.chatCount + 1),
      updatedAt: DateTime.now(),
    );
  }

  // 친구 카운트 업데이트
  UserModel updateFriendCount(int count) {
    return copyWith(
      stats: stats.copyWith(friendCount: count),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, mbtiType: $mbtiType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
