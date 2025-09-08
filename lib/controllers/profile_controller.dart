import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/models/user_model.dart';

/// 사용자 프로필 관리를 위한 컨트롤러
/// 프로필 CRUD 기능을 담당합니다.
class ProfileController extends GetxController {
  static ProfileController get instance => Get.find<ProfileController>();

  final AuthController _authController = Get.find<AuthController>();
  final RealUserRepository _userRepository = Get.find<RealUserRepository>();

  // 프로필 편집 상태
  RxBool isEditing = false.obs;
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  // 프로필 편집 폼 컨트롤러
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController emailController;
  late TextEditingController ageController;

  // 현재 사용자 모델
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // 프로필 이미지 URL
  RxString profileImageUrl = ''.obs;
  
  // 나이와 성별 상태
  RxString age = ''.obs;
  RxString gender = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _loadCurrentUserProfile();
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  /// 컨트롤러 초기화
  void _initializeControllers() {
    nameController = TextEditingController();
    bioController = TextEditingController();
    emailController = TextEditingController();
    ageController = TextEditingController();
  }

  /// 컨트롤러 정리
  void _disposeControllers() {
    try {
      nameController.dispose();
      bioController.dispose();
      emailController.dispose();
      ageController.dispose();
    } catch (e) {
      print('컨트롤러 정리 오류: $e');
    }
  }

  /// 컨트롤러 안전하게 업데이트
  void _updateFormControllers(UserModel user) {
    try {
      // 컨트롤러가 초기화되어 있는지 확인
      if (nameController.text.isNotEmpty || nameController.text.isEmpty) {
        nameController.text = user.name;
      }
      if (bioController.text.isNotEmpty || bioController.text.isEmpty) {
        bioController.text = user.bio ?? '';
      }
      if (emailController.text.isNotEmpty || emailController.text.isEmpty) {
        emailController.text = user.email;
      }
      if (ageController.text.isNotEmpty || ageController.text.isEmpty) {
        ageController.text = user.age?.toString() ?? '';
      }
      profileImageUrl.value = user.profileImageUrl ?? '';
      age.value = user.age?.toString() ?? '';
      gender.value = user.gender ?? '';
    } catch (e) {
      print('컨트롤러 업데이트 오류: $e');
      // 컨트롤러가 dispose된 경우 다시 초기화
      try {
        _initializeControllers();
        nameController.text = user.name;
        bioController.text = user.bio ?? '';
        emailController.text = user.email;
        ageController.text = user.age?.toString() ?? '';
        profileImageUrl.value = user.profileImageUrl ?? '';
        age.value = user.age?.toString() ?? '';
        gender.value = user.gender ?? '';
      } catch (e2) {
        print('컨트롤러 재초기화 오류: $e2');
      }
    }
  }

