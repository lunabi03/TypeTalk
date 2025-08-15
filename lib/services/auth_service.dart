import 'package:get/get.dart';
import 'package:typetalk/services/user_repository.dart';
import 'package:typetalk/models/user_model.dart';

// 데모용 사용자 클래스
class DemoUser {
  final String uid;
  final String? email;
  final String? displayName;
  
  DemoUser({required this.uid, this.email, this.displayName});
}

// 데모용 사용자 인증 정보 클래스
class DemoUserCredential {
  final DemoUser? user;
  
  DemoUserCredential({this.user});
}

class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();
  
  // 데모용 사용자 정보
  Rx<DemoUser?> user = Rx<DemoUser?>(null);
  
  // 데모용 사용자 데이터베이스
  final Map<String, Map<String, dynamic>> _demoDatabase = {};
  
  // 세션 저장소 (실제 앱에서는 SharedPreferences 등을 사용)
  final Map<String, dynamic> _sessionStorage = {};
  
  // 사용자 데이터 저장소
  final UserRepository _userRepository = UserRepository.instance;
  
  @override
  void onInit() {
    super.onInit();
    // 세션 복원 시도
    _restoreSession();
  }
  
  // 세션 복원
  Future<void> _restoreSession() async {
    try {
      // 저장된 세션 확인
      final savedUser = _sessionStorage['currentUser'];
      if (savedUser != null) {
        // 저장된 사용자 정보로 복원
        final restoredUser = DemoUser(
          uid: savedUser['uid'],
          email: savedUser['email'],
          displayName: savedUser['displayName'],
        );
        
        // 사용자 상태 복원
        user.value = restoredUser;
        print('세션 복원 완료: ${restoredUser.email}');
      } else {
        // 저장된 세션이 없으면 기본 데모 사용자로 초기화
        _initializeDemoUser();
      }
    } catch (e) {
      print('세션 복원 실패: $e');
      // 오류 발생 시 기본 데모 사용자로 초기화
      _initializeDemoUser();
    }
  }

  // 세션 저장
  Future<void> _saveSession(DemoUser user) async {
    try {
      _sessionStorage['currentUser'] = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
      };
      _sessionStorage['lastLoginTime'] = DateTime.now().toIso8601String();
      print('세션 저장 완료: ${user.email}');
    } catch (e) {
      print('세션 저장 실패: $e');
    }
  }

  // 세션 삭제
  Future<void> _clearSession() async {
    try {
      _sessionStorage.clear();
      print('세션 삭제 완료');
    } catch (e) {
      print('세션 삭제 실패: $e');
    }
  }

  void _initializeDemoUser() {
    // 데모용 사용자 생성
    final demoUser = DemoUser(
      uid: 'demo-user-001',
      email: 'demo@typetalk.com',
      displayName: '데모 사용자',
    );
    
    // 데모 사용자 프로필 생성
    _demoDatabase[demoUser.uid] = {
      'uid': demoUser.uid,
      'email': demoUser.email,
      'name': demoUser.displayName,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'mbtiType': 'ENFP',
      'mbtiTestCount': 3,
    };
    
    // 자동 로그인 및 세션 저장
    user.value = demoUser;
    _saveSession(demoUser);
  }
  
  // 현재 사용자가 로그인 상태인지 확인
  bool get isLoggedIn => user.value != null;
  
  // 현재 사용자 UID
  String? get currentUserId => user.value?.uid;
  
  // 이메일/비밀번호로 회원가입 (데모 모드)
  Future<DemoUserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 데모 모드: 시뮬레이션 지연
      await Future.delayed(const Duration(seconds: 1));
      
      // 새 사용자 생성
      final uid = 'user-${DateTime.now().millisecondsSinceEpoch}';
      final newUser = DemoUser(
        uid: uid,
        email: email,
        displayName: name,
      );
      
      // Firestore에 사용자 정보 저장
      final userModel = UserModel(
        uid: uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mbtiType: null,
        mbtiTestCount: 0,
        loginProvider: 'email',
      );
      
      await _userRepository.createUser(userModel);
      
      // 데모 데이터베이스에도 저장 (호환성 유지)
      _demoDatabase[uid] = userModel.toMap();
      
      // 로그인 상태로 설정 및 세션 저장
      user.value = newUser;
      await _saveSession(newUser);
      
      Get.snackbar('성공', '회원가입이 완료되었습니다!');
      return DemoUserCredential(user: newUser);
    } catch (e) {
      Get.snackbar('오류', '회원가입 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }
  
  // 이메일/비밀번호로 로그인 (데모 모드)
  Future<DemoUserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 데모 모드: 시뮬레이션 지연
      await Future.delayed(const Duration(seconds: 1));
      
      // 데모 계정으로 로그인
      final demoUser = DemoUser(
        uid: 'demo-user-001',
        email: email,
        displayName: '데모 사용자',
      );
      
      user.value = demoUser;
      await _saveSession(demoUser);
      Get.snackbar('성공', '로그인되었습니다!');
      return DemoUserCredential(user: demoUser);
    } catch (e) {
      Get.snackbar('오류', '로그인 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }
  
  // 로그아웃 (데모 모드)
  Future<void> signOut() async {
    try {
      user.value = null;
      await _clearSession();
      Get.snackbar('알림', '로그아웃되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다: ${e.toString()}');
    }
  }
  
  // 비밀번호 재설정 이메일 전송 (데모 모드)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // 데모 모드: 시뮬레이션 지연
      await Future.delayed(const Duration(seconds: 1));
      Get.snackbar('알림', '비밀번호 재설정 이메일이 전송되었습니다. (데모 모드)');
    } catch (e) {
      Get.snackbar('오류', '이메일 전송 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  // Google 로그인 (데모 모드)
  Future<DemoUserCredential?> signInWithGoogle() async {
    try {
      // 데모 모드: 시뮬레이션 지연
      await Future.delayed(const Duration(seconds: 2));
      
      // Google 계정으로 로그인된 데모 사용자 생성
      final googleUser = DemoUser(
        uid: 'google-${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo.google@gmail.com',
        displayName: 'Google 사용자',
      );
      
      // Firestore에 사용자 정보 저장 (기존 사용자가 아닌 경우)
      final existingUser = await _userRepository.getUser(googleUser.uid);
      if (existingUser == null) {
        final userModel = UserModel(
          uid: googleUser.uid,
          email: googleUser.email!,
          name: googleUser.displayName!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          mbtiType: null,
          mbtiTestCount: 0,
          loginProvider: 'google',
        );
        
        await _userRepository.createUser(userModel);
        _demoDatabase[googleUser.uid] = userModel.toMap();
      } else {
        // 기존 사용자의 마지막 로그인 시간 업데이트
        await _userRepository.updateLastLogin(googleUser.uid);
        _demoDatabase[googleUser.uid] = existingUser.updateLastLogin().toMap();
      }
      
      // 로그인 상태로 설정 및 세션 저장
      user.value = googleUser;
      await _saveSession(googleUser);
      
      Get.snackbar('성공', 'Google 계정으로 로그인되었습니다!');
      return DemoUserCredential(user: googleUser);
    } catch (e) {
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }

  // Apple 로그인 (데모 모드)
  Future<DemoUserCredential?> signInWithApple() async {
    try {
      // 데모 모드: 시뮬레이션 지연
      await Future.delayed(const Duration(seconds: 2));
      
      // Apple 계정으로 로그인된 데모 사용자 생성
      final appleUser = DemoUser(
        uid: 'apple-${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo.apple@icloud.com',
        displayName: 'Apple 사용자',
      );
      
      // Firestore에 사용자 정보 저장 (기존 사용자가 아닌 경우)
      final existingUser = await _userRepository.getUser(appleUser.uid);
      if (existingUser == null) {
        final userModel = UserModel(
          uid: appleUser.uid,
          email: appleUser.email!,
          name: appleUser.displayName!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          mbtiType: null,
          mbtiTestCount: 0,
          loginProvider: 'apple',
        );
        
        await _userRepository.createUser(userModel);
        _demoDatabase[appleUser.uid] = userModel.toMap();
      } else {
        // 기존 사용자의 마지막 로그인 시간 업데이트
        await _userRepository.updateLastLogin(appleUser.uid);
        _demoDatabase[appleUser.uid] = existingUser.updateLastLogin().toMap();
      }
      
      // 로그인 상태로 설정 및 세션 저장
      user.value = appleUser;
      await _saveSession(appleUser);
      
      Get.snackbar('성공', 'Apple 계정으로 로그인되었습니다!');
      return DemoUserCredential(user: appleUser);
    } catch (e) {
      Get.snackbar('오류', 'Apple 로그인 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }
  
  // 사용자 프로필 생성 (데모 모드)
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      _demoDatabase[uid] = {
        'uid': uid,
        'email': email,
        'name': name,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'mbtiType': null,
        'mbtiTestCount': 0,
      };
    } catch (e) {
      print('사용자 프로필 생성 오류: $e');
    }
  }
  
  // 사용자 프로필 정보 가져오기 (데모 모드)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;
      return _demoDatabase[currentUserId];
    } catch (e) {
      print('사용자 프로필 조회 오류: $e');
      return null;
    }
  }
  
  // 사용자 프로필 업데이트 (데모 모드)
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (currentUserId == null) return;
      
      data['updatedAt'] = DateTime.now();
      _demoDatabase[currentUserId!]!.addAll(data);
    } catch (e) {
      print('사용자 프로필 업데이트 오류: $e');
      Get.snackbar('오류', '프로필 업데이트 중 오류가 발생했습니다.');
    }
  }
}
