import 'package:get/get.dart';
import 'package:typetalk/services/firestore_service.dart';
import 'package:typetalk/models/user_model.dart';

// 사용자 데이터 저장소
class UserRepository extends GetxService {
  static UserRepository get instance => Get.find<UserRepository>();

  DemoFirestoreService get _firestore => Get.find<DemoFirestoreService>();
  static const String _collectionName = 'users';

  // 사용자 생성
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .set(user.toMap());
      
      print('사용자 생성 완료: ${user.uid}');
    } catch (e) {
      print('사용자 생성 실패: $e');
      throw Exception('사용자 생성 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 조회
  Future<UserModel?> getUser(String uid) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .get();

      if (snapshot.exists) {
        return UserModel.fromSnapshot(snapshot);
      }
      return null;
    } catch (e) {
      print('사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 업데이트
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .update(user.toMap());
      
      print('사용자 업데이트 완료: ${user.uid}');
    } catch (e) {
      print('사용자 업데이트 실패: $e');
      throw Exception('사용자 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 삭제
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .delete();
      
      print('사용자 삭제 완료: $uid');
    } catch (e) {
      print('사용자 삭제 실패: $e');
      throw Exception('사용자 삭제 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 이메일로 사용자 조회
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.isNotEmpty) {
        return UserModel.fromSnapshot(querySnapshot.first);
      }
      return null;
    } catch (e) {
      print('이메일로 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // MBTI 타입으로 사용자 목록 조회
  Future<List<UserModel>> getUsersByMBTI(String mbtiType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('mbtiType', isEqualTo: mbtiType)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot
          .map((snapshot) => UserModel.fromSnapshot(snapshot))
          .toList();
    } catch (e) {
      print('MBTI로 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 최근 가입한 사용자 목록 조회
  Future<List<UserModel>> getRecentUsers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot
          .map((snapshot) => UserModel.fromSnapshot(snapshot))
          .toList();
    } catch (e) {
      print('최근 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 활성 사용자 목록 조회 (최근 로그인 기준)
  Future<List<UserModel>> getActiveUsers({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('stats.lastLoginAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot
          .map((snapshot) => UserModel.fromSnapshot(snapshot))
          .toList();
    } catch (e) {
      print('활성 사용자 조회 실패: $e');
      throw Exception('사용자 조회 중 오류가 발생했습니다: ${e.toString()}');
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
      
      updateData['updatedAt'] = DateTime.now();

      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .update(updateData);
      
      print('사용자 프로필 업데이트 완료: $uid');
    } catch (e) {
      print('사용자 프로필 업데이트 실패: $e');
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
        'updatedAt': DateTime.now(),
      };

      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .update(updateData);
      
      print('MBTI 업데이트 완료: $uid -> $mbtiType');
    } catch (e) {
      print('MBTI 업데이트 실패: $e');
      throw Exception('MBTI 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 설정 업데이트
  Future<void> updateUserPreferences(String uid, UserPreferences preferences) async {
    try {
      final updateData = {
        'preferences': preferences.toMap(),
        'updatedAt': DateTime.now(),
      };

      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .update(updateData);
      
      print('사용자 설정 업데이트 완료: $uid');
    } catch (e) {
      print('사용자 설정 업데이트 실패: $e');
      throw Exception('설정 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 통계 업데이트
  Future<void> updateUserStats(String uid, UserStats stats) async {
    try {
      final updateData = {
        'stats': stats.toMap(),
        'updatedAt': DateTime.now(),
      };

      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .update(updateData);
      
      print('사용자 통계 업데이트 완료: $uid');
    } catch (e) {
      print('사용자 통계 업데이트 실패: $e');
      throw Exception('통계 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 마지막 로그인 시간 업데이트
  Future<void> updateLastLogin(String uid) async {
    try {
      final updateData = {
        'stats.lastLoginAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .update(updateData);
      
      print('마지막 로그인 시간 업데이트 완료: $uid');
    } catch (e) {
      print('마지막 로그인 시간 업데이트 실패: $e');
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
          'updatedAt': DateTime.now(),
        };

        await _firestore
            .collection(_collectionName)
            .doc(uid)
            .update(updateData);
        
        print('채팅 카운트 증가 완료: $uid');
      }
    } catch (e) {
      print('채팅 카운트 증가 실패: $e');
      // 카운트 업데이트 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  // 사용자 검색 (이름 또는 이메일)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // 데모에서는 간단한 문자열 검색 구현
      final allUsers = await _firestore
          .collection(_collectionName)
          .get();

      final searchResults = allUsers
          .map((snapshot) => UserModel.fromSnapshot(snapshot))
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();

      print('사용자 검색 완료: $query -> ${searchResults.length}명');
      return searchResults;
    } catch (e) {
      print('사용자 검색 실패: $e');
      throw Exception('사용자 검색 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 사용자 존재 여부 확인
  Future<bool> userExists(String uid) async {
    try {
      final user = await getUser(uid);
      return user != null;
    } catch (e) {
      print('사용자 존재 확인 실패: $e');
      return false;
    }
  }

  // 사용자 실시간 스트림
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(_collectionName)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromSnapshot(snapshot);
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

      await _firestore.batch(operations);
      print('배치 업데이트 완료: ${updates.length}명');
    } catch (e) {
      print('배치 업데이트 실패: $e');
      throw Exception('배치 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }
}
