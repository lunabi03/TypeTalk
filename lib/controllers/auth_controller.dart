import 'package:get/get.dart';
import 'package:typetalk/routes/app_routes.dart';

// 데모 서비스들 (활성화)
import 'package:typetalk/services/auth_service.dart';
import 'package:typetalk/services/user_repository.dart';

import 'package:typetalk/models/user_model.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();
  
  AuthService get _authService => Get.find<AuthService>();
  UserRepository get _userRepository => Get.find<UserRepository>();
  
  // 사용자 정보 (데모 모드)
  RxString currentUserId = ''.obs;
  RxString currentUserEmail = ''.obs;
  RxString currentUserName = ''.obs;
  RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  
  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isSigningIn = false.obs;
  RxBool isSigningUp = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 데모 모드 - 자동 로그인
    _initDemoUser();
  }
  
  @override
  void onReady() {
    super.onReady();
    // 데모 모드 - 초기화 완료
    print('AuthController 초기화 완료 (데모 모드)');
  }
  
  // 데모 사용자 초기화
  void _initDemoUser() {
    currentUserId.value = 'demo_user_001';
    currentUserEmail.value = 'demo@typetalk.com';
    currentUserName.value = '데모 사용자';
    
    // 데모 프로필 설정
    userProfile.value = {
      'name': '데모 사용자',
      'email': 'demo@typetalk.com',
      'mbti': 'ENFP',
      'bio': '안녕하세요! TypeTalk 데모 사용자입니다.',
      'age': 25,
      'profileImageUrl': null,
    };
    
    print('데모 사용자 로그인 완료');
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

  // 사용자 프로필 로드 (데모 모드에서는 이미 설정됨)
  Future<void> loadUserProfile() async {
    if (currentUserId.value.isEmpty) {
      print('로그인된 사용자가 없습니다.');
      return;
    }

    try {
      isLoading.value = true;
      
      // 데모 모드에서는 이미 설정된 프로필 사용
      print('현재 로그인 사용자 UID: ${currentUserId.value}');
      print('프로필 정보: ${userProfile.value}');
      
    } catch (e) {
      print('프로필 로드 실패: $e');
      Get.snackbar('오류', '프로필 로드에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 사용자 프로필 업데이트 (데모 모드)
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUserId.value.isEmpty) {
      Get.snackbar('오류', '로그인이 필요합니다.');
      return;
    }

    try {
      isLoading.value = true;
      
      // 데모 모드에서는 로컬 저장만
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

  // 사용자 MBTI 업데이트 (데모 모드)
  Future<void> updateUserMBTI(String mbtiType) async {
    if (currentUserId.value.isEmpty) {
      Get.snackbar('오류', '로그인이 필요합니다.');
      return;
    }

    try {
      isLoading.value = true;
      
      // 데모 모드에서는 로컬 업데이트만
      userProfile['mbti'] = mbtiType;
      userProfile.refresh();
      
      print('MBTI 업데이트 완료: $mbtiType');
      Get.snackbar('성공', 'MBTI가 업데이트되었습니다.');
      
    } catch (e) {
      print('MBTI 업데이트 실패: $e');
      Get.snackbar('오류', 'MBTI 업데이트에 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 이메일 로그인 (데모 모드)
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isSigningIn.value = true;
      
      // 데모 모드 - 항상 성공
      await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션
      
      _initDemoUser();
      _redirectToMain();
      
      Get.snackbar('성공', '로그인 되었습니다.');
      
    } catch (e) {
      print('로그인 실패: $e');
      Get.snackbar('오류', '로그인에 실패했습니다.');
    } finally {
      isSigningIn.value = false;
    }
  }

  // 회원가입 (데모 모드)
  Future<void> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      isSigningUp.value = true;
      
      // 데모 모드 - 항상 성공
      await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션
      
      currentUserId.value = 'demo_user_001';
      currentUserEmail.value = email;
      currentUserName.value = name;
      
      userProfile.value = {
        'name': name,
        'email': email,
        'mbti': null,
        'bio': '',
        'age': null,
        'profileImageUrl': null,
      };
      
      _redirectToMain();
      Get.snackbar('성공', '회원가입이 완료되었습니다.');
      
    } catch (e) {
      print('회원가입 실패: $e');
      Get.snackbar('오류', '회원가입에 실패했습니다.');
    } finally {
      isSigningUp.value = false;
    }
  }

  // Google 로그인 (데모 모드)
  Future<void> signInWithGoogle() async {
    try {
      isSigningIn.value = true;
      
      // 데모 모드 - 항상 성공
      await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션
      
      _initDemoUser();
      _redirectToMain();
      
      Get.snackbar('성공', 'Google 로그인이 완료되었습니다.');
      
    } catch (e) {
      print('Google 로그인 실패: $e');
      Get.snackbar('오류', 'Google 로그인에 실패했습니다.');
    } finally {
      isSigningIn.value = false;
    }
  }

  // Apple 로그인 (데모 모드)
  Future<void> signInWithApple() async {
    try {
      isSigningIn.value = true;
      
      // 데모 모드 - 항상 성공
      await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션
      
      _initDemoUser();
      _redirectToMain();
      
      Get.snackbar('성공', 'Apple 로그인이 완료되었습니다.');
      
    } catch (e) {
      print('Apple 로그인 실패: $e');
      Get.snackbar('오류', 'Apple 로그인에 실패했습니다.');
    } finally {
      isSigningIn.value = false;
    }
  }

  // 로그아웃 (데모 모드)
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      
      // 데모 모드 - 상태 초기화
      currentUserId.value = '';
      currentUserEmail.value = '';
      currentUserName.value = '';
      userProfile.clear();
      userModel.value = null;
      
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
    // 데모 모드에서는 항상 유효
    return isLoggedIn;
  }

  Future<void> forceLogout({String? reason}) async {
    if (reason != null) {
      Get.snackbar('알림', reason);
    }
    await signOut();
  }
}