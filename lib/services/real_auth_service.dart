import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:typetalk/services/real_firebase_service.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  // 이메일/비밀번호 회원가입 (별칭)
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    return await signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
    );
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
      // 로그인 실패 시 예외를 다시 throw하여 AuthController에서 처리하도록 함
      throw e;
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

  // Google 로그인 (실제 구현)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign In 인스턴스 생성 - profile 스코프 제거
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'], // profile 스코프 제거하여 People API 호출 방지
      );
      
      // Google 로그인 진행
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        throw Exception('Google 로그인이 취소되었습니다.');
      }
      
      print('Google 로그인 사용자 정보:');
      print('  - Email: ${googleUser.email}');
      print('  - Display Name: ${googleUser.displayName}');
      print('  - Photo URL: ${googleUser.photoUrl}');
      print('  - ID: ${googleUser.id}');
      
      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('Google 인증 정보:');
      print('  - Access Token: ${googleAuth.accessToken != null ? "있음" : "없음"}');
      print('  - ID Token: ${googleAuth.idToken != null ? "있음" : "없음"}');
      print('  - Server Auth Code: ${googleAuth.serverAuthCode != null ? "있음" : "없음"}');
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('인증 정보가 부족합니다. Firebase Auth로 직접 로그인을 시도합니다.');
        
        // Firebase Auth로 직접 로그인 시도
        try {
          final userCredential = await _firebase.signInWithCredential(
            GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            ),
          );
          
          if (userCredential.user != null) {
            print('Firebase Auth 로그인 성공: ${userCredential.user!.uid}');
            return await _handleSuccessfulGoogleLogin(userCredential, googleUser);
          }
        } catch (firebaseError) {
          print('Firebase Auth 로그인 실패: $firebaseError');
          throw Exception('Firebase 인증에 실패했습니다: ${firebaseError.toString()}');
        }
        
        throw Exception('Google 인증 정보를 가져올 수 없습니다.');
      }
      
      // Firebase Auth 크레덴셜 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Firebase Auth로 로그인
      final userCredential = await _firebase.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return await _handleSuccessfulGoogleLogin(userCredential, googleUser);
      }
      
      return null;
    } catch (e) {
      print('Google 로그인 실패: $e');
      
      // 구체적인 오류 메시지 제공
      if (e.toString().contains('network_error')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception('Google 로그인이 취소되었습니다.');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Google 로그인에 실패했습니다. 다시 시도해주세요.');
      } else if (e.toString().contains('play_services_not_available')) {
        throw Exception('Google Play 서비스가 필요합니다.');
      } else if (e.toString().contains('Google 인증 정보를 가져올 수 없습니다')) {
        throw Exception('Google 인증 정보를 가져올 수 없습니다. 다시 시도해주세요.');
      } else {
        throw Exception('Google 로그인 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  // Google 로그인 성공 처리
  Future<UserCredential?> _handleSuccessfulGoogleLogin(UserCredential userCredential, GoogleSignInAccount googleUser) async {
    // Firestore에 사용자 정보가 있는지 확인
    final existingUser = await _userRepository.getUser(userCredential.user!.uid);
    
    if (existingUser == null) {
      // 새로운 사용자인 경우 Firestore에 사용자 정보 저장
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? googleUser.email,
        name: userCredential.user!.displayName ?? googleUser.displayName ?? 'Google 사용자',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mbtiType: null,
        mbtiTestCount: 0,
        loginProvider: 'google',
        profileImageUrl: null, // 기본 이미지 없음
      );
      
      await _userRepository.createUser(userModel);
      print('Google 로그인으로 새 사용자 생성: ${userCredential.user!.uid}');
    } else {
      // 기존 사용자인 경우 마지막 로그인 시간 업데이트
      await _updateLastLogin(userCredential.user!.uid);
      print('Google 로그인으로 기존 사용자 로그인: ${userCredential.user!.uid}');
    }
    
    Get.snackbar('성공', 'Google 로그인이 완료되었습니다!');
    return userCredential;
  }

  // Apple 로그인 (실제 구현)
  Future<UserCredential?> signInWithApple() async {
    try {
      // Apple 로그인 가능 여부 확인
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple 로그인이 지원되지 않는 기기입니다.');
      }
      
      // Apple 로그인 진행
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      if (credential.identityToken == null) {
        throw Exception('Apple 로그인 인증 정보를 가져올 수 없습니다.');
      }
      
      // Firebase Auth 크레덴셜 생성
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      
      // Firebase Auth로 로그인
      final userCredential = await _firebase.signInWithCredential(oauthCredential);
      
      if (userCredential.user != null) {
        // Firestore에 사용자 정보가 있는지 확인
        final existingUser = await _userRepository.getUser(userCredential.user!.uid);
        
        if (existingUser == null) {
          // 새로운 사용자인 경우 Firestore에 사용자 정보 저장
          String userName = 'Apple 사용자';
          if (credential.givenName != null && credential.familyName != null) {
            userName = '${credential.givenName} ${credential.familyName}';
          }
          
          final userModel = UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            mbtiType: null,
            mbtiTestCount: 0,
            loginProvider: 'apple',
          );
          
          await _userRepository.createUser(userModel);
          print('Apple 로그인으로 새 사용자 생성: ${userCredential.user!.uid}');
        } else {
          // 기존 사용자인 경우 마지막 로그인 시간 업데이트
          await _updateLastLogin(userCredential.user!.uid);
          print('Apple 로그인으로 기존 사용자 로그인: ${userCredential.user!.uid}');
        }
        
        Get.snackbar('성공', 'Apple 로그인이 완료되었습니다!');
        return userCredential;
      }
      
      return null;
    } catch (e) {
      print('Apple 로그인 실패: $e');
      
      // 구체적인 오류 메시지 제공
      if (e.toString().contains('not_interactive')) {
        throw Exception('Apple 로그인을 다시 시도해주세요.');
      } else if (e.toString().contains('canceled')) {
        throw Exception('Apple 로그인이 취소되었습니다.');
      } else if (e.toString().contains('failed')) {
        throw Exception('Apple 로그인에 실패했습니다. 다시 시도해주세요.');
      } else if (e.toString().contains('not_available')) {
        throw Exception('Apple 로그인이 지원되지 않는 기기입니다.');
      } else {
        throw Exception('Apple 로그인 중 오류가 발생했습니다: ${e.toString()}');
      }
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

