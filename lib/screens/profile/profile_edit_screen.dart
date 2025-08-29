import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File; // Guarded usage with kIsWeb checks
import 'package:typetalk/controllers/profile_controller.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/app_button.dart';
import 'package:typetalk/core/widgets/app_text_field.dart';

/// 프로필 편집 화면
/// 사용자가 자신의 프로필 정보를 수정할 수 있는 화면입니다.
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20.sp,
          ),
        ),
        title: Text(
          '프로필 편집',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() => TextButton(
            onPressed: profileController.isSaving.value
                ? null
                : () => _saveProfile(profileController),
            child: Text(
              '저장',
              style: AppTextStyles.bodyMedium.copyWith(
                color: profileController.isSaving.value
                    ? AppColors.textSecondary
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (profileController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지 섹션
              _buildProfileImageSection(profileController),
              
              SizedBox(height: 32.h),

              // 기본 정보 섹션
              _buildBasicInfoSection(profileController),

              SizedBox(height: 32.h),

              // 추가 정보 섹션
              _buildAdditionalInfoSection(profileController),

              SizedBox(height: 32.h),

              // 프로필 완성도
              _buildProfileCompletenessSection(profileController),

              SizedBox(height: 32.h),

              // 삭제 버튼
              _buildDeleteSection(profileController),

              SizedBox(height: 40.h),
            ],
          ),
        );
      }),
    );
  }

  /// 프로필 이미지 섹션
  Widget _buildProfileImageSection(ProfileController controller) {
    return Center(
      child: Column(
        children: [
          // 프로필 이미지
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Obx(() {
              final imageUrl = controller.profileImageUrl.value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: imageUrl.isNotEmpty
                    ? _buildProfileImage(imageUrl)
                    : _defaultProfileIcon(),
              );
            }),
          ),

          SizedBox(height: 16.h),

          // 이미지 변경 버튼
          AppButton(
            text: '프로필 사진 변경',
            onPressed: () => _showImagePicker(controller),
            backgroundColor: AppColors.surface,
            textColor: Colors.black, // 글씨 색상을 검은색으로 변경
          ),
        ],
      ),
    );
  }

  /// 프로필 이미지 표시
  Widget _buildProfileImage(String imagePath) {
    // 웹에서는 dart:io File을 사용할 수 없으므로 네트워크/데이터 URL로만 처리
    final isNetworkLike = imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('blob:') ||
        imagePath.startsWith('data:');

    if (isNetworkLike || kIsWeb) {
      return Image.network(
        imagePath,
        width: 120.w,
        height: 120.w,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _defaultProfileIcon();
        },
      );
    }

    // 모바일/데스크톱(native)에서만 파일 경로 처리
    try {
      return Image.file(
        File(imagePath),
        width: 120.w,
        height: 120.w,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _defaultProfileIcon();
        },
      );
    } catch (e) {
      return _defaultProfileIcon();
    }
  }

  /// 기본 프로필 아이콘
  Widget _defaultProfileIcon() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Image.asset(
        'assets/images/_icon_profile.png',
        width: 80.w,
        height: 80.w,
        fit: BoxFit.contain,
      ),
    );
  }

  /// 기본 정보 섹션
  Widget _buildBasicInfoSection(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기본 정보',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        // 이름
        AppTextField(
          label: '이름',
          controller: controller.nameController,
          hint: '이름을 입력해주세요',
        ),

        SizedBox(height: 16.h),

        // 이메일 (읽기 전용)
        AppTextField(
          label: '이메일',
          controller: controller.emailController,
          hint: '이메일',
          enabled: false, // 읽기 전용
        ),

        SizedBox(height: 16.h),

        // 소개
        AppTextField(
          label: '소개',
          controller: controller.bioController,
          hint: '자신을 소개해주세요',
          maxLines: 3,
        ),
      ],
    );
  }

  /// 추가 정보 섹션
  Widget _buildAdditionalInfoSection(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추가 정보',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        // MBTI 정보 표시
        Obx(() {
          final user = controller.currentUser.value;
          final mbtiType = user?.mbtiType;
          
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MBTI 유형',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed('/question'),
                      child: Text(
                        '테스트하기',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  mbtiType ?? '아직 테스트를 완료하지 않았습니다',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: mbtiType != null ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (user?.mbtiTestCount != null && user!.mbtiTestCount > 0) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '테스트 완료 횟수: ${user.mbtiTestCount}회',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        SizedBox(height: 16.h),

        // 가입일 정보
        Obx(() {
          final user = controller.currentUser.value;
          if (user == null) return const SizedBox.shrink();

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '가입 정보',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '가입일: ${_formatDate(user.createdAt)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '최근 로그인: ${_formatDate(user.stats.lastLoginAt)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 프로필 완성도 섹션
  Widget _buildProfileCompletenessSection(ProfileController controller) {
    return Obx(() {
      final completeness = controller.profileCompleteness;
      final message = controller.profileCompletenessMessage;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '프로필 완성도',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${(completeness * 100).toInt()}%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            LinearProgressIndicator(
              value: completeness,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 삭제 섹션
  Widget _buildDeleteSection(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '위험 영역',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        SizedBox(height: 16.h),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '프로필 삭제',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '프로필을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 12.h),
              AppButton(
                text: '프로필 삭제',
                onPressed: () => _confirmDelete(controller),
                backgroundColor: Colors.red,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 프로필 저장
  Future<void> _saveProfile(ProfileController controller) async {
    if (!controller.validateProfileData()) {
      return;
    }

    final success = await controller.updateUserProfile();
    if (success == true) {
      Get.back();
    }
  }

  /// 이미지 선택기 표시
  void _showImagePicker(ProfileController controller) {
    // 사용자 정보 확인
    if (controller.currentUser.value == null) {
      Get.snackbar(
        '오류',
        '사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '프로필 사진 선택',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('카메라로 촬영'),
              onTap: () {
                Get.back();
                _pickImageFromCamera(controller);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('갤러리에서 선택'),
              onTap: () {
                Get.back();
                _pickImageFromGallery(controller);
              },
            ),
            
            if (controller.profileImageUrl.value.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('사진 삭제'),
                onTap: () async {
                  Get.back();
                  await controller.deleteProfileImage();
                },
              ),
            
            SizedBox(height: 20.h),
            
            AppButton(
              text: '취소',
              onPressed: () => Get.back(),
              backgroundColor: AppColors.surface,
              textColor: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 카메라에서 이미지 선택
  Future<void> _pickImageFromCamera(ProfileController controller) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _processSelectedImage(controller, image);
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '카메라에서 이미지를 선택하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImageFromGallery(ProfileController controller) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _processSelectedImage(controller, image);
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '갤러리에서 이미지를 선택하는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 선택된 이미지 처리
  Future<void> _processSelectedImage(ProfileController controller, XFile image) async {
    try {
      print('이미지 처리 시작: ${image.path}');
      // 파일 크기 확인 (플랫폼 독립적 API)
      final int fileSize = await image.length();
      final int maxSize = 5 * 1024 * 1024; // 5MB
      print('이미지 파일 크기: ${fileSize} bytes (최대: ${maxSize} bytes)');
      
      if (fileSize > maxSize) {
        Get.snackbar(
          '파일 크기 초과',
          '이미지 파일 크기는 5MB 이하여야 합니다.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      print('ProfileController.updateProfileImage 호출 시작');
      
      // ProfileController를 통해 이미지 업데이트
      final success = await controller.updateProfileImage(image.path);
      print('ProfileController.updateProfileImage 결과: $success');
      
      if (!success) {
        print('이미지 업데이트 실패');
        Get.snackbar(
          '오류',
          '프로필 이미지 업데이트에 실패했습니다.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        print('이미지 업데이트 성공');
      }
    } catch (e) {
      print('이미지 처리 중 오류 발생: $e');
      print('오류 타입: ${e.runtimeType}');
      print('오류 스택: ${StackTrace.current}');
      
      Get.snackbar(
        '오류',
        '이미지 처리 중 오류가 발생했습니다: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 삭제 확인
  void _confirmDelete(ProfileController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('정말 삭제하시겠습니까?'),
        content: const Text(
          '이 작업은 되돌릴 수 없습니다.\n모든 프로필 데이터가 영구적으로 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteUserProfile(confirmDelete: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
