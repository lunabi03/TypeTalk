import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:typetalk/services/real_firebase_service.dart';
import 'package:typetalk/models/user_model.dart';

// 실제 Firebase 사용자 데이터 저장소
class RealUserRepository extends GetxService {
  static RealUserRepository get instance => Get.find<RealUserRepository>();

  RealFirebaseService get _firebase => Get.find<RealFirebaseService>();
  static const String _collectionName = 'users';

  // 사용자 생성
  Future<void> createUser(UserModel user) async {
    try {
      await _firebase.setDocument(
        '$_collectionName/${user.uid}',
        _convertUserModelToFirestore(user),
      );
      
      print('실제 Firebase 사용자 생성 완료: ${user.uid}');
    } catch (e) {
      print('실제 Firebase 사용자 생성 실패: $e');
      throw Exception('사용자 생성 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 조회
  Future<UserModel?> getUser(String uid) async {
    try {
      final snapshot = await _firebase.getDocument('$_collectionName/$uid');

      if (snapshot.exists) {
        return _convertFirestoreToUserModel(snapshot);
      }
      return null;
    } catch (e) {
      print('실제 Firebase 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 업데이트 (전체 업데이트 또는 부분 업데이트)
  Future<void> updateUser(dynamic userData) async {
    try {
      if (userData is UserModel) {
        // 전체 사용자 모델로 업데이트
        await _firebase.updateDocument(
          '$_collectionName/${userData.uid}',
          _convertUserModelToFirestore(userData),
        );
        print('실제 Firebase 사용자 전체 업데이트 완료: ${userData.uid}');
      } else if (userData is Map<String, dynamic>) {
        // 부분 업데이트 (uid와 data가 포함된 Map)
        final uid = userData['uid'];
        final data = Map<String, dynamic>.from(userData);
        data.remove('uid'); // uid는 경로에 사용하므로 제거
        
        await _firebase.updateDocument(
          '$_collectionName/$uid',
          data,
        );
        print('실제 Firebase 사용자 부분 업데이트 완료: $uid');
      } else {
        throw ArgumentError('userData는 UserModel 또는 Map<String, dynamic>이어야 합니다.');
      }
    } catch (e) {
      print('실제 Firebase 사용자 업데이트 실패: $e');
      throw Exception('사용자 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 부분 업데이트 (별도 메서드)
  Future<void> updateUserFields(String uid, Map<String, dynamic> data) async {
    try {
      await _firebase.updateDocument(
        '$_collectionName/$uid',
        data,
      );
      
      print('실제 Firebase 사용자 부분 업데이트 완료: $uid');
    } catch (e) {
      print('실제 Firebase 사용자 부분 업데이트 실패: $e');
      throw Exception('사용자 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 삭제
  Future<void> deleteUser(String uid) async {
    try {
      await _firebase.deleteDocument('$_collectionName/$uid');
      
      print('실제 Firebase 사용자 삭제 완료: $uid');
    } catch (e) {
      print('실제 Firebase 사용자 삭제 실패: $e');
      throw Exception('사용자 삭제 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 이메일로 사용자 조회
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firebase.queryDocuments(
        _collectionName,
        field: 'email',
        isEqualTo: email,
        limitCount: 1,
      );

      if (querySnapshot.docs.isNotEmpty) {
        return _convertFirestoreToUserModel(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('실제 Firebase 이메일로 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // MBTI 타입으로 사용자 목록 조회
  Future<List<UserModel>> getUsersByMBTI(String mbtiType) async {
    try {
      final querySnapshot = await _firebase.queryDocuments(
        _collectionName,
        field: 'mbtiType',
        isEqualTo: mbtiType,
        orderByField: 'updatedAt',
        descending: true,
      );

      return querySnapshot.docs
          .map((doc) => _convertFirestoreToUserModel(doc))
          .toList();
    } catch (e) {
      print('실제 Firebase MBTI로 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 최근 가입한 사용자 목록 조회
  Future<List<UserModel>> getRecentUsers({int limit = 10}) async {
    try {
      final querySnapshot = await _firebase.queryDocuments(
        _collectionName,
        orderByField: 'createdAt',
        descending: true,
        limitCount: limit,
      );

      return querySnapshot.docs
          .map((doc) => _convertFirestoreToUserModel(doc))
          .toList();
    } catch (e) {
      print('실제 Firebase 최근 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 활성 사용자 목록 조회 (최근 로그인 기준)
  Future<List<UserModel>> getActiveUsers({int limit = 10}) async {
    try {
      final querySnapshot = await _firebase.queryDocuments(
        _collectionName,
        orderByField: 'stats.lastLoginAt',
        descending: true,
        limitCount: limit,
      );

      return querySnapshot.docs
          .map((doc) => _convertFirestoreToUserModel(doc))
          .toList();
    } catch (e) {
      print('실제 Firebase 활성 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 이름으로 사용자 조회 (중복 확인용)
  Future<UserModel?> getUserByName(String name) async {
    try {
      final querySnapshot = await _firebase.queryDocuments(
        _collectionName,
        field: 'name',
        isEqualTo: name.trim(),
        limitCount: 1,
      );

      if (querySnapshot.docs.isNotEmpty) {
        return _convertFirestoreToUserModel(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('실제 Firebase 이름으로 사용자 조회 실패: $e');
      throw Exception('이름으로 사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 이름 중복 확인
  Future<bool> isNameAvailable(String name) async {
    try {
      final user = await getUserByName(name);
      return user == null; // 사용자가 없으면 사용 가능
    } catch (e) {
      print('이름 중복 확인 실패: $e');
      // 오류 발생 시 중복으로 간주하여 안전하게 처리
      return false;
    }
  }

  // 이메일 중복 확인
  Future<bool> isEmailAvailable(String email) async {
    try {
      final user = await getUserByEmail(email);
      return user == null; // 사용자가 없으면 사용 가능
    } catch (e) {
      print('이메일 중복 확인 실패: $e');
      // 오류 발생 시 중복으로 간주하여 안전하게 처리
      return false;
    }
  }

  // 사용자 프로필 업데이트
  Future<void> updateUserProfile(String uid, {
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (bio != null) updateData['bio'] = bio;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firebase.updateDocument('$_collectionName/$uid', updateData);
      
      print('실제 Firebase 사용자 프로필 업데이트 완료: $uid');
    } catch (e) {
      print('실제 Firebase 사용자 프로필 업데이트 실패: $e');
      throw Exception('프로필 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // MBTI 결과 업데이트
  Future<void> updateUserMBTI(String uid, String mbtiType) async {
    try {
      final user = await getUser(uid);
      if (user == null) {
        throw Exception('사용자를 찾을 수 없습니다.');
      }

      final updateData = {
        'mbtiType': mbtiType,
        'mbtiTestCount': user.mbtiTestCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firebase.updateDocument('$_collectionName/$uid', updateData);
      
      print('실제 Firebase MBTI 업데이트 완료: $uid -> $mbtiType');
    } catch (e) {
      print('실제 Firebase MBTI 업데이트 실패: $e');
      throw Exception('MBTI 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 설정 업데이트
  Future<void> updateUserPreferences(String uid, UserPreferences preferences) async {
    try {
      final updateData = {
        'preferences': preferences.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firebase.updateDocument('$_collectionName/$uid', updateData);
      
      print('실제 Firebase 사용자 설정 업데이트 완료: $uid');
    } catch (e) {
      print('실제 Firebase 사용자 설정 업데이트 실패: $e');
      throw Exception('설정 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 통계 업데이트
  Future<void> updateUserStats(String uid, UserStats stats) async {
    try {
      final updateData = {
        'stats': stats.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firebase.updateDocument('$_collectionName/$uid', updateData);
      
      print('실제 Firebase 사용자 통계 업데이트 완료: $uid');
    } catch (e) {
      print('실제 Firebase 사용자 통계 업데이트 실패: $e');
      throw Exception('통계 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 마지막 로그인 시간 업데이트
  Future<void> updateLastLogin(String uid) async {
    try {
      final updateData = {
        'stats.lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firebase.updateDocument('$_collectionName/$uid', updateData);
      
      print('실제 Firebase 마지막 로그인 시간 업데이트 완료: $uid');
    } catch (e) {
      print('실제 Firebase 마지막 로그인 시간 업데이트 실패: $e');
      // 로그인 시간 업데이트 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  // 채팅 카운트 증가
  Future<void> incrementChatCount(String uid) async {
    try {
      final user = await getUser(uid);
      if (user != null) {
        final updateData = {
          'stats.chatCount': user.stats.chatCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firebase.updateDocument('$_collectionName/$uid', updateData);
        
        print('실제 Firebase 채팅 카운트 증가 완료: $uid');
      }
    } catch (e) {
      print('실제 Firebase 채팅 카운트 증가 실패: $e');
      // 카운트 업데이트 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  // 사용자 검색 (이름 또는 이메일)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Firestore는 부분 검색이 제한적이므로 클라이언트 측에서 필터링
      final allUsers = await getRecentUsers(limit: 100);
      
      final searchResults = allUsers
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();

      print('실제 Firebase 사용자 검색 완료: $query -> ${searchResults.length}명');
      return searchResults;
    } catch (e) {
      print('실제 Firebase 사용자 검색 실패: $e');
      throw Exception('사용자 검색 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 존재 여부 확인
  Future<bool> userExists(String uid) async {
    try {
      final user = await getUser(uid);
      return user != null;
    } catch (e) {
      print('실제 Firebase 사용자 존재 확인 실패: $e');
      return false;
    }
  }

  // 사용자 실시간 스트림
  Stream<UserModel?> getUserStream(String uid) {
    return _firebase
        .getDocumentStream('$_collectionName/$uid')
        .map((snapshot) {
          if (snapshot.exists) {
            return _convertFirestoreToUserModel(snapshot);
          }
          return null;
        });
  }

  // 배치 업데이트 (여러 사용자 동시 업데이트)
  Future<void> batchUpdateUsers(List<Map<String, dynamic>> updates) async {
    try {
      final operations = updates.map((update) => {
        'type': 'update',
        'path': '$_collectionName/${update['uid']}',
        'data': update['data'],
      }).toList();

      await _firebase.batchWrite(operations);
      print('실제 Firebase 배치 업데이트 완료: ${updates.length}명');
    } catch (e) {
      print('실제 Firebase 배치 업데이트 실패: $e');
      throw Exception('배치 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // UserModel을 Firestore 데이터로 변환
  Map<String, dynamic> _convertUserModelToFirestore(UserModel user) {
    final data = user.toMap();
    
    // DateTime을 Timestamp로 변환
    data['createdAt'] = Timestamp.fromDate(user.createdAt);
    data['updatedAt'] = Timestamp.fromDate(user.updatedAt);
    
    // stats 내의 DateTime들도 변환
    if (data['stats'] != null) {
      final stats = data['stats'] as Map<String, dynamic>;
      if (stats['lastLoginAt'] != null) {
        stats['lastLoginAt'] = Timestamp.fromDate(user.stats.lastLoginAt);
      }
      if (stats['lastActiveAt'] != null && user.stats is UserStats) {
        // lastActiveAt이 UserStats에 있다면 변환
        // 현재 UserStats에는 없지만 향후 추가될 수 있음
      }
    }
    
    return data;
  }

  // Firestore 데이터를 UserModel로 변환
  UserModel _convertFirestoreToUserModel(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    // MBTI 정보 디버그 로그 추가
    print('=== Firestore 변환 디버그 ===');
    print('원본 Firestore 데이터: $data');
    print('mbtiType 필드: ${data['mbtiType']}');
    print('mbtiType 필드 타입: ${data['mbtiType']?.runtimeType}');
    print('mbtiTestCount 필드: ${data['mbtiTestCount']}');
    print('mbtiTestCount 필드 타입: ${data['mbtiTestCount']?.runtimeType}');
    print('============================');
    
    // Timestamp를 DateTime으로 변환
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
    }
    if (data['updatedAt'] is Timestamp) {
      data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
    }
    
    // stats 내의 Timestamp들도 변환
    if (data['stats'] != null) {
      final stats = data['stats'] as Map<String, dynamic>;
      if (stats['lastLoginAt'] is Timestamp) {
        stats['lastLoginAt'] = (stats['lastLoginAt'] as Timestamp).toDate();
      }
      if (stats['lastActiveAt'] is Timestamp) {
        stats['lastActiveAt'] = (stats['lastActiveAt'] as Timestamp).toDate();
      }
    }
    
    final userModel = UserModel.fromMap(data);
    print('변환된 UserModel.mbtiType: ${userModel.mbtiType}');
    print('변환된 UserModel.mbtiTestCount: ${userModel.mbtiTestCount}');
    print('============================');
    
    return userModel;
  }
}

