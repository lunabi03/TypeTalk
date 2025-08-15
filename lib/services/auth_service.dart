import 'package:get/get.dart';

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
  
  @override
  void onInit() {
    super.onInit();
    // 데모 모드: 초기화 시 자동 로그인된 상태로 설정
    _initializeDemoUser();
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
    
    // 자동 로그인
    user.value = demoUser;
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
      
      // 데모 데이터베이스에 사용자 정보 저장
      _demoDatabase[uid] = {
        'uid': uid,
        'email': email,
        'name': name,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'mbtiType': null,
        'mbtiTestCount': 0,
      };
      
      // 로그인 상태로 설정
      user.value = newUser;
      
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
      
      // 데모 데이터베이스에 사용자 정보 저장
      _demoDatabase[googleUser.uid] = {
        'uid': googleUser.uid,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'mbtiType': null,
        'mbtiTestCount': 0,
        'loginProvider': 'google',
      };
      
      // 로그인 상태로 설정
      user.value = googleUser;
      
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
      
      // 데모 데이터베이스에 사용자 정보 저장
      _demoDatabase[appleUser.uid] = {
        'uid': appleUser.uid,
        'email': appleUser.email,
        'name': appleUser.displayName,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'mbtiType': null,
        'mbtiTestCount': 0,
        'loginProvider': 'apple',
      };
      
      // 로그인 상태로 설정
      user.value = appleUser;
      
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
