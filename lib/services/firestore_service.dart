import 'package:get/get.dart';

// 데모용 Firestore 문서 클래스
class DemoDocumentSnapshot {
  final String id;
  final Map<String, dynamic> data;
  final bool exists;

  DemoDocumentSnapshot({
    required this.id,
    required this.data,
    this.exists = true,
  });

  Map<String, dynamic>? call() => exists ? data : null;
}

// 데모용 Firestore 컬렉션 참조
class DemoCollectionReference {
  final String path;
  final DemoFirestoreService _service;

  DemoCollectionReference(this.path, this._service);

  DemoDocumentReference doc(String id) {
    return DemoDocumentReference('$path/$id', _service);
  }

  Future<void> add(Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await doc(id).set(data);
  }

  Future<List<DemoDocumentSnapshot>> get() async {
    await Future.delayed(const Duration(milliseconds: 100)); // 네트워크 지연 시뮬레이션
    return _service._getCollectionDocuments(path);
  }

  Stream<List<DemoDocumentSnapshot>> snapshots() {
    return _service._getCollectionStream(path);
  }

  DemoQuery where(String field, {dynamic isEqualTo, dynamic isGreaterThan, dynamic isLessThan}) {
    return DemoQuery(path, _service, field: field, isEqualTo: isEqualTo, isGreaterThan: isGreaterThan, isLessThan: isLessThan);
  }

  DemoQuery orderBy(String field, {bool descending = false}) {
    return DemoQuery(path, _service, orderByField: field, descending: descending);
  }

  DemoQuery limit(int count) {
    return DemoQuery(path, _service, limitCount: count);
  }
}

// 데모용 Firestore 문서 참조
class DemoDocumentReference {
  final String path;
  final DemoFirestoreService _service;

  DemoDocumentReference(this.path, this._service);

  String get id => path.split('/').last;

  Future<DemoDocumentSnapshot> get() async {
    await Future.delayed(const Duration(milliseconds: 50)); // 네트워크 지연 시뮬레이션
    return _service._getDocument(path);
  }

  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {
    await Future.delayed(const Duration(milliseconds: 100)); // 네트워크 지연 시뮬레이션
    await _service._setDocument(path, data, merge: merge);
  }

  Future<void> update(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100)); // 네트워크 지연 시뮬레이션
    await _service._updateDocument(path, data);
  }

  Future<void> delete() async {
    await Future.delayed(const Duration(milliseconds: 100)); // 네트워크 지연 시뮬레이션
    await _service._deleteDocument(path);
  }

  Stream<DemoDocumentSnapshot> snapshots() {
    return _service._getDocumentStream(path);
  }

  DemoCollectionReference collection(String collectionPath) {
    return DemoCollectionReference('$path/$collectionPath', _service);
  }
}

// 데모용 쿼리 클래스
class DemoQuery {
  final String collectionPath;
  final DemoFirestoreService _service;
  final String? field;
  final dynamic isEqualTo;
  final dynamic isGreaterThan;
  final dynamic isLessThan;
  final String? orderByField;
  final bool descending;
  final int? limitCount;

  DemoQuery(
    this.collectionPath,
    this._service, {
    this.field,
    this.isEqualTo,
    this.isGreaterThan,
    this.isLessThan,
    this.orderByField,
    this.descending = false,
    this.limitCount,
  });

