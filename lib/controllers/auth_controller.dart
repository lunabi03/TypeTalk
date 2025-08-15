import 'package:get/get.dart';
import 'package:typetalk/services/auth_service.dart';
import 'package:typetalk/routes/app_routes.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();
  
  final AuthService _authService = AuthService.instance;
  
  // 사용자 정보
  Rx<DemoUser?> user = Rx<DemoUser?>(null);
  RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;
  
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
  
  // 사용자 프로필 정보 로드
  Future<void> _loadUserProfile() async {
    try {
      isLoading.value = true;
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        userProfile.value = profile;
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
      await _authService.updateUserProfile(data);
      await _loadUserProfile(); // 프로필 새로고침
      Get.snackbar('성공', '프로필이 업데이트되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '프로필 업데이트 중 오류가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }
  
  // MBTI 결과 저장
  Future<void> saveMBTIResult(String mbtiType) async {
    try {
      final currentCount = mbtiTestCount;
      await updateProfile({
        'mbtiType': mbtiType,
        'mbtiTestCount': currentCount + 1,
      });
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
