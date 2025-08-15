import 'package:get/get.dart';
import 'package:typetalk/services/auth_service.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/services/user_repository.dart';
import 'package:typetalk/models/user_model.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();
  
  final AuthService _authService = AuthService.instance;
  final UserRepository _userRepository = UserRepository.instance;
  
  // 사용자 정보
  Rx<DemoUser?> user = Rx<DemoUser?>(null);
  RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  
  // 로딩 상태
  RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // 인증 상태 변화 감지
    user.bindStream(_authService.user.stream);
    
    // 사용자 변화 감지하여 프로필 정보 로드
    ever(user, _handleAuthChanged);
  }
  
  @override
  void onReady() {
    super.onReady();
    // 초기 인증 상태 확인
    _handleAuthChanged(user.value);
  }
  
  // 인증 상태 변화 처리
  void _handleAuthChanged(DemoUser? user) async {
    if (user == null) {
      // 로그아웃 상태
      userProfile.clear();
      _redirectToLogin();
    } else {
      // 로그인 상태 - 사용자 프로필 로드
      await _loadUserProfile();
      _redirectToMain();
    }
  }

  // 인증이 필요한 페이지 접근 가드
  bool requireAuth({String? redirectTo}) {
    if (!isLoggedIn) {
      // 로그인되지 않은 경우 로그인 페이지로 리다이렉트
      Get.snackbar('알림', '로그인이 필요한 서비스입니다.');
      Get.offAllNamed(AppRoutes.login);
      return false;
    }
    return true;
  }

  // 로그인된 사용자의 특정 화면 접근 제한
  bool requireGuest({String? redirectTo}) {
    if (isLoggedIn) {
      // 이미 로그인된 경우 메인 페이지로 리다이렉트
      Get.offAllNamed(redirectTo ?? AppRoutes.start);
      return false;
    }
    return true;
  }

  // 세션 만료 확인
  bool isSessionValid() {
    // 데모 모드에서는 항상 유효한 것으로 처리
    // 실제 앱에서는 토큰 만료 시간 등을 확인
    return isLoggedIn;
  }

  // 강제 로그아웃 (세션 만료 등)
  Future<void> forceLogout({String reason = '세션이 만료되었습니다.'}) async {
    await logout();
    Get.snackbar('알림', reason);
    Get.offAllNamed(AppRoutes.login);
  }
  
  // 사용자 프로필 정보 로드
  Future<void> _loadUserProfile() async {
    try {
      isLoading.value = true;
      
      if (user.value?.uid != null) {
        // Firestore에서 사용자 모델 로드
        final loadedUser = await _userRepository.getUser(user.value!.uid);
        if (loadedUser != null) {
          userModel.value = loadedUser;
          userProfile.assignAll(loadedUser.toMap());
        } else {
          // Firestore에 없으면 기존 방식으로 로드
          final profile = await _authService.getUserProfile();
          if (profile != null) {
            userProfile.assignAll(profile);
          }
        }
      }
    } catch (e) {
      print('프로필 로드 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // 프로필 새로고침
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }
  
  // 로그인 화면으로 리다이렉트
  void _redirectToLogin() {
    // 현재 로그인 화면이 아닌 경우에만 리다이렉트
    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
  
  // 메인 화면으로 리다이렉트
  void _redirectToMain() {
    // 현재 인증 화면인 경우에만 리다이렉트
    if (Get.currentRoute == AppRoutes.login || 
        Get.currentRoute == AppRoutes.signup) {
      Get.offAllNamed(AppRoutes.start);
    }
  }
  
  // 로그아웃
  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다.');
    }
  }
  
  // 현재 로그인 상태 확인
  bool get isLoggedIn => user.value != null;
  
  // 현재 사용자 UID
  String? get currentUserId => user.value?.uid;
  
  // 현재 사용자 이메일
  String? get currentUserEmail => user.value?.email;
  
  // 현재 사용자 이름
  String? get currentUserName => userProfile['name'] ?? user.value?.displayName;
  
  // 현재 사용자 MBTI 타입
  String? get currentUserMBTI => userProfile['mbtiType'];
  
  // MBTI 테스트 완료 횟수
  int get mbtiTestCount => userProfile['mbtiTestCount'] ?? 0;
  
  // 프로필 업데이트
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      
      if (user.value?.uid != null) {
        // Firestore에 업데이트
        if (userModel.value != null) {
          final updatedUser = userModel.value!.copyWith(
            name: data['name'],
            bio: data['bio'],
            profileImageUrl: data['profileImageUrl'],
          );
          await _userRepository.updateUser(updatedUser);
          userModel.value = updatedUser;
        } else {
          // UserRepository 메서드 사용
          await _userRepository.updateUserProfile(
            user.value!.uid,
            name: data['name'],
            bio: data['bio'],
            profileImageUrl: data['profileImageUrl'],
          );
        }
        
        // 기존 AuthService도 업데이트 (호환성)
        await _authService.updateUserProfile(data);
        
        await _loadUserProfile(); // 프로필 새로고침
        Get.snackbar('성공', '프로필이 업데이트되었습니다.');
      }
    } catch (e) {
      Get.snackbar('오류', '프로필 업데이트 중 오류가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }
  
  // MBTI 결과 저장
  Future<void> saveMBTIResult(String mbtiType) async {
    try {
      if (user.value?.uid != null) {
        // Firestore에 MBTI 업데이트
        await _userRepository.updateUserMBTI(user.value!.uid, mbtiType);
        
        // 기존 방식도 호환성을 위해 유지
        final currentCount = mbtiTestCount;
        await updateProfile({
          'mbtiType': mbtiType,
          'mbtiTestCount': currentCount + 1,
        });
      }
    } catch (e) {
      Get.snackbar('오류', 'MBTI 결과 저장 중 오류가 발생했습니다.');
    }
  }

  // Google 로그인
  Future<DemoUserCredential?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        await _loadUserProfile();
      }
      return result;
    } catch (e) {
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다.');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Apple 로그인
  Future<DemoUserCredential?> signInWithApple() async {
    try {
      isLoading.value = true;
      final result = await _authService.signInWithApple();
      if (result != null) {
        await _loadUserProfile();
      }
      return result;
    } catch (e) {
      Get.snackbar('오류', 'Apple 로그인 중 오류가 발생했습니다.');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
