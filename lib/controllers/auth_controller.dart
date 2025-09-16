import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:typetalk/routes/app_routes.dart';

// 실제 Firebase 서비스들 (활성화)
import 'package:typetalk/services/real_auth_service.dart';
import 'package:typetalk/services/real_user_repository.dart';

import 'package:typetalk/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for User model

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();
  
  RealAuthService get _authService => Get.find<RealAuthService>();
  RealUserRepository get _userRepository => Get.find<RealUserRepository>();
  
  // 사용자 정보 (실제 Firebase)
  RxString currentUserId = ''.obs;
  RxString currentUserEmail = ''.obs;
  RxString currentUserName = ''.obs;
  RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  
  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isSigningIn = false.obs;
  RxBool isSigningUp = false.obs;
  
  // 차단된 사용자 플래그
  RxBool isBlockedUser = false.obs;
  // 회원가입 화면에서 소셜 연동 여부 플래그
  RxBool isSignupFlow = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 실제 Firebase 모드 - 사용자 상태 감지
    _initRealUser();
  }
  
  @override
  void onReady() {
    super.onReady();
    // 실제 Firebase 모드 - 초기화 완료
    print('AuthController 초기화 완료 (실제 Firebase 모드)');
  }
  
  // 실제 Firebase 사용자 초기화
  void _initRealUser() {
    // Firebase Auth 상태 변화 감지
    ever(_authService.user, (User? firebaseUser) async {
      if (firebaseUser != null) {
        _onUserLogin(firebaseUser);
      } else {
        // 차단된 사용자가 아닌 경우에만 로그아웃 처리
        if (!isBlockedUser.value) {
          _onUserLogout();
        }
      }
    });
    
    // 현재 사용자 상태 확인
    final currentUser = _authService.user.value;
    if (currentUser != null) {
      _onUserLogin(currentUser);
    } else {
      // 로그인되지 않은 경우 초기화만 완료
      print('로그인되지 않은 사용자 - 초기화 완료');
      // 초기화 시에는 네비게이션하지 않음 (main.dart에서 initialRoute로 처리)
    }
  }

  // 사용자 로그인 시 호출
  void _onUserLogin(User firebaseUser) async {
    // 관리자 해제 전까지는 차단 이메일 로그인 불가
    final userEmail = firebaseUser.email ?? '';
    final blockedUntil = await _userRepository.getEmailBlockedUntil(userEmail);
    if (blockedUntil != null && blockedUntil.isAfter(DateTime.now())) {
      final remain = blockedUntil.difference(DateTime.now()).inDays + 1;
      // 강제 로그아웃 후 안내
      try { await _authService.signOut(); } catch (_) {}
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar('로그인 제한', '회원탈퇴 처리된 계정입니다. ${remain}일 후 또는 관리자 해제 후 이용 가능합니다.');
      return;
    }
    print('차단 아님 - 로그인 진행');
    print('==================');
    
    currentUserId.value = firebaseUser.uid;
    currentUserEmail.value = firebaseUser.email ?? '';
    currentUserName.value = firebaseUser.displayName ?? '';
    
    // Firestore에서 사용자 프로필 로드 후 분기
    loadUserProfile().then((_) async {
      // userModel이 없거나 프로필 문서가 없으면 회원가입 유도 (메인 화면 이동 금지)
      if (userModel.value == null) {
        final exists = await _userRepository.userExists(firebaseUser.uid);
        if (!exists) {
          // 1) 동일 이메일로 기존 계정(다른 uid)이 있는지 확인하여 프로필 매칭/이전 처리
          try {
            final email = (firebaseUser.email ?? '').trim();
            if (email.isNotEmpty) {
              final existingByEmail = await _userRepository.getUserByEmail(email);
              if (existingByEmail != null) {
                // 기존 이메일 계정의 프로필을 현재 Google uid로 복제 생성
                final migrated = existingByEmail.copyWith(
                  uid: firebaseUser.uid,
                  updatedAt: DateTime.now(),
                  loginProvider: 'google',
                  // displayName이 더 풍부하면 보강
                  name: (firebaseUser.displayName != null && firebaseUser.displayName!.trim().isNotEmpty)
                      ? firebaseUser.displayName
                      : existingByEmail.name,
                );
                await _userRepository.createUser(migrated);
                // 마지막 로그인 갱신 시도 (비치명적)
                try { await _userRepository.updateLastLogin(firebaseUser.uid); } catch (_) {}

                // 로컬 상태 업데이트 후 메인으로 이동
                userModel.value = migrated;
                userProfile.value = {
                  'name': migrated.name,
                  'email': migrated.email,
                  'mbti': migrated.mbtiType,
                  'bio': migrated.bio ?? '자기소개를 입력해주세요.',
                  'age': migrated.age,
                  'profileImageUrl': migrated.profileImageUrl,
                  'mbtiTestCount': migrated.mbtiTestCount,
                  'lastMBTITestDate': migrated.lastMBTITestDate,
                  'createdAt': migrated.createdAt,
                };
                Get.snackbar('성공', '기존 이메일 계정을 Google로 연결했습니다.');
                Get.offNamed(AppRoutes.start);
                return;
              }
            }
          } catch (e) {
            print('이메일 기반 기존 계정 매칭 시도 중 오류: $e');
            // 계속 진행 (아래 분기)
          }

          // 신규 사용자: 회원가입 화면에서 구글 연동으로 진입한 경우 자동 프로필 생성
          if (isSignupFlow.value) {
            try {
              // 신규 사용자 프로필 생성
              final newUser = UserModel(
                uid: firebaseUser.uid,
                email: (firebaseUser.email ?? '').trim(),
                name: (firebaseUser.displayName ?? '사용자'),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                loginProvider: 'google',
                profileImageUrl: firebaseUser.photoURL,
              );
              await _userRepository.createUser(newUser);

              // 로컬 상태 반영
              userModel.value = newUser;
              userProfile.value = {
                'name': newUser.name,
                'email': newUser.email,
                'mbti': newUser.mbtiType,
                'bio': newUser.bio ?? '자기소개를 입력해주세요.',
                'age': newUser.age,
                'profileImageUrl': newUser.profileImageUrl,
                'mbtiTestCount': newUser.mbtiTestCount,
                'lastMBTITestDate': newUser.lastMBTITestDate,
                'createdAt': newUser.createdAt,
              };

              // 회원가입 완료 처리
              isSignupFlow.value = false; // 플로우 플래그 리셋
              Get.snackbar('성공', 'Google 계정으로 회원가입되었습니다.');
              Get.offNamed(AppRoutes.start);
              return;
            } catch (e) {
              // 자동 생성 실패 시 기존 안내로 폴백
              print('Google 신규 사용자 자동 프로필 생성 실패: $e');
            }
          }

          // (폴백) 회원가입 유도 팝업
          try { await _authService.signOut(); } catch (_) {}
          Get.offAllNamed(AppRoutes.login);
          Get.dialog(
            AlertDialog(
              title: const Text('회원가입 필요'),
              content: const Text('해당 이메일로 생성된 프로필이 없습니다. 회원가입을 먼저 진행해주세요.'),
              actions: [
                TextButton(
                  onPressed: () { Get.back(); },
                  child: const Text('닫기'),
                ),
                TextButton(
                  onPressed: () { Get.back(); Get.toNamed(AppRoutes.signup); },
                  child: const Text('회원가입으로 이동'),
                ),
              ],
            ),
            barrierDismissible: true,
          );
          return;
        }
      }
      
      // 정상 로그인 성공 메시지 표시
      Get.snackbar('성공', '로그인 되었습니다.');
      
      // 기존 사용자이면 메인으로 이동
      Get.offNamed(AppRoutes.start);
    });
    
    print('실제 Firebase 사용자 로그인: ${firebaseUser.uid}');
  }

  // 사용자 로그아웃 시 호출
  void _onUserLogout() {
    // 차단된 사용자인 경우 아무것도 하지 않음
    if (isBlockedUser.value) {
      print('차단된 사용자 로그아웃 - 메시지 표시 안 함');
      return;
    }
    
    currentUserId.value = '';
    currentUserEmail.value = '';
    currentUserName.value = '';
    userProfile.value = <String, dynamic>{};
    userModel.value = null;
    
    // 정상 로그아웃 메시지 표시
    Get.snackbar('알림', '로그아웃 되었습니다.');
    
    // 로그아웃 시 로그인 화면으로 이동
    Get.offNamed(AppRoutes.login);
    
    print('실제 Firebase 사용자 로그아웃');
  }

  // 인증이 필요한 페이지 접근 가드
  bool requireAuth({String? redirectTo}) {
    if (!isLoggedIn) {
      // 로그인되지 않은 경우 로그인 페이지로 리다이렉트
      Get.snackbar('알림', '로그인이 필요한 서비스입니다.');
      Get.offNamed(AppRoutes.login);
      return false;
    }
    return true;
  }

  // 로그인 후 리다이렉트
  void _redirectToMain() {
    Get.offNamed(AppRoutes.start);
  }

  // 로그아웃 후 리다이렉트
  void _redirectToLogin() {
    Get.offNamed(AppRoutes.login);
  }

  // 사용자 프로필 로드 (실제 Firebase)
  Future<void> loadUserProfile() async {
    if (currentUserId.value.isEmpty) {
      print('로그인된 사용자가 없습니다.');
      return;
    }

    try {
      isLoading.value = true;
      
      // Firestore에서 사용자 프로필 로드
      final userData = await _userRepository.getUser(currentUserId.value);
      if (userData != null) {
        userModel.value = userData;
        
        // MBTI 정보 디버그 로그 추가
        print('=== MBTI 디버그 정보 ===');
        print('userData.mbtiType: ${userData.mbtiType}');
        print('userData.mbtiType 타입: ${userData.mbtiType.runtimeType}');
        print('userData.mbtiTestCount: ${userData.mbtiTestCount}');
        print('userData.age: ${userData.age}');
        print('userData.gender: ${userData.gender}');
        print('userData.toMap(): ${userData.toMap()}');
        print('=======================');
        
        userProfile.value = {
          'name': userData.name,
          'email': userData.email,
          'mbti': userData.mbtiType,
          'bio': userData.bio ?? '자기소개를 입력해주세요.',
          'age': userData.age,
          'profileImageUrl': userData.profileImageUrl,
          'mbtiTestCount': userData.mbtiTestCount ?? 0,
          'lastMBTITestDate': userData.lastMBTITestDate,
          'createdAt': userData.createdAt,
        };
        
        // userProfile에 저장된 MBTI 정보 확인
        print('userProfile에 저장된 MBTI: ${userProfile['mbti']}');
        print('currentUserMBTI getter 결과: ${currentUserMBTI}');
        
        // MBTI 정보가 제대로 로드되었는지 확인하고 강제로 업데이트
        if (userData.mbtiType != null && userData.mbtiType!.isNotEmpty) {
          print('MBTI 정보 강제 업데이트: ${userData.mbtiType}');
          // userProfile을 강제로 업데이트하여 반응성 보장
          userProfile.refresh();
        }
        
        print('사용자 프로필 로드 완료: ${userData.name}, MBTI: ${userData.mbtiType}, 테스트 횟수: ${userData.mbtiTestCount ?? 0}');
        print('가입일 정보: ${userData.createdAt} (타입: ${userData.createdAt.runtimeType})');
      } else {
        print('사용자 프로필을 찾을 수 없습니다.');
      }
      
    } catch (e) {
      print('프로필 로드 실패: $e');
      Get.snackbar('오류', '프로필 로드에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 사용자 프로필 업데이트 (실제 Firebase)
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUserId.value.isEmpty) {
      print('로그인된 사용자가 없습니다.');
      return;
    }

    try {
      isLoading.value = true;
      
      // Firestore에 사용자 프로필 업데이트
      await _userRepository.updateUserFields(currentUserId.value, data);
      
      // 로컬 프로필도 업데이트
      userProfile.value = {...userProfile.value, ...data};
      
      print('프로필 업데이트 완료: $data');
      Get.snackbar('성공', '프로필이 업데이트되었습니다.');
    } catch (e) {
      print('프로필 업데이트 실패: $e');
      Get.snackbar('오류', '프로필 업데이트에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 게터들
  bool get isLoggedIn => currentUserId.value.isNotEmpty;
  String? get userId => currentUserId.value.isEmpty ? null : currentUserId.value;
  String? get userEmail => currentUserEmail.value.isEmpty ? null : currentUserEmail.value;
  String? get userName => userProfile['name'] ?? currentUserName.value;
  String? get currentUserMBTI => userProfile['mbti'];

  // 이름 중복 확인 (실제 Firebase)
  Future<bool> checkNameAvailability(String name) async {
    try {
      isLoading.value = true;
      
      final isAvailable = await _userRepository.isNameAvailable(name);
      
      if (isAvailable) {
        Get.snackbar(
          '사용 가능', 
          '"$name"은(는) 사용 가능한 이름입니다.',
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
          colorText: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          '사용 불가', 
          '"$name"은(는) 이미 사용 중인 이름입니다.',
          backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
          colorText: const Color(0xFFFF9800),
          duration: const Duration(seconds: 3),
        );
      }
      
      return isAvailable;
    } catch (e) {
      print('이름 중복 확인 실패: $e');
      Get.snackbar(
        '오류', 
        '이름 중복 확인 중 오류가 발생했습니다.',
        backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
        colorText: const Color(0xFFFF0000),
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 이메일 중복 확인 (실제 Firebase)
  Future<bool> checkEmailAvailability(String email) async {
    try {
      isLoading.value = true;
      
      final isAvailable = await _userRepository.isEmailAvailable(email);
      
      if (isAvailable) {
        Get.snackbar(
          '사용 가능', 
          '"$email"은(는) 사용 가능한 이메일입니다.',
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
          colorText: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          '사용 불가', 
          '"$email"은(는) 이미 사용 중인 이메일입니다.',
          backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
          colorText: const Color(0xFFFF9800),
          duration: const Duration(seconds: 3),
        );
      }
      
      return isAvailable;
    } catch (e) {
      print('이메일 중복 확인 실패: $e');
      Get.snackbar(
        '오류', 
        '이메일 중복 확인 중 오류가 발생했습니다.',
        backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
        colorText: const Color(0xFFFF0000),
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 사용자 MBTI 업데이트 (실제 Firebase)
  Future<void> updateUserMBTI(String mbtiType) async {
    if (currentUserId.value.isEmpty) {
      print('로그인된 사용자가 없습니다.');
      return;
    }

    try {
      isLoading.value = true;
      
      // 현재 MBTI 테스트 완료 횟수 가져오기
      int currentTestCount = 0;
      if (userProfile['mbtiTestCount'] != null) {
        currentTestCount = (userProfile['mbtiTestCount'] is int) 
            ? userProfile['mbtiTestCount'] 
            : int.tryParse(userProfile['mbtiTestCount'].toString()) ?? 0;
      }
      
      // MBTI 테스트 완료 횟수 증가
      int newTestCount = currentTestCount + 1;
      
      // Firestore에 MBTI와 테스트 완료 횟수 업데이트
      await _userRepository.updateUserFields(currentUserId.value, {
        'mbtiType': mbtiType,
        'mbtiTestCount': newTestCount,
        'lastMBTITestDate': DateTime.now().toIso8601String(),
      });
      
      // 로컬 프로필도 업데이트
      userProfile['mbti'] = mbtiType;
      userProfile['mbtiTestCount'] = newTestCount;
      userProfile['lastMBTITestDate'] = DateTime.now().toIso8601String();
      userProfile.refresh();
      
      print('MBTI 업데이트 완료: $mbtiType, 테스트 완료 횟수: $newTestCount');
      Get.snackbar('성공', 'MBTI가 업데이트되었습니다.');
    } catch (e) {
      print('MBTI 업데이트 실패: $e');
      Get.snackbar('오류', 'MBTI 업데이트에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 이메일 로그인 (실제 Firebase)
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isSigningIn.value = true;
      // 차단 검사 제거: Firebase Auth 로그인만 시도
      // Firebase Auth 로그인
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      
      // 네비게이션은 Auth 상태 리스너(_onUserLogin)에서
      // 차단 검사 후에만 진행하도록 위임
      
    } catch (e) {
      print('로그인 실패: $e');
      // Firebase Auth 예외에 따른 적절한 오류 메시지 표시
      String errorMessage = _getLoginErrorMessage(e);
      Get.snackbar('로그인 실패', errorMessage);
      // 로그인 실패 시에는 메인 화면으로 이동하지 않음
    } finally {
      isSigningIn.value = false;
      // 로그인 시도 후에는 회원가입 플래그를 항상 OFF로 리셋
      isSignupFlow.value = false;
    }
  }

  // 로그인 오류 메시지 처리 (개선된 버전)
  String _getLoginErrorMessage(dynamic error) {
    if (error is Exception) {
      String errorString = error.toString();
      
      // Firebase Auth 예외 코드별 메시지
      if (errorString.contains('등록되지 않은 이메일입니다')) {
        return '등록되지 않은 이메일입니다. 회원가입을 먼저 진행해주세요.';
      } else if (errorString.contains('비밀번호가 올바르지 않습니다')) {
        return '비밀번호가 올바르지 않습니다. 다시 확인해주세요.';
      } else if (errorString.contains('올바른 이메일 형식을 입력해주세요')) {
        return '올바른 이메일 형식을 입력해주세요. (예: user@example.com)';
      } else if (errorString.contains('비활성화된 계정입니다')) {
        return '비활성화된 계정입니다. 관리자에게 문의해주세요.';
      } else if (errorString.contains('너무 많은 로그인 시도가 있었습니다')) {
        return '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      } else if (errorString.contains('이메일/비밀번호 로그인이 비활성화되어 있습니다')) {
        return '이메일/비밀번호 로그인이 비활성화되어 있습니다. Firebase 콘솔에서 설정을 확인해주세요.';
      } else if (errorString.contains('네트워크 연결을 확인해주세요')) {
        return '네트워크 연결을 확인해주세요. 인터넷 연결 상태를 점검해보세요.';
      } else if (errorString.contains('Firebase 내부 오류가 발생했습니다')) {
        return 'Firebase 서비스에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      } else if (errorString.contains('Firebase 할당량이 초과되었습니다')) {
        return 'Firebase 서비스 사용량이 초과되었습니다. 잠시 후 다시 시도해주세요.';
      } else if (errorString.contains('앱이 Firebase에 인증되지 않았습니다')) {
        return '앱 인증에 문제가 발생했습니다. 개발자에게 문의해주세요.';
      } else if (errorString.contains('로그인 세션이 만료되었습니다')) {
        return '로그인 세션이 만료되었습니다. 다시 로그인해주세요.';
      } else if (errorString.contains('보안을 위해 다시 로그인이 필요합니다')) {
        return '보안을 위해 다시 로그인이 필요합니다. 비밀번호를 다시 입력해주세요.';
      }
      
      // 일반적인 오류 메시지
      return '로그인 중 오류가 발생했습니다: ${errorString.replaceAll('Exception: ', '')}';
    }
    
    // 예외가 아닌 경우
    return '로그인 중 예상치 못한 오류가 발생했습니다. 다시 시도해주세요.';
  }

  // 회원가입 (실제 Firebase)
  Future<void> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      isSigningUp.value = true;
      
      // Firebase Auth 회원가입
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      
      _redirectToMain();
      Get.snackbar('성공', '회원가입이 완료되었습니다!');
      
    } catch (e) {
      print('회원가입 실패: $e');
      
      // 회원가입 오류 메시지 처리
      String errorMessage = _getSignupErrorMessage(e);
      Get.snackbar(
        '회원가입 실패', 
        errorMessage,
        backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
        colorText: const Color(0xFFFF0000),
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSigningUp.value = false;
    }
  }

  // 회원가입 오류 메시지 처리
  String _getSignupErrorMessage(dynamic error) {
    if (error is Exception) {
      String errorString = error.toString();
      
      // Firebase Auth 예외 코드별 메시지
      if (errorString.contains('비밀번호가 너무 약합니다')) {
        return '비밀번호가 너무 약합니다. 최소 6자 이상으로 설정해주세요.';
      } else if (errorString.contains('이미 사용 중인 이메일입니다')) {
        return '이미 사용 중인 이메일입니다. 다른 이메일을 사용하거나 로그인해주세요.';
      } else if (errorString.contains('올바른 이메일 형식을 입력해주세요')) {
        return '올바른 이메일 형식을 입력해주세요. (예: user@example.com)';
      } else if (errorString.contains('이메일/비밀번호 로그인이 비활성화되어 있습니다')) {
        return '이메일/비밀번호 로그인이 비활성화되어 있습니다. Firebase 콘솔에서 설정을 확인해주세요.';
      } else if (errorString.contains('네트워크 연결을 확인해주세요')) {
        return '네트워크 연결을 확인해주세요. 인터넷 연결 상태를 점검해보세요.';
      } else if (errorString.contains('Firebase 내부 오류가 발생했습니다')) {
        return 'Firebase 서비스에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      } else if (errorString.contains('Firebase 할당량이 초과되었습니다')) {
        return 'Firebase 서비스 사용량이 초과되었습니다. 잠시 후 다시 시도해주세요.';
      } else if (errorString.contains('앱이 Firebase에 인증되지 않았습니다')) {
        return '앱 인증에 문제가 발생했습니다. 개발자에게 문의해주세요.';
      }
      
      // 일반적인 오류 메시지
      return '회원가입 중 오류가 발생했습니다: ${errorString.replaceAll('Exception: ', '')}';
    }
    
    // 예외가 아닌 경우
    return '회원가입 중 예상치 못한 오류가 발생했습니다. 다시 시도해주세요.';
  }

  // Google 로그인 (실제 Firebase)
  Future<void> signInWithGoogle() async {
    try {
      isSigningIn.value = true;
      // Google 로그인은 이메일을 몰라 선검사가 어려움 → 로그인 후에 즉시 차단 검사
      
      // Firebase Auth Google 로그인
      await _authService.signInWithGoogle();
      
      // 네비게이션은 Auth 상태 리스너(_onUserLogin)에서 처리
      
    } catch (e) {
      print('Google 로그인 실패: $e');
      // Google 로그인 오류에 따른 적절한 오류 메시지 표시
      String errorMessage = _getGoogleLoginErrorMessage(e);
      Get.snackbar('로그인 실패', errorMessage);
      // 로그인 실패 시에는 메인 화면으로 이동하지 않음
    } finally {
      isSigningIn.value = false;
    }
  }

  // Apple 로그인 (실제 Firebase)
  Future<void> signInWithApple() async {
    try {
      isSigningIn.value = true;
      // Apple도 로그인 후 차단 검사 수행
      
      // Firebase Auth Apple 로그인
      await _authService.signInWithApple();
      
      // 네비게이션은 Auth 상태 리스너(_onUserLogin)에서 처리
      
    } catch (e) {
      print('Apple 로그인 실패: $e');
      // Apple 로그인 오류에 따른 적절한 오류 메시지 표시
      String errorMessage = _getAppleLoginErrorMessage(e);
      Get.snackbar('로그인 실패', errorMessage);
      // 로그인 실패 시에는 메인 화면으로 이동하지 않음
    } finally {
      isSigningIn.value = false;
    }
  }

  // Google 로그인 오류 메시지 처리
  String _getGoogleLoginErrorMessage(dynamic error) {
    if (error is Exception) {
      String errorString = error.toString();
      if (errorString.contains('Google 로그인이 취소되었습니다')) {
        return 'Google 로그인이 취소되었습니다.';
      } else if (errorString.contains('네트워크 연결을 확인해주세요')) {
        return '네트워크 연결을 확인해주세요.';
      } else if (errorString.contains('Google 로그인에 실패했습니다')) {
        return 'Google 로그인에 실패했습니다. 다시 시도해주세요.';
      } else if (errorString.contains('Google Play 서비스가 필요합니다')) {
        return 'Google Play 서비스가 필요합니다.';
      } else if (errorString.contains('Google 인증 정보를 가져올 수 없습니다')) {
        return 'Google 인증 정보를 가져올 수 없습니다. 다시 시도해주세요.';
      }
    }
    return 'Google 로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
  }

  // Apple 로그인 오류 메시지 처리
  String _getAppleLoginErrorMessage(dynamic error) {
    if (error is Exception) {
      String errorString = error.toString();
      if (errorString.contains('Apple 로그인이 취소되었습니다')) {
        return 'Apple 로그인이 취소되었습니다.';
      } else if (errorString.contains('Apple 로그인을 다시 시도해주세요')) {
        return 'Apple 로그인을 다시 시도해주세요.';
      } else if (errorString.contains('Apple 로그인에 실패했습니다')) {
        return 'Apple 로그인에 실패했습니다. 다시 시도해주세요.';
      } else if (errorString.contains('Apple 로그인이 지원되지 않는 기기입니다')) {
        return 'Apple 로그인이 지원되지 않는 기기입니다.';
      } else if (errorString.contains('Apple 로그인 인증 정보를 가져올 수 없습니다')) {
        return 'Apple 로그인 인증 정보를 가져올 수 없습니다. 다시 시도해주세요.';
      }
    }
    return 'Apple 로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
  }

  // 비밀번호 재설정 이메일 전송 (실제 Firebase)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;
      
      // Firebase Auth 비밀번호 재설정 이메일 전송
      await _authService.sendPasswordResetEmail(email);
      
      print('비밀번호 재설정 이메일 전송 완료: $email');
      
    } catch (e) {
      print('비밀번호 재설정 이메일 전송 실패: $e');
      throw Exception('비밀번호 재설정 이메일 전송에 실패했습니다: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // 로그아웃 (실제 Firebase)
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      
      // Firebase Auth 로그아웃
      await _authService.signOut();
      
      _redirectToLogin();
      Get.snackbar('알림', '로그아웃 되었습니다.');
      
    } catch (e) {
      print('로그아웃 실패: $e');
      Get.snackbar('오류', '로그아웃에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 추가 메서드들 (호환성을 위해)
  Future<void> logout() async {
    await signOut();
  }

  Future<void> refreshProfile() async {
    await loadUserProfile();
  }

  void debugCheckUserData() {
    print('=== 사용자 데이터 디버그 정보 ===');
    print('사용자 ID: ${currentUserId.value}');
    print('사용자 이메일: ${currentUserEmail.value}');
    print('사용자 이름: ${currentUserName.value}');
    print('프로필 데이터: ${userProfile.value}');
    print('로그인 상태: $isLoggedIn');
    print('==============================');
  }

  bool isSessionValid() {
    // 실제 Firebase 모드에서는 항상 유효
    return isLoggedIn;
  }

  Future<void> forceLogout({String? reason}) async {
    if (reason != null) {
      Get.snackbar('알림', reason);
    }
    await signOut();
  }

  /// Firebase Auth 계정 삭제 (회원 탈퇴 시 사용)
  Future<void> deleteFirebaseAuthAccount() async {
    try {
      if (currentUserId.value.isEmpty) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // Firebase Auth에서 현재 사용자 계정 삭제
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // 이메일 차단 등록 (30일)
        final email = currentUser.email ?? '';
        if (email.isNotEmpty) {
          await _userRepository.blockEmailForDays(email, days: 30);
        }
        await currentUser.delete();
        print('Firebase Auth 계정 삭제 완료: ${currentUserId.value}');
      } else {
        throw Exception('Firebase Auth 사용자를 찾을 수 없습니다.');
      }
    } catch (e) {
      print('Firebase Auth 계정 삭제 실패: $e');
      throw Exception('Firebase Auth 계정 삭제에 실패했습니다: ${e.toString()}');
    }
  }

  /// 이메일 인증 재발송 (로그인 전)
  Future<void> resendEmailVerification(String email) async {
    try {
      await _authService.sendEmailVerificationToEmail(email);
    } catch (e) {
      print('이메일 인증 재발송 실패: $e');
      throw Exception('이메일 인증 재발송에 실패했습니다: ${e.toString()}');
    }
  }

  /// 현재 사용자의 이메일 인증 상태 확인
  bool get isEmailVerified => _authService.isEmailVerified;

  /// 현재 사용자의 이메일 인증 발송
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      print('이메일 인증 발송 실패: $e');
      throw Exception('이메일 인증 발송에 실패했습니다: ${e.toString()}');
    }
  }
}