  /// 현재 사용자 프로필 로드
  Future<void> _loadCurrentUserProfile() async {
    try {
      isLoading.value = true;
      
      final uid = _authController.userId;
      if (uid != null) {
        final user = await readUserProfile(uid);
        if (user != null) {
          currentUser.value = user;
          _updateFormControllers(user);
        }
      }
    } catch (e) {
      print('프로필 로드 오류: $e');
      Get.snackbar('오류', '프로필 정보를 불러오는 중 오류가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  /// 사용자 프로필 생성 (Create)
  Future<bool> createUserProfile({
    required String uid,
    required String email,
    required String name,
    String? bio,
    String? profileImageUrl,
    String? mbtiType,
    String? loginProvider,
  }) async {
    try {
      isLoading.value = true;

      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bio: bio,
        profileImageUrl: profileImageUrl,
        mbtiType: mbtiType,
        loginProvider: loginProvider,
        preferences: UserPreferences(),
        stats: UserStats(lastLoginAt: DateTime.now()),
      );

      await _userRepository.createUser(newUser);
      currentUser.value = newUser;
      _updateFormControllers(newUser);

      Get.snackbar(
        '성공',
        '프로필이 성공적으로 생성되었습니다.',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      return true;
    } catch (e) {
      print('프로필 생성 오류: $e');
      Get.snackbar(
        '오류',
        '프로필 생성 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 사용자 프로필 조회 (Read)
  Future<UserModel?> readUserProfile(String uid) async {
    try {
      isLoading.value = true;
      
      final user = await _userRepository.getUser(uid);
      if (user != null) {
        currentUser.value = user;
        return user;
      } else {
        print('사용자를 찾을 수 없습니다: $uid');
        return null;
      }
    } catch (e) {
      print('프로필 조회 오류: $e');
      Get.snackbar(
        '오류',
        '프로필 정보를 조회하는 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// 사용자 프로필 수정 (Update)
  Future<bool> updateUserProfile() async {
    try {
      isSaving.value = true;
      
      final uid = _authController.userId;
      if (uid == null) {
        Get.snackbar('오류', '사용자 정보를 찾을 수 없습니다.');
        return false;
      }

      // 서버 타임스탬프는 Firestore 서비스에서 주입되므로
      // 클라이언트에서는 DateTime 값을 보내지 않는다.
      final DateTime now = DateTime.now();
      final Map<String, dynamic> updateDataForFirestore = {
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
      };

      // 나이 처리 (입력 컨트롤러 기준으로 저장)
      final String ageText = ageController.text.trim();
      if (ageText.isNotEmpty) {
        final ageInt = int.tryParse(ageText);
        print('=== 나이 저장 디버그 ===');
        print('age.text: $ageText');
        print('ageInt: $ageInt');
        if (ageInt != null && ageInt > 0 && ageInt < 150) {
          updateDataForFirestore['age'] = ageInt;
          print('나이가 저장됩니다: $ageInt');
        } else {
          print('나이 저장 실패: 유효하지 않은 값');
          updateDataForFirestore['age'] = null;
        }
        print('====================');
      } else {
        print('나이 값이 비어있습니다');
        updateDataForFirestore['age'] = null;
      }

      // 성별 처리
      updateDataForFirestore['gender'] = (gender.value.isEmpty) ? null : gender.value;

      try {
        print('=== Firestore 저장 데이터 ===');
        print('updateDataForFirestore: $updateDataForFirestore');
        print('==========================');
        await _userRepository.updateUserFields(uid, updateDataForFirestore);
      } catch (e) {
        print('Firestore 업데이트 오류: $e');
        throw e;
      }
      
      // 로컬 사용자 모델 업데이트
      final currentUserData = currentUser.value;
      if (currentUserData != null) {
        currentUser.value = currentUserData.copyWith(
          name: updateDataForFirestore['name'] as String,
          bio: updateDataForFirestore['bio'] as String,
          age: updateDataForFirestore['age'] as int?,
          gender: updateDataForFirestore['gender'] as String?,
          updatedAt: now,
        );
      }

      // AuthController의 userModel도 직접 업데이트 (즉시 반영)
      final authUserModel = _authController.userModel.value;
      if (authUserModel != null) {
        _authController.userModel.value = authUserModel.copyWith(
          name: updateDataForFirestore['name'] as String,
          bio: updateDataForFirestore['bio'] as String,
          age: updateDataForFirestore['age'] as int?,
          gender: updateDataForFirestore['gender'] as String?,
          updatedAt: now,
        );
        print('AuthController userModel 업데이트 완료: age=${updateDataForFirestore['age']}, gender=${updateDataForFirestore['gender']}');
      }

      // AuthController의 userProfile도 즉시 업데이트
      _authController.userProfile.value = {
        'name': updateDataForFirestore['name'] as String,
        'email': authUserModel?.email ?? '',
        'mbti': authUserModel?.mbtiType ?? '',
        'bio': updateDataForFirestore['bio'] as String,
        'age': updateDataForFirestore['age'] as int?,
        'gender': updateDataForFirestore['gender'] as String?,
        'profileImageUrl': authUserModel?.profileImageUrl ?? '',
        'mbtiTestCount': authUserModel?.mbtiTestCount ?? 0,
        'createdAt': authUserModel?.createdAt ?? DateTime.now(),
        'updatedAt': now,
      };
      
      // 변경 사항을 즉시 UI에 반영하기 위해 이벤트 브로드캐스트
      try {
        // AuthController에 최신 모델이 이미 세팅되어 있으므로 별도 호출 없이도 Obx가 반응
        // 다만 일부 화면에서 캐시된 userProfile을 참조할 수 있어, 값 동기화 이벤트를 한 번 더 보냄
        _authController.userProfile.refresh();
        _authController.userModel.refresh();
      } catch (_) {}

      Get.snackbar('성공', '프로필이 업데이트되었습니다.');
      return true;
      
    } catch (e) {
      print('프로필 업데이트 오류: $e');
      Get.snackbar('오류', '프로필 업데이트에 실패했습니다: ${e.toString()}');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// 사용자 프로필 삭제 (Delete)
  Future<bool> deleteUserProfile({bool confirmDelete = false}) async {
    try {
      if (!confirmDelete) {
        // 삭제 확인 다이얼로그 표시
        final shouldDelete = await _showDeleteConfirmDialog();
        if (!shouldDelete) return false;
      }

      isLoading.value = true;

      final uid = _authController.userId;
      if (uid == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // Firestore에서 사용자 삭제
      await _userRepository.deleteUser(uid);

      // Firebase Auth 계정도 함께 삭제 (재가입 시 회원가입 절차 진행을 위해)
      try {
        await _authController.deleteFirebaseAuthAccount();
        print('Firebase Auth 계정 삭제 완료: $uid');
      } catch (e) {
        print('Firebase Auth 계정 삭제 실패: $e');
        // Auth 계정 삭제 실패 시에도 Firestore 데이터는 삭제되었으므로 계속 진행
      }

      // 로그아웃 처리 (Auth 계정 삭제 후)
      await _authController.logout();

      // 로컬 상태 초기화
      currentUser.value = null;
      nameController.clear();
      bioController.clear();
      emailController.clear();
      profileImageUrl.value = '';

      // 로그아웃은 이미 위에서 처리됨

      Get.snackbar(
        '완료',
        '사용자 프로필이 삭제되었습니다.',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
      );

      return true;
    } catch (e) {
      print('프로필 삭제 오류: $e');
      Get.snackbar(
        '오류',
        '프로필 삭제 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 삭제 확인 다이얼로그
  Future<bool> _showDeleteConfirmDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('프로필 삭제'),
        content: const Text(
          '정말로 프로필을 삭제하시겠습니까?\n\n'
          '이 작업은 되돌릴 수 없으며, 모든 프로필 정보가 영구적으로 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// MBTI 테스트 결과 업데이트
  Future<bool> updateMBTIResult(String mbtiType) async {
    try {
      isSaving.value = true;

      final uid = _authController.userId;
      if (uid == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      await _userRepository.updateUserMBTI(uid, mbtiType);

      // 프로필 새로고침
      await _loadCurrentUserProfile();
      await _authController.refreshProfile();

      Get.snackbar(
        '성공',
        'MBTI 결과가 업데이트되었습니다: $mbtiType',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      return true;
    } catch (e) {
      print('MBTI 업데이트 오류: $e');
      Get.snackbar(
        '오류',
        'MBTI 결과 업데이트 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// 사용자 설정 업데이트
  Future<bool> updateUserPreferences(UserPreferences preferences) async {
    try {
      isSaving.value = true;

      final uid = _authController.userId;
      if (uid == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      await _userRepository.updateUserPreferences(uid, preferences);

      // 프로필 새로고침
      await _loadCurrentUserProfile();

      Get.snackbar(
        '성공',
        '설정이 업데이트되었습니다.',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      return true;
    } catch (e) {
      print('설정 업데이트 오류: $e');
      Get.snackbar(
        '오류',
        '설정 업데이트 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// 프로필 편집 모드 토글
  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    
    if (!isEditing.value) {
      // 편집 취소 시 원래 값으로 복원
      final user = currentUser.value;
      if (user != null) {
        _updateFormControllers(user);
      }
    }
  }

  /// 프로필 편집 저장
  Future<void> saveProfileEdit() async {
    final success = await updateUserProfile();
    if (success) {
      isEditing.value = false;
    }
  }

  /// 프로필 정보 유효성 검증
  bool validateProfileData() {
    try {
      if (nameController.text.trim().isEmpty) {
        Get.snackbar('오류', '이름을 입력해주세요.');
        return false;
      }

      if (nameController.text.trim().length < 2) {
        Get.snackbar('오류', '이름은 2자 이상 입력해주세요.');
        return false;
      }

      if (bioController.text.length > 200) {
        Get.snackbar('오류', '소개는 200자 이내로 입력해주세요.');
        return false;
      }

      return true;
    } catch (e) {
      print('프로필 데이터 검증 오류: $e');
      Get.snackbar('오류', '프로필 데이터 검증 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 프로필 새로고침
  Future<void> refreshProfile() async {
    await _loadCurrentUserProfile();
  }

  /// 다른 사용자 프로필 조회 (공개 정보만)
  Future<UserModel?> getPublicUserProfile(String uid) async {
    try {
      final user = await _userRepository.getUser(uid);
      return user;
    } catch (e) {
      print('공개 프로필 조회 오류: $e');
      return null;
    }
  }

  /// 사용자 검색
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final users = await _userRepository.searchUsers(query);
      return users;
    } catch (e) {
      print('사용자 검색 오류: $e');
      return [];
    }
  }

  /// MBTI별 사용자 조회
  Future<List<UserModel>> getUsersByMBTI(String mbtiType) async {
    try {
      final users = await _userRepository.getUsersByMBTI(mbtiType);
      return users;
    } catch (e) {
      print('MBTI별 사용자 조회 오류: $e');
      return [];
    }
  }

  /// 프로필 통계 정보
  Map<String, dynamic> get profileStats {
    final user = currentUser.value;
    if (user == null) return {};

    return {
      'chatCount': user.stats.chatCount,
      'friendCount': user.stats.friendCount,
      'mbtiTestCount': user.mbtiTestCount,
      'joinDate': user.createdAt,
      'lastLogin': user.stats.lastLoginAt,
    };
  }

  /// 프로필 완성도 계산
  double get profileCompleteness {
    final user = currentUser.value;
    if (user == null) return 0.0;

    double score = 0.0;
    
    // 기본 정보 (50%)
    if (user.name.isNotEmpty) score += 20.0;
    if (user.email.isNotEmpty) score += 20.0;
    if (user.bio?.isNotEmpty == true) score += 10.0;
    
    // 추가 정보 (50%)
    if (user.profileImageUrl?.isNotEmpty == true) score += 20.0;
    if (user.mbtiType?.isNotEmpty == true) score += 30.0;

    return score / 100.0;
  }

  /// 프로필 완성 상태 메시지
  String get profileCompletenessMessage {
    final completeness = profileCompleteness;
    
    if (completeness >= 1.0) {
      return '프로필이 완성되었습니다! 🎉';
    } else if (completeness >= 0.8) {
      return '프로필이 거의 완성되었어요! 👍';
    } else if (completeness >= 0.5) {
      return '프로필을 더 완성해보세요! 📝';
    } else {
      return '프로필 정보를 입력해주세요! ✏️';
    }
  }

  /// 프로필 이미지 업데이트
  Future<bool> updateProfileImage(String imagePath) async {
    try {
      print('프로필 이미지 업데이트 시작: $imagePath');
      
      // 현재 사용자 정보 가져오기
      final user = currentUser.value;
      if (user == null) {
        print('사용자 정보를 찾을 수 없음 - 프로필 새로고침 시도');
        
        // 프로필 새로고침 시도
        try {
          final uid = _authController.userId;
          if (uid != null) {
            await _loadCurrentUserProfile();
            final refreshedUser = currentUser.value;
            if (refreshedUser != null) {
              print('프로필 새로고침 성공');
              return await updateProfileImage(imagePath); // 재귀 호출
            }
          }
        } catch (refreshError) {
          print('프로필 새로고침 실패: $refreshError');
        }
        
        Get.snackbar('오류', '사용자 정보를 찾을 수 없습니다. 다시 시도해주세요.');
        return false;
      }

      print('사용자 UID: ${user.uid}');
      print('현재 프로필 이미지: ${user.profileImageUrl}');

      // 프로필 이미지 URL 업데이트
      profileImageUrl.value = imagePath;
      print('로컬 상태 업데이트 완료');
      
      // Firestore에 업데이트
      try {
        await _userRepository.updateUserFields(
          user.uid,
          {'profileImageUrl': imagePath},
        );
        print('Firestore 업데이트 완료');
      } catch (firestoreError) {
        print('Firestore 업데이트 실패: $firestoreError');
        // Firestore 실패 시 로컬 상태 복원
        profileImageUrl.value = user.profileImageUrl ?? '';
        throw firestoreError;
      }

      // 현재 사용자 모델 업데이트
      currentUser.value = user.copyWith(profileImageUrl: imagePath);
      print('사용자 모델 업데이트 완료');
      // 상위 인증 컨트롤러 상태도 갱신하여 다른 화면에 즉시 반영
      try {
        await _authController.refreshProfile();
      } catch (_) {}
      
      Get.snackbar('성공', '프로필 이미지가 업데이트되었습니다.');
      return true;
    } catch (e) {
      print('프로필 이미지 업데이트 오류: $e');
      print('오류 타입: ${e.runtimeType}');
      print('오류 스택: ${StackTrace.current}');
      
      // 오류 발생 시 로컬 상태 복원
      try {
        final user = currentUser.value;
        if (user != null) {
          profileImageUrl.value = user.profileImageUrl ?? '';
        }
      } catch (restoreError) {
        print('상태 복원 실패: $restoreError');
      }
      
      Get.snackbar('오류', '프로필 이미지 업데이트 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    }
  }

  /// 프로필 이미지 삭제
  Future<bool> deleteProfileImage() async {
    try {
      // 현재 사용자 정보 가져오기
      final user = currentUser.value;
      if (user == null) {
        Get.snackbar('오류', '사용자 정보를 찾을 수 없습니다.');
        return false;
      }

      // 프로필 이미지 URL 초기화 (로컬 상태)
      profileImageUrl.value = '';
      
      // Firestore에 업데이트
      await _userRepository.updateUserFields(
        user.uid,
        {'profileImageUrl': ''},
      );

      // 현재 사용자 모델 업데이트
      currentUser.value = user.copyWith(profileImageUrl: '');
      // AuthController 캐시도 비워서 다른 화면에 즉시 반영
      try {
        _authController.userProfile['profileImageUrl'] = '';
        _authController.userProfile.refresh();
        await _authController.refreshProfile();
      } catch (_) {}
      Get.snackbar('성공', '프로필 이미지가 삭제되었습니다.');
      try {
        await _authController.refreshProfile();
      } catch (_) {}
      return true;
    } catch (e) {
      print('프로필 이미지 삭제 오류: $e');
      Get.snackbar('오류', '프로필 이미지 삭제 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 나이 업데이트
  void updateAge(String ageValue) {
    age.value = ageValue;
  }

  /// 성별 업데이트
  void updateGender(String? genderValue) {
    gender.value = genderValue ?? '';
  }

  /// 나이와 성별을 Firestore에 저장
  Future<void> _saveAgeAndGender() async {
    try {
      final user = currentUser.value;
      if (user == null) return;

      final updateData = <String, dynamic>{};
      
      // 나이 처리
      if (age.value.isNotEmpty) {
        final ageInt = int.tryParse(age.value);
        if (ageInt != null && ageInt > 0 && ageInt < 150) {
          updateData['age'] = ageInt;
        }
      } else {
        updateData['age'] = null;
      }

      // 성별 처리
      updateData['gender'] = (gender.value.isEmpty) ? null : gender.value;

      if (updateData.isNotEmpty) {
        await _userRepository.updateUserFields(user.uid, updateData);
        
        // 현재 사용자 모델 업데이트
        currentUser.value = user.copyWith(
          age: updateData['age'] as int?,
          gender: updateData['gender'] as String?,
        );
        
        // AuthController의 userModel도 직접 업데이트 (즉시 반영)
        final authUserModel = _authController.userModel.value;
        if (authUserModel != null) {
          _authController.userModel.value = authUserModel.copyWith(
            age: updateData['age'] as int?,
            gender: updateData['gender'] as String?,
          );
          print('AuthController userModel 업데이트 완료 (나이/성별): age=${updateData['age']}, gender=${updateData['gender']}');
        }
        
        // AuthController의 userProfile도 즉시 업데이트
        _authController.userProfile.value = {
          'name': authUserModel?.name ?? '',
          'email': authUserModel?.email ?? '',
          'mbti': authUserModel?.mbtiType ?? '',
          'bio': authUserModel?.bio ?? '',
          'age': updateData['age'] as int?,
          'gender': updateData['gender'] as String?,
          'profileImageUrl': authUserModel?.profileImageUrl ?? '',
          'mbtiTestCount': authUserModel?.mbtiTestCount ?? 0,
          'createdAt': authUserModel?.createdAt ?? DateTime.now(),
          'updatedAt': DateTime.now(),
        };
        
        // 변경 사항을 즉시 UI에 반영
        try {
          _authController.userProfile.refresh();
          _authController.userModel.refresh();
        } catch (_) {}

        print('나이와 성별이 저장되었습니다: age=${updateData['age']}, gender=${updateData['gender']}');
      }
    } catch (e) {
      print('나이와 성별 저장 오류: $e');
    }
  }
}
