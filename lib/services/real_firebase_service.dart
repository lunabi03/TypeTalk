import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

// 실제 Firebase 서비스
class RealFirebaseService extends GetxService {
  static RealFirebaseService get instance => Get.find<RealFirebaseService>();

  // Firebase 인스턴스들
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  @override
  void onInit() {
    super.onInit();
    _initializeFirebase();
  }

  void _initializeFirebase() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      
      // Firebase 서비스 상태 확인
      print('Firebase Auth 인스턴스 생성 완료');
      print('Firestore 인스턴스 생성 완료');
      
      // Firestore 설정 (오프라인 지원, 캐시 설정)
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      print('실제 Firebase 서비스 초기화 완료');
    } catch (e) {
      print('Firebase 서비스 초기화 실패: $e');
      throw Exception('Firebase 서비스를 초기화할 수 없습니다: ${e.toString()}');
    }
  }

  // Firebase Auth 인스턴스 반환
  FirebaseAuth get auth => _auth;

  // Firestore 인스턴스 반환
  FirebaseFirestore get firestore => _firestore;

  // 주요 컬렉션들
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get chats => _firestore.collection('chats');
  CollectionReference get messages => _firestore.collection('messages');
  CollectionReference get chatParticipants => _firestore.collection('chatParticipants');
  CollectionReference get notifications => _firestore.collection('notifications');
  CollectionReference get recommendations => _firestore.collection('recommendations');
  CollectionReference get chatInvites => _firestore.collection('chatInvites');

  // 컬렉션 참조 가져오기
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  // 문서 참조 가져오기
  DocumentReference doc(String path) {
    return _firestore.doc(path);
  }

  // 문서 가져오기
  Future<DocumentSnapshot> getDocument(String path) async {
    try {
      return await _firestore.doc(path).get();
    } catch (e) {
      print('문서 조회 실패: $path - $e');
      throw Exception('문서 조회 중 오류가 발생했습니다.');
    }
  }

  // 문서 설정
  Future<void> setDocument(String path, Map<String, dynamic> data, {bool merge = false}) async {
    try {
      // 자동으로 타임스탬프 추가
      if (!data.containsKey('updatedAt')) {
        data['updatedAt'] = FieldValue.serverTimestamp();
      }
      
      await _firestore.doc(path).set(data, SetOptions(merge: merge));
      print('Firebase 문서 저장 완료: $path');
    } catch (e) {
      print('Firebase 문서 저장 실패: $path - $e');
      throw Exception('문서 저장 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 문서 업데이트
  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    try {
      // 자동으로 타임스탬프 추가
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.doc(path).update(data);
      print('Firebase 문서 업데이트 완료: $path');
    } catch (e) {
      print('Firebase 문서 업데이트 실패: $path - $e');
      throw Exception('문서 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 문서 삭제
  Future<void> deleteDocument(String path) async {
    try {
      await _firestore.doc(path).delete();
      print('Firebase 문서 삭제 완료: $path');
    } catch (e) {
      print('Firebase 문서 삭제 실패: $path - $e');
      throw Exception('문서 삭제 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 컬렉션 문서들 가져오기
  Future<QuerySnapshot> getCollectionDocuments(String collectionPath) async {
    try {
      return await _firestore.collection(collectionPath).get();
    } catch (e) {
      print('컬렉션 조회 실패: $collectionPath - $e');
      throw Exception('컬렉션 조회 중 오류가 발생했습니다.');
    }
  }

  // 쿼리 실행
  Future<QuerySnapshot> queryDocuments(
    String collectionPath, {
    String? field,
    dynamic isEqualTo,
    dynamic isGreaterThan,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    String? orderByField,
    bool descending = false,
    int? limitCount,
    DocumentSnapshot? startAfterDocument,
  }) async {
    try {
      Query query = _firestore.collection(collectionPath);

      // 필터링
      if (field != null) {
        if (isEqualTo != null) {
          query = query.where(field, isEqualTo: isEqualTo);
        }
        if (isGreaterThan != null) {
          query = query.where(field, isGreaterThan: isGreaterThan);
        }
        if (isLessThan != null) {
          query = query.where(field, isLessThan: isLessThan);
        }
        if (isLessThanOrEqualTo != null) {
          query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
        }
        if (isGreaterThanOrEqualTo != null) {
          query = query.where(field, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
        }
        if (arrayContains != null) {
          query = query.where(field, arrayContains: arrayContains);
        }
        if (arrayContainsAny != null) {
          query = query.where(field, arrayContainsAny: arrayContainsAny);
        }
        if (whereIn != null) {
          query = query.where(field, whereIn: whereIn);
        }
        if (whereNotIn != null) {
          query = query.where(field, whereNotIn: whereNotIn);
        }
      }

      // 정렬
      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }

      // 제한
      if (limitCount != null) {
        query = query.limit(limitCount);
      }

      // 시작점
      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      // 제한
      if (limitCount != null) {
        query = query.limit(limitCount);
      }

      return await query.get();
    } catch (e) {
      print('쿼리 실행 실패: $collectionPath - $e');
      throw Exception('쿼리 실행 중 오류가 발생했습니다.');
    }
  }

  // 문서 스트림 (실시간 업데이트)
  Stream<DocumentSnapshot> getDocumentStream(String path) {
    return _firestore.doc(path).snapshots();
  }

  // 컬렉션 스트림 (실시간 업데이트)
  Stream<QuerySnapshot> getCollectionStream(String collectionPath) {
    return _firestore.collection(collectionPath).snapshots();
  }

  // 배치 작업 (여러 문서 동시 처리)
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final type = operation['type'] as String;
        final path = operation['path'] as String;
        final data = operation['data'] as Map<String, dynamic>?;

        final docRef = _firestore.doc(path);

        switch (type) {
          case 'set':
            if (data != null) {
              // 타임스탬프 추가
              if (!data.containsKey('updatedAt')) {
                data['updatedAt'] = FieldValue.serverTimestamp();
              }
              batch.set(docRef, data, SetOptions(merge: operation['merge'] ?? false));
            }
            break;
          case 'update':
            if (data != null) {
              data['updatedAt'] = FieldValue.serverTimestamp();
              batch.update(docRef, data);
            }
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      print('Firebase 배치 작업 완료: ${operations.length}개 작업');
    } catch (e) {
      print('Firebase 배치 작업 실패: $e');
      throw Exception('배치 작업 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 트랜잭션 (원자적 작업)
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) updateFunction) async {
    try {
      return await _firestore.runTransaction<T>((transaction) async {
        return await updateFunction(transaction);
      });
    } catch (e) {
      print('Firebase 트랜잭션 실패: $e');
      throw Exception('트랜잭션 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // Firebase Auth 메서드들

  // 이메일/비밀번호 회원가입
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase 회원가입 성공: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Firebase 회원가입 실패: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    }
  }

  // 이메일/비밀번호 로그인
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase 로그인 성공: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Firebase 로그인 실패: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Firebase 로그아웃 완료');
    } catch (e) {
      print('Firebase 로그아웃 실패: $e');
      throw Exception('로그아웃 중 오류가 발생했습니다.');
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('비밀번호 재설정 이메일 발송 완료: $email');
    } on FirebaseAuthException catch (e) {
      print('비밀번호 재설정 이메일 발송 실패: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    }
  }

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firebase Auth 예외 처리 (한국어 메시지로 개선)
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    print('Firebase Auth 예외 발생: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'weak-password':
        return Exception('비밀번호가 너무 약합니다. 최소 6자 이상으로 설정해주세요.');
      case 'email-already-in-use':
        return Exception('이미 사용 중인 이메일입니다. 다른 이메일을 사용하거나 로그인해주세요.');
      case 'user-not-found':
        return Exception('등록되지 않은 이메일입니다. 회원가입을 먼저 진행해주세요.');
      case 'wrong-password':
        return Exception('비밀번호가 올바르지 않습니다. 다시 확인해주세요.');
      case 'invalid-email':
        return Exception('올바른 이메일 형식을 입력해주세요. (예: user@example.com)');
      case 'user-disabled':
        return Exception('비활성화된 계정입니다. 관리자에게 문의해주세요.');
      case 'too-many-requests':
        return Exception('너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.');
      case 'operation-not-allowed':
        return Exception('이메일/비밀번호 로그인이 비활성화되어 있습니다. Firebase 콘솔에서 설정을 확인해주세요.');
      case 'account-exists-with-different-credential':
        return Exception('다른 방법으로 가입된 계정입니다. Google 또는 Apple 로그인을 시도해보세요.');
      case 'invalid-credential':
        return Exception('유효하지 않은 인증 정보입니다. 이메일과 비밀번호를 다시 확인해주세요.');
      case 'user-token-expired':
        return Exception('로그인 세션이 만료되었습니다. 다시 로그인해주세요.');
      case 'user-token-revoked':
        return Exception('로그인 세션이 취소되었습니다. 다시 로그인해주세요.');
      case 'network-request-failed':
        return Exception('네트워크 연결을 확인해주세요. 인터넷 연결 상태를 점검해보세요.');
      case 'invalid-verification-code':
        return Exception('인증 코드가 올바르지 않습니다. 다시 시도해주세요.');
      case 'invalid-verification-id':
        return Exception('인증 ID가 올바르지 않습니다. 다시 시도해주세요.');
      case 'quota-exceeded':
        return Exception('Firebase 할당량이 초과되었습니다. 잠시 후 다시 시도해주세요.');
      case 'app-not-authorized':
        return Exception('앱이 Firebase에 인증되지 않았습니다. 개발자에게 문의해주세요.');
      case 'keychain-error':
        return Exception('키체인 오류가 발생했습니다. 기기를 재시작해보세요.');
      case 'internal-error':
        return Exception('Firebase 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      case 'invalid-app-credential':
        return Exception('앱 인증 정보가 올바르지 않습니다. 앱을 재설치해보세요.');
      case 'invalid-user-token':
        return Exception('사용자 토큰이 올바르지 않습니다. 다시 로그인해주세요.');
      case 'requires-recent-login':
        return Exception('보안을 위해 다시 로그인이 필요합니다.');
      case 'credential-already-in-use':
        return Exception('이미 다른 계정에서 사용 중인 인증 정보입니다.');
      default:
        return Exception('인증 오류가 발생했습니다: ${e.message ?? '알 수 없는 오류'}');
    }
  }

  // OAuth 크레덴셜을 사용한 로그인
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      print('OAuth 크레덴셜 로그인 성공: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('OAuth 크레덴셜 로그인 실패: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    }
  }

  // 배치 작업 시작
  WriteBatch batch() {
    return _firestore.batch();
  }
}