  Future<List<DemoDocumentSnapshot>> get() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _service._queryDocuments(
      collectionPath,
      field: field,
      isEqualTo: isEqualTo,
      isGreaterThan: isGreaterThan,
      isLessThan: isLessThan,
      orderByField: orderByField,
      descending: descending,
      limitCount: limitCount,
    );
  }

  DemoQuery where(String newField, {dynamic isEqualTo, dynamic isGreaterThan, dynamic isLessThan}) {
    return DemoQuery(
      collectionPath,
      _service,
      field: newField,
      isEqualTo: isEqualTo,
      isGreaterThan: isGreaterThan,
      isLessThan: isLessThan,
      orderByField: orderByField,
      descending: descending,
      limitCount: limitCount,
    );
  }

  DemoQuery orderBy(String newField, {bool descending = false}) {
    return DemoQuery(
      collectionPath,
      _service,
      field: field,
      isEqualTo: isEqualTo,
      isGreaterThan: isGreaterThan,
      isLessThan: isLessThan,
      orderByField: newField,
      descending: descending,
      limitCount: limitCount,
    );
  }

  DemoQuery limit(int count) {
    return DemoQuery(
      collectionPath,
      _service,
      field: field,
      isEqualTo: isEqualTo,
      isGreaterThan: isGreaterThan,
      isLessThan: isLessThan,
      orderByField: orderByField,
      descending: descending,
      limitCount: count,
    );
  }
}

// 데모용 Firestore 서비스
class DemoFirestoreService extends GetxService {
  static DemoFirestoreService get instance => Get.find<DemoFirestoreService>();

  // 메모리 기반 데이터 저장소
  final Map<String, Map<String, dynamic>> _documents = {};
  
  // 실시간 업데이트를 위한 스트림 컨트롤러
  final Map<String, Stream<DemoDocumentSnapshot>> _documentStreams = {};
  final Map<String, Stream<List<DemoDocumentSnapshot>>> _collectionStreams = {};

  @override
  void onInit() {
    super.onInit();
    _initializeSampleData();
  }

  // 샘플 데이터 초기화
  void _initializeSampleData() {
    _initializeUserSamples();
    _initializeChatSamples();
    _initializeMessageSamples();
    _initializeNotificationSamples();
    _initializeMBTITestSamples();
    _initializeRecommendationSamples();

    print('데모 Firestore 초기화 완료 - 모든 컬렉션 샘플 데이터 생성');
  }

  // 사용자 샘플 데이터
  void _initializeUserSamples() {
    final now = DateTime.now();
    
    // 다양한 MBTI 타입의 사용자들
    final sampleUsers = [
      {
        'uid': 'demo-user-001',
        'email': 'demo@typetalk.com',
        'name': '데모 사용자',
        'createdAt': now.subtract(Duration(days: 30)),
        'updatedAt': now,
        'mbtiType': 'ENFP',
        'mbtiTestCount': 3,
        'profileImageUrl': null,
        'bio': '안녕하세요! MBTI 기반 대화를 좋아합니다.',
        'loginProvider': 'email',
        'preferences': {
          'notifications': true,
          'darkMode': false,
          'language': 'ko',
          'privateChatEnabled': true,
          'mbtiVisible': true,
        },
        'stats': {
          'chatCount': 15,
          'friendCount': 8,
          'messageCount': 127,
          'lastLoginAt': now,
          'lastActiveAt': now,
        },
        'location': {
          'country': 'KR',
          'city': 'Seoul',
          'timezone': 'Asia/Seoul',
        }
      },
      {
        'uid': 'demo-user-002',
        'email': 'intj@typetalk.com',
        'name': 'INTJ 사용자',
        'createdAt': now.subtract(Duration(days: 20)),
        'updatedAt': now.subtract(Duration(hours: 2)),
        'mbtiType': 'INTJ',
        'mbtiTestCount': 1,
        'profileImageUrl': null,
        'bio': '논리적 사고를 좋아하는 건축가입니다.',
        'loginProvider': 'google',
        'preferences': {
          'notifications': false,
          'darkMode': true,
          'language': 'ko',
          'privateChatEnabled': false,
          'mbtiVisible': true,
        },
        'stats': {
          'chatCount': 5,
          'friendCount': 3,
          'messageCount': 45,
          'lastLoginAt': now.subtract(Duration(hours: 2)),
          'lastActiveAt': now.subtract(Duration(hours: 2)),
        },
        'location': {
          'country': 'KR',
          'city': 'Busan',
          'timezone': 'Asia/Seoul',
        }
      },
      {
        'uid': 'demo-user-003',
        'email': 'esfj@typetalk.com',
        'name': 'ESFJ 사용자',
        'createdAt': now.subtract(Duration(days: 10)),
        'updatedAt': now.subtract(Duration(minutes: 30)),
        'mbtiType': 'ESFJ',
        'mbtiTestCount': 2,
        'profileImageUrl': null,
        'bio': '사람들과의 조화를 중시하는 사교적인 성격입니다.',
        'loginProvider': 'apple',
        'preferences': {
          'notifications': true,
          'darkMode': false,
          'language': 'ko',
          'privateChatEnabled': true,
          'mbtiVisible': true,
        },
        'stats': {
          'chatCount': 12,
          'friendCount': 15,
          'messageCount': 98,
          'lastLoginAt': now.subtract(Duration(minutes: 30)),
          'lastActiveAt': now.subtract(Duration(minutes: 30)),
        },
        'location': {
          'country': 'KR',
          'city': 'Incheon',
          'timezone': 'Asia/Seoul',
        }
      }
    ];

    for (int i = 0; i < sampleUsers.length; i++) {
      _documents['users/demo-user-00${i + 1}'] = sampleUsers[i];
    }
  }

