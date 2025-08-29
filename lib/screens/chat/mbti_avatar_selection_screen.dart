import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/models/mbti_avatar_model.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/routes/app_routes.dart';

// MBTI 아바타 선택 화면
class MBTIAvatarSelectionScreen extends StatefulWidget {
  const MBTIAvatarSelectionScreen({super.key});

  @override
  State<MBTIAvatarSelectionScreen> createState() => _MBTIAvatarSelectionScreenState();
}

class _MBTIAvatarSelectionScreenState extends State<MBTIAvatarSelectionScreen> {
  String? selectedMBTI;
  List<MBTIAvatar> allAvatars = [];
  List<MBTIAvatar> filteredAvatars = [];

  @override
  void initState() {
    super.initState();
    allAvatars = MBTIAvatarData.getAllAvatars();
    filteredAvatars = allAvatars;
  }

  // MBTI 유형별 필터링
  void _filterByMBTI(String? mbtiType) {
    setState(() {
      selectedMBTI = mbtiType;
      if (mbtiType == null) {
        filteredAvatars = allAvatars;
      } else {
        filteredAvatars = allAvatars.where((avatar) => avatar.mbtiType == mbtiType).toList();
      }
    });
  }

  // 아바타 선택 및 채팅 화면으로 이동
  void _selectAvatar(MBTIAvatar avatar) {
    Get.toNamed(
      AppRoutes.aiChat,
      arguments: {'avatar': avatar},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          'MBTI 아바타와 대화하기',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // MBTI 필터 섹션
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MBTI 유형 선택',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                // MBTI 유형 칩들
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 전체 보기 칩
                      _buildMBTIChip(null, '전체'),
                      SizedBox(width: 8.w),
                      // 개별 MBTI 유형 칩들
                      ...MBTIAvatarData.avatars.map((avatar) => 
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _buildMBTIChip(avatar.mbtiType, avatar.mbtiType),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 아바타 목록
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: filteredAvatars.length,
              itemBuilder: (context, index) {
                final avatar = filteredAvatars[index];
                return _buildAvatarCard(avatar);
              },
            ),
          ),
        ],
      ),
    );
  }

  // MBTI 유형 칩 위젯
  Widget _buildMBTIChip(String? mbtiType, String label) {
    final isSelected = selectedMBTI == mbtiType;
    
    return GestureDetector(
      onTap: () => _filterByMBTI(mbtiType),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE9ECEF),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // 아바타 카드 위젯
  Widget _buildAvatarCard(MBTIAvatar avatar) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 아바타 이미지 및 기본 정보
          Container(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // 아바타 이미지 (플레이스홀더)
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(avatar.mbtiType),
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child: Center(
                    child: Text(
                      avatar.name[0],
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // 아바타 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            avatar.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: _getAvatarColor(avatar.mbtiType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              avatar.mbtiType,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: _getAvatarColor(avatar.mbtiType),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        avatar.personality,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        avatar.description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black45,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 관심사 및 채팅 버튼
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
            child: Column(
              children: [
                // 관심사 태그들
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: avatar.interests.take(3).map((interest) => 
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
                SizedBox(height: 16.h),
                // 채팅 시작 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () => _selectAvatar(avatar),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getAvatarColor(avatar.mbtiType),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: Text(
                      '${avatar.name}와 대화하기',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MBTI 유형별 색상 반환
  Color _getAvatarColor(String mbtiType) {
    final colorMap = {
      'ENFP': const Color(0xFFFF6B6B),
      'INTJ': const Color(0xFF191970),
      'ISFJ': const Color(0xFFDEB887),
      'ENTP': const Color(0xFF45B7D1),
      'INFJ': const Color(0xFF2E8B57),
      'ESTJ': const Color(0xFF4682B4),
      'ISFP': const Color(0xFFFF69B4),
      'INTP': const Color(0xFF4169E1),
    };

    return colorMap[mbtiType] ?? AppColors.primary;
  }
}

