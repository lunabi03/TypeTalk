import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:typetalk/services/real_firebase_service.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/models/user_model.dart';

// 실제 Firebase 인증 서비스
class RealAuthService extends GetxService {
  static RealAuthService get instance => Get.find<RealAuthService>();

  // 현재 사용자
  Rx<User?> user = Rx<User?>(null);

  // 의존성 주입
  RealFirebaseService get _firebase => Get.find<RealFirebaseService>();
  RealUserRepository get _userRepository => Get.find<RealUserRepository>();

  @override
  void onInit() {
    super.onInit();
    // Firebase Auth 상태 변화 감지
    _firebase.authStateChanges.listen((User? firebaseUser) {
      user.value = firebaseUser;
      if (firebaseUser != null) {
        print('실제 Firebase 사용자 로그인: ${firebaseUser.uid}');
        _updateLastLogin(firebaseUser.uid);
      } else {
        print('실제 Firebase 사용자 로그아웃');
      }
    });
    
    // 현재 사용자 설정
    user.value = _firebase.currentUser;
    print('실제 Firebase Auth 서비스 초기화 완료');
  }

  // 이메일/비밀번호 회원가입
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Firebase Auth 회원가입
      final credential = await _firebase.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Firestore에 사용자 프로필 정보 저장
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          mbtiType: null,
          mbtiTestCount: 0,
          loginProvider: 'email',
        );

        await _userRepository.createUser(userModel);
        print('실제 Firebase 회원가입 및 프로필 저장 완료: ${credential.user!.uid}');
        
        Get.snackbar('성공', '회원가입이 완료되었습니다!');
        return credential;
      }

      return null;
    } catch (e) {
      print('실제 Firebase 회원가입 실패: $e');
      Get.snackbar('오류', '회원가입 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }

  // 이메일/비밀번호 로그인
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebase.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 마지막 로그인 시간 업데이트
        await _updateLastLogin(credential.user!.uid);
        print('실제 Firebase 로그인 완료: ${credential.user!.uid}');
        
        Get.snackbar('성공', '로그인되었습니다!');
        return credential;
      }

      return null;
    } catch (e) {
      print('실제 Firebase 로그인 실패: $e');
      Get.snackbar('오류', '로그인 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _firebase.signOut();
      user.value = null;
      print('실제 Firebase 로그아웃 완료');
      Get.snackbar('알림', '로그아웃되었습니다.');
    } catch (e) {
      print('실제 Firebase 로그아웃 실패: $e');
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebase.sendPasswordResetEmail(email);
      Get.snackbar('성공', '비밀번호 재설정 이메일이 발송되었습니다.');
    } catch (e) {
      print('실제 Firebase 비밀번호 재설정 실패: $e');
      Get.snackbar('오류', '비밀번호 재설정 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // Google 로그인 (데모 모드 - 실제 구현 시 google_sign_in 패키지 필요)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 실제 Google 로그인 구현은 google_sign_in 패키지가 필요합니다.
      // 여기서는 데모용으로 처리합니다.
      Get.snackbar('알림', 'Google 로그인은 추가 설정이 필요합니다.');
      
      // 데모용 Google 사용자 생성
      final demoEmail = 'demo.google.${DateTime.now().millisecondsSinceEpoch}@gmail.com';
      return await signUpWithEmailAndPassword(
        email: demoEmail,
        password: 'demo123456',
        name: 'Google 사용자',
      );
    } catch (e) {
      print('Google 로그인 실패: $e');
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }

  // Apple 로그인 (데모 모드 - 실제 구현 시 sign_in_with_apple 패키지 필요)
  Future<UserCredential?> signInWithApple() async {
    try {
      // 실제 Apple 로그인 구현은 sign_in_with_apple 패키지가 필요합니다.
      // 여기서는 데모용으로 처리합니다.
      Get.snackbar('알림', 'Apple 로그인은 추가 설정이 필요합니다.');
      
      // 데모용 Apple 사용자 생성
      final demoEmail = 'demo.apple.${DateTime.now().millisecondsSinceEpoch}@icloud.com';
      return await signUpWithEmailAndPassword(
        email: demoEmail,
        password: 'demo123456',
        name: 'Apple 사용자',
      );
    } catch (e) {
      print('Apple 로그인 실패: $e');
      Get.snackbar('오류', 'Apple 로그인 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }

  // 사용자 프로필 정보 가져오기
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (user.value?.uid != null) {
        final userModel = await _userRepository.getUser(user.value!.uid);
        return userModel?.toMap();
      }
      return null;
    } catch (e) {
      print('실제 Firebase 사용자 프로필 조회 실패: $e');
      return null;
    }
  }

  // 사용자 프로필 업데이트
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (user.value?.uid != null) {
        await _userRepository.updateUserProfile(
          user.value!.uid,
          name: data['name'],
          bio: data['bio'],
          profileImageUrl: data['profileImageUrl'],
        );
        print('실제 Firebase 사용자 프로필 업데이트 완료: ${user.value!.uid}');
      }
    } catch (e) {
      print('실제 Firebase 사용자 프로필 업데이트 실패: $e');
      throw Exception('프로필 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 마지막 로그인 시간 업데이트
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _userRepository.updateLastLogin(uid);
    } catch (e) {
      print('마지막 로그인 시간 업데이트 실패: $e');
      // 로그인 시간 업데이트 실패는 치명적이지 않으므로 무시
    }
  }

  // 현재 로그인 상태 확인
  bool get isLoggedIn => user.value != null;

  // 현재 사용자 UID
  String? get currentUserId => user.value?.uid;

  // 현재 사용자 이메일
  String? get currentUserEmail => user.value?.email;

  // 현재 사용자 이름
  String? get currentUserName => user.value?.displayName;

  // 사용자 삭제 (회원 탈퇴)
  Future<void> deleteUser() async {
    try {
      if (user.value?.uid != null) {
        final uid = user.value!.uid;
        
        // Firestore에서 사용자 데이터 삭제
        await _userRepository.deleteUser(uid);
        
        // Firebase Auth에서 사용자 삭제
        await user.value!.delete();
        
        user.value = null;
        print('실제 Firebase 사용자 삭제 완료: $uid');
        Get.snackbar('완료', '계정이 삭제되었습니다.');
      }
    } catch (e) {
      print('실제 Firebase 사용자 삭제 실패: $e');
      Get.snackbar('오류', '계정 삭제 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 이메일 인증 발송
  Future<void> sendEmailVerification() async {
    try {
      if (user.value != null && !user.value!.emailVerified) {
        await user.value!.sendEmailVerification();
        Get.snackbar('성공', '인증 이메일이 발송되었습니다.');
      }
    } catch (e) {
      print('이메일 인증 발송 실패: $e');
      Get.snackbar('오류', '이메일 인증 발송 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // 이메일 인증 상태 확인
  bool get isEmailVerified => user.value?.emailVerified ?? false;

  // 프로필 새로고침
  Future<void> reloadUser() async {
    try {
      if (user.value != null) {
        await user.value!.reload();
        user.value = _firebase.currentUser;
      }
    } catch (e) {
      print('사용자 정보 새로고침 실패: $e');
    }
  }
}