  // 채팅방 샘플 데이터
  void _initializeChatSamples() {
    final now = DateTime.now();
    
    final sampleChats = [
      {
        'chatId': 'chat-enfp-001',
        'type': 'group',
        'title': 'ENFP 모임 💫',
        'description': '활발하고 창의적인 ENFP들의 소통 공간입니다!',
        'createdBy': 'demo-user-001',
        'createdAt': now.subtract(Duration(days: 15)),
        'updatedAt': now.subtract(Duration(minutes: 5)),
        'participants': ['demo-user-001', 'demo-user-003'],
        'participantCount': 2,
        'maxParticipants': 10,
        'targetMBTI': ['ENFP', 'ENFJ'],
        'mbtiCategory': 'NF',
        'settings': {
          'isPrivate': false,
          'allowInvites': true,
          'moderatedMode': false,
          'autoDelete': false,
          'autoDeleteDays': null,
        },
        'stats': {
          'messageCount': 45,
          'activeMembers': 2,
          'lastActivity': now.subtract(Duration(minutes: 5)),
        },
        'lastMessage': {
          'content': '오늘 날씨가 정말 좋네요! 🌤️',
          'senderId': 'demo-user-001',
          'senderName': '데모 사용자',
          'timestamp': now.subtract(Duration(minutes: 5)),
          'type': 'text',
        }
      },
      {
        'chatId': 'chat-thinking-002',
        'type': 'group',
        'title': '논리적 사고 클럽 🧠',
        'description': 'T 성향들이 모여 논리적 토론을 하는 공간',
        'createdBy': 'demo-user-002',
        'createdAt': now.subtract(Duration(days: 8)),
        'updatedAt': now.subtract(Duration(hours: 1)),
        'participants': ['demo-user-002'],
        'participantCount': 1,
        'maxParticipants': 8,
        'targetMBTI': ['INTJ', 'ENTJ', 'INTP', 'ENTP'],
        'mbtiCategory': 'NT',
        'settings': {
          'isPrivate': false,
          'allowInvites': true,
          'moderatedMode': true,
          'autoDelete': false,
          'autoDeleteDays': null,
        },
        'stats': {
          'messageCount': 12,
          'activeMembers': 1,
          'lastActivity': now.subtract(Duration(hours: 1)),
        },
        'lastMessage': {
          'content': '새로운 프로그래밍 패러다임에 대해 토론해봐요',
          'senderId': 'demo-user-002',
          'senderName': 'INTJ 사용자',
          'timestamp': now.subtract(Duration(hours: 1)),
          'type': 'text',
        }
      },
      {
        'chatId': 'private-001-003',
        'type': 'private',
        'title': '개인 채팅',
        'description': null,
        'createdBy': 'demo-user-001',
        'createdAt': now.subtract(Duration(days: 5)),
        'updatedAt': now.subtract(Duration(hours: 3)),
        'participants': ['demo-user-001', 'demo-user-003'],
        'participantCount': 2,
        'maxParticipants': 2,
        'targetMBTI': null,
        'mbtiCategory': null,
        'settings': {
          'isPrivate': true,
          'allowInvites': false,
          'moderatedMode': false,
          'autoDelete': false,
          'autoDeleteDays': null,
        },
        'stats': {
          'messageCount': 28,
          'activeMembers': 2,
          'lastActivity': now.subtract(Duration(hours: 3)),
        },
        'lastMessage': {
          'content': '내일 만날까요?',
          'senderId': 'demo-user-003',
          'senderName': 'ESFJ 사용자',
          'timestamp': now.subtract(Duration(hours: 3)),
          'type': 'text',
        }
      }
    ];

    for (int i = 0; i < sampleChats.length; i++) {
      final chat = sampleChats[i];
      _documents['chats/${chat['chatId']}'] = chat;
    }
  }

