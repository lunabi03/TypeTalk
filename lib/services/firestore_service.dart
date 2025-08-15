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
    // 사용자 컬렉션 샘플 데이터
    _documents['users/demo-user-001'] = {
      'uid': 'demo-user-001',
      'email': 'demo@typetalk.com',
      'name': '데모 사용자',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'mbtiType': 'ENFP',
      'mbtiTestCount': 3,
      'profileImageUrl': null,
      'bio': '안녕하세요! MBTI 기반 대화를 좋아합니다.',
      'preferences': {
        'notifications': true,
        'darkMode': false,
        'language': 'ko',
      },
      'stats': {
        'chatCount': 15,
        'friendCount': 8,
        'lastLoginAt': DateTime.now(),
      }
    };

    print('데모 Firestore 초기화 완료');
  }

  // 컬렉션 참조 가져오기
  DemoCollectionReference collection(String path) {
    return DemoCollectionReference(path, this);
  }

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
