import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
                    ? Image.network(
                        imageUrl,
                        width: 120.w,
                        height: 120.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _defaultProfileIcon();
                        },
                      )
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
          ),
        ],
      ),
    );
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
    if (success) {
      Get.back();
    }
  }

  /// 이미지 선택기 표시
  void _showImagePicker(ProfileController controller) {
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
                onTap: () {
                  Get.back();
                  controller.profileImageUrl.value = '';
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
  void _pickImageFromCamera(ProfileController controller) {
    // TODO: 실제 이미지 선택 구현
    Get.snackbar('준비중', '카메라 기능은 곧 추가될 예정입니다.');
  }

  /// 갤러리에서 이미지 선택
  void _pickImageFromGallery(ProfileController controller) {
    // TODO: 실제 이미지 선택 구현
    Get.snackbar('준비중', '갤러리 기능은 곧 추가될 예정입니다.');
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