  // 메시지 샘플 데이터
  void _initializeMessageSamples() {
    final now = DateTime.now();
    
    final sampleMessages = [
      {
        'messageId': 'msg-001',
        'chatId': 'chat-enfp-001',
        'senderId': 'demo-user-001',
        'senderName': '데모 사용자',
        'senderMBTI': 'ENFP',
        'content': '안녕하세요! 새로운 채팅방을 만들었어요 🎉',
        'type': 'text',
        'createdAt': now.subtract(Duration(days: 15)),
        'updatedAt': null,
        'media': null,
        'status': {
          'isEdited': false,
          'isDeleted': false,
          'readBy': ['demo-user-001', 'demo-user-003'],
        },
        'reactions': {
          '👋': ['demo-user-003'],
          '🎉': ['demo-user-003']
        },
        'replyTo': null,
      },
      {
        'messageId': 'msg-002',
        'chatId': 'chat-enfp-001',
        'senderId': 'demo-user-003',
        'senderName': 'ESFJ 사용자',
        'senderMBTI': 'ESFJ',
        'content': '와! 정말 좋은 아이디어네요! 참여하고 싶어요 😊',
        'type': 'text',
        'createdAt': now.subtract(Duration(days: 15, minutes: -10)),
        'updatedAt': null,
        'media': null,
        'status': {
          'isEdited': false,
          'isDeleted': false,
          'readBy': ['demo-user-001', 'demo-user-003'],
        },
        'reactions': {
          '❤️': ['demo-user-001']
        },
        'replyTo': {
          'messageId': 'msg-001',
          'content': '안녕하세요! 새로운 채팅방을 만들었어요 🎉',
          'senderId': 'demo-user-001',
        },
      },
      {
        'messageId': 'msg-003',
        'chatId': 'chat-thinking-002',
        'senderId': 'demo-user-002',
        'senderName': 'INTJ 사용자',
        'senderMBTI': 'INTJ',
        'content': '함수형 프로그래밍의 장점에 대해 논의해보고 싶습니다.',
        'type': 'text',
        'createdAt': now.subtract(Duration(days: 8)),
        'updatedAt': null,
        'media': null,
        'status': {
          'isEdited': false,
          'isDeleted': false,
          'readBy': ['demo-user-002'],
        },
        'reactions': null,
        'replyTo': null,
      }
    ];

    for (final message in sampleMessages) {
      _documents['messages/${message['messageId']}'] = message;
    }
  }

  // 알림 샘플 데이터
  void _initializeNotificationSamples() {
    final now = DateTime.now();
    
    final sampleNotifications = [
      {
        'notificationId': 'notif-001',
        'userId': 'demo-user-001',
        'chatId': 'chat-enfp-001',
        'messageId': 'msg-002',
        'type': 'message',
        'title': 'ESFJ 사용자님이 메시지를 보냈습니다',
        'body': '와! 정말 좋은 아이디어네요! 참여하고 싶어요 😊',
        'status': 'unread',
        'createdAt': now.subtract(Duration(hours: 2)),
        'readAt': null,
        'dismissedAt': null,
        'metadata': {
          'imageUrl': null,
          'actionUrl': null,
          'customData': null,
          'badgeCount': 1,
        },
      },
      {
        'notificationId': 'notif-002',
        'userId': 'demo-user-001',
        'chatId': 'chat-thinking-002',
        'messageId': null,
        'type': 'invite',
        'title': 'INTJ 사용자님이 초대했습니다',
        'body': '함수형 프로그래밍 채팅방에 초대되었습니다',
        'status': 'unread',
        'createdAt': now.subtract(Duration(days: 1)),
        'readAt': null,
        'dismissedAt': null,
        'metadata': {
          'imageUrl': null,
          'actionUrl': null,
          'customData': null,
          'badgeCount': 1,
        },
      },
      {
        'notificationId': 'notif-003',
        'userId': 'demo-user-002',
        'chatId': 'chat-thinking-002',
        'messageId': 'msg-003',
        'type': 'reaction',
        'title': 'ESFJ 사용자님이 반응했습니다',
        'body': '👍 반응을 받았습니다',
        'status': 'read',
        'createdAt': now.subtract(Duration(days: 2)),
        'readAt': now.subtract(Duration(days: 1)),
        'dismissedAt': null,
        'metadata': {
          'imageUrl': null,
          'actionUrl': null,
          'customData': null,
          'badgeCount': null,
        },
      }
    ];

    for (final notification in sampleNotifications) {
      _documents['notifications/${notification['notificationId']}'] = notification;
    }
  }

  // MBTI 테스트 샘플 데이터
  void _initializeMBTITestSamples() {
    final now = DateTime.now();
    
    final sampleTests = [
      {
        'testId': 'mbti-test-001',
        'userId': 'demo-user-001',
        'result': 'ENFP',
        'completedAt': now.subtract(Duration(days: 25)),
        'scores': {
          'E_I': 35.0,
          'S_N': 40.0,
          'T_F': 25.0,
          'J_P': 45.0,
        },
        'answers': [
          {
            'questionId': 'ei_1',
            'answer': 4,
            'timeSpent': 8,
          },
          {
            'questionId': 'sn_1',
            'answer': 4,
            'timeSpent': 12,
          },
          {
            'questionId': 'tf_1',
            'answer': 4,
            'timeSpent': 15,
          },
          {
            'questionId': 'jp_1',
            'answer': 5,
            'timeSpent': 10,
          }
        ],
        'metadata': {
          'version': '1.0',
          'totalQuestions': 4,
          'totalTimeSpent': 45,
          'accuracy': 85.5,
        }
      },
      {
        'testId': 'mbti-test-002',
        'userId': 'demo-user-002',
        'result': 'INTJ',
        'completedAt': now.subtract(Duration(days: 18)),
        'scores': {
          'E_I': -42.0,
          'S_N': 38.0,
          'T_F': -35.0,
          'J_P': -30.0,
        },
        'answers': [
          {
            'questionId': 'ei_1',
            'answer': 1,
            'timeSpent': 5,
          },
          {
            'questionId': 'sn_1',
            'answer': 4,
            'timeSpent': 8,
          },
          {
            'questionId': 'tf_1',
            'answer': 1,
            'timeSpent': 6,
          },
          {
            'questionId': 'jp_1',
            'answer': 2,
            'timeSpent': 7,
          }
        ],
        'metadata': {
          'version': '1.0',
          'totalQuestions': 4,
          'totalTimeSpent': 26,
          'accuracy': 92.3,
        }
      }
    ];

    for (final test in sampleTests) {
      _documents['mbti_tests/${test['testId']}'] = test;
    }
  }

  // 추천 샘플 데이터
  void _initializeRecommendationSamples() {
    final now = DateTime.now();
    
    final sampleRecommendations = [
      {
        'recommendationId': 'rec-user-001',
        'userId': 'demo-user-001',
        'type': 'user',
        'targetId': 'demo-user-002',
        'score': 78.5,
        'reasons': [
          'MBTI 성격이 잘 맞습니다 (ENFP ↔ INTJ)',
          '새로운 관점을 배울 수 있습니다'
        ],
        'createdAt': now.subtract(Duration(days: 3)),
        'viewedAt': now.subtract(Duration(days: 2)),
        'actionTaken': null,
        'algorithm': {
          'version': '1.0',
          'factors': {
            'mbtiCompatibility': 75.0,
            'sharedInterests': 60.0,
            'activityLevel': 80.0,
            'location': 100.0,
          }
        }
      },
      {
        'recommendationId': 'rec-chat-001',
        'userId': 'demo-user-002',
        'type': 'chat',
        'targetId': 'chat-thinking-002',
        'score': 92.0,
        'reasons': [
          '당신의 MBTI(INTJ)와 매우 잘 맞는 채팅방입니다',
          'NT 타입들과 대화해보세요',
          '활발한 채팅방입니다'
        ],
        'createdAt': now.subtract(Duration(days: 1)),
        'viewedAt': null,
        'actionTaken': null,
        'algorithm': {
          'version': '1.0',
          'factors': {
            'mbtiCompatibility': 95.0,
            'sharedInterests': 90.0,
            'activityLevel': 85.0,
            'location': 100.0,
          }
        }
      }
    ];

    for (final rec in sampleRecommendations) {
      _documents['recommendations/${rec['recommendationId']}'] = rec;
    }
  }

  // 컬렉션 참조 가져오기
  DemoCollectionReference collection(String path) {
    return DemoCollectionReference(path, this);
  }

  // 주요 컬렉션들에 대한 getter
  DemoCollectionReference get users => collection('users');
  DemoCollectionReference get chats => collection('chats');
  DemoCollectionReference get messages => collection('messages');
  DemoCollectionReference get chatParticipants => collection('chatParticipants');
  DemoCollectionReference get chatInvites => collection('chatInvites');
  DemoCollectionReference get notifications => collection('notifications');
  DemoCollectionReference get recommendations => collection('recommendations');

  // 문서 참조 가져오기
  DemoDocumentReference doc(String path) {
    return DemoDocumentReference(path, this);
  }

  // 문서 가져오기
  DemoDocumentSnapshot _getDocument(String path) {
    final data = _documents[path];
    if (data != null) {
      return DemoDocumentSnapshot(
        id: path.split('/').last,
        data: Map<String, dynamic>.from(data),
        exists: true,
      );
    }
    return DemoDocumentSnapshot(
      id: path.split('/').last,
      data: {},
      exists: false,
    );
  }

  // 문서 설정
  Future<void> _setDocument(String path, Map<String, dynamic> data, {bool merge = false}) async {
    try {
      if (merge && _documents.containsKey(path)) {
        _documents[path]!.addAll(data);
      } else {
        _documents[path] = Map<String, dynamic>.from(data);
      }
      
      // 자동으로 타임스탬프 추가
      if (!data.containsKey('updatedAt')) {
        _documents[path]!['updatedAt'] = DateTime.now();
      }
      
      print('문서 저장 완료: $path');
      print('저장된 데이터: ${_documents[path]}');
      
      // 전체 문서 수 출력
      final userDocs = _documents.keys.where((key) => key.startsWith('users/')).length;
      print('현재 총 사용자 문서 수: $userDocs');
    } catch (e) {
      print('문서 저장 실패: $path - $e');
      throw Exception('문서 저장 중 오류가 발생했습니다.');
    }
  }

  // 문서 업데이트
  Future<void> _updateDocument(String path, Map<String, dynamic> data) async {
    try {
      if (!_documents.containsKey(path)) {
        throw Exception('업데이트할 문서가 존재하지 않습니다: $path');
      }
      
      _documents[path]!.addAll(data);
      _documents[path]!['updatedAt'] = DateTime.now();
      
      print('문서 업데이트 완료: $path');
    } catch (e) {
      print('문서 업데이트 실패: $path - $e');
      throw Exception('문서 업데이트 중 오류가 발생했습니다.');
    }
  }

  // 문서 삭제
  Future<void> _deleteDocument(String path) async {
    try {
      _documents.remove(path);
      print('문서 삭제 완료: $path');
    } catch (e) {
      print('문서 삭제 실패: $path - $e');
      throw Exception('문서 삭제 중 오류가 발생했습니다.');
    }
  }

  // 컬렉션 문서들 가져오기
  List<DemoDocumentSnapshot> _getCollectionDocuments(String collectionPath) {
    final documents = <DemoDocumentSnapshot>[];
    
    for (final entry in _documents.entries) {
      if (entry.key.startsWith('$collectionPath/') && 
          entry.key.split('/').length == collectionPath.split('/').length + 1) {
        documents.add(DemoDocumentSnapshot(
          id: entry.key.split('/').last,
          data: Map<String, dynamic>.from(entry.value),
          exists: true,
        ));
      }
    }
    
    return documents;
  }

  // 쿼리 실행
  List<DemoDocumentSnapshot> _queryDocuments(
    String collectionPath, {
    String? field,
    dynamic isEqualTo,
    dynamic isGreaterThan,
    dynamic isLessThan,
    String? orderByField,
    bool descending = false,
    int? limitCount,
  }) {
    var documents = _getCollectionDocuments(collectionPath);

    // 필터링
    if (field != null) {
      documents = documents.where((doc) {
        final value = doc.data[field];
        
        if (isEqualTo != null && value != isEqualTo) return false;
        if (isGreaterThan != null && (value == null || value <= isGreaterThan)) return false;
        if (isLessThan != null && (value == null || value >= isLessThan)) return false;
        
        return true;
      }).toList();
    }

    // 정렬
    if (orderByField != null) {
      documents.sort((a, b) {
        final aValue = a.data[orderByField];
        final bValue = b.data[orderByField];
        
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return 1;
        if (bValue == null) return -1;
        
        int comparison;
        if (aValue is Comparable && bValue is Comparable) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }
        
        return descending ? -comparison : comparison;
      });
    }

    // 제한
    if (limitCount != null && documents.length > limitCount) {
      documents = documents.take(limitCount).toList();
    }

    return documents;
  }

  // 문서 스트림 (실시간 업데이트)
  Stream<DemoDocumentSnapshot> _getDocumentStream(String path) {
    return Stream.periodic(const Duration(seconds: 1), (_) => _getDocument(path));
  }

  // 컬렉션 스트림 (실시간 업데이트)
  Stream<List<DemoDocumentSnapshot>> _getCollectionStream(String collectionPath) {
    return Stream.periodic(const Duration(seconds: 1), (_) => _getCollectionDocuments(collectionPath));
  }

  // 배치 작업 (여러 문서 동시 처리)
  Future<void> batch(List<Map<String, dynamic>> operations) async {
    try {
      for (final operation in operations) {
        final type = operation['type'] as String;
        final path = operation['path'] as String;
        final data = operation['data'] as Map<String, dynamic>?;

        switch (type) {
          case 'set':
            await _setDocument(path, data!, merge: operation['merge'] ?? false);
            break;
          case 'update':
            await _updateDocument(path, data!);
            break;
          case 'delete':
            await _deleteDocument(path);
            break;
        }
      }
      print('배치 작업 완료: ${operations.length}개 작업');
    } catch (e) {
      print('배치 작업 실패: $e');
      throw Exception('배치 작업 중 오류가 발생했습니다.');
    }
  }

  // 트랜잭션 (원자적 작업)
  Future<T> runTransaction<T>(Future<T> Function(DemoFirestoreService transaction) updateFunction) async {
    try {
      // 데모에서는 단순히 함수 실행
      return await updateFunction(this);
    } catch (e) {
      print('트랜잭션 실패: $e');
      throw Exception('트랜잭션 중 오류가 발생했습니다.');
    }
  }
}
