import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/services/location_service.dart';
import 'package:typetalk/controllers/chat_controller.dart';

/// 대화 상대 찾기 화면
class FindChatPartnerScreen extends StatelessWidget {
  const FindChatPartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = 0.obs; // 0: 위치 기반, 1: MBTI 궁합 기반
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '대화 상대 찾기',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // TODO: 전체 검색 기능 구현
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 추천 방식 선택 탭
          Container(
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => GestureDetector(
                    onTap: () => selectedTab.value = 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: selectedTab.value == 0 
                            ? AppColors.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: selectedTab.value == 0 
                                ? Colors.white 
                                : Colors.grey[600],
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '위치 기반',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: selectedTab.value == 0 
                                  ? Colors.white 
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ),
                Expanded(
                  child: Obx(() => GestureDetector(
                    onTap: () => selectedTab.value = 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: selectedTab.value == 1 
                            ? const Color(0xFF9C27B0) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: selectedTab.value == 1 
                                ? Colors.white 
                                : Colors.grey[600],
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'MBTI 궁합',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: selectedTab.value == 1 
                                  ? Colors.white 
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
          // 선택된 탭에 따른 내용 표시
          Expanded(
            child: Obx(() {
              if (selectedTab.value == 0) {
                return _buildLocationBasedTab();
              } else {
                return _buildMBTICompatibilityTab();
              }
            }),
          ),
        ],
      ),
    );
  }

  /// 위치 기반 추천 탭
  Widget _buildLocationBasedTab() {
    final locationService = Get.put(LocationService());
    final searchQuery = ''.obs;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // 위치 기반 추천 헤더
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '위치 기반 추천',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '가까운 거리에 있는 사용자를 우선적으로 추천합니다',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() => locationService.isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : IconButton(
                        onPressed: () => _refreshLocationBasedRecommendations(locationService),
                        icon: Icon(Icons.refresh, color: AppColors.primary, size: 24.sp),
                        tooltip: '위치 새로고침',
                      )),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // 검색 바
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: '이름, MBTI, 관심사로 검색',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: Icon(Icons.filter_list, color: Colors.grey[600]),
              ),
              onChanged: (value) {
                searchQuery.value = value;
                // TODO: 사용자 검색 로직 구현
              },
            ),
          ),
          SizedBox(height: 20.h),
          // 사용자 목록
          Obx(() {
            if (locationService.isLoading) {
              return Container(
                height: 200.h,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '가까운 사용자를 찾고 있습니다...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            if (locationService.error.isNotEmpty) {
              return Container(
                height: 200.h,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        locationService.error,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton.icon(
                        onPressed: () => locationService.openLocationSettings(),
                        icon: Icon(Icons.settings),
                        label: Text('위치 설정 열기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // 위치 기반 사용자 목록 (예시 데이터)
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                // 위치 정보가 포함된 사용자 모델 생성
                final user = UserModel(
                  uid: 'user-$index',
                  email: 'user${index + 1}@example.com',
                  name: '사용자${index + 1}',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  mbtiType: ['ENFP', 'INTJ', 'ISFP', 'ENTP', 'INFJ'][index % 5],
                  profileImageUrl: null,
                  // 위치 정보 추가 (서울 지역 기준)
                  latitude: 37.5665 + (index * 0.01), // 위도
                  longitude: 126.9780 + (index * 0.01), // 경도
                  locationName: '서울시 ${['강남구', '서초구', '마포구', '종로구', '중구'][index % 5]}',
                  stats: UserStats(
                    friendCount: (index + 1) * 5,
                    chatCount: (index + 1) * 3,
                    lastLoginAt: DateTime.now(),
                  ),
                );
                
                return _buildLocationBasedUserListItem(
                  user,
                  Get.find<ChatController>(),
                  locationService,
                );
              },
            );
          }),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  /// MBTI 궁합 기반 추천 탭
  Widget _buildMBTICompatibilityTab() {
    final selectedMBTI = 'ENFP'.obs; // 기본값
    final searchQuery = ''.obs;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // MBTI 궁합 추천 헤더
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: const Color(0xFF9C27B0),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MBTI 궁합 기반 추천',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9C27B0),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '성격 유형 궁합이 좋은 사용자를 추천합니다',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF9C27B0).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // MBTI 선택
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '찾고 싶은 MBTI 유형:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16.h),
                // 두 줄 텍스트 칩 높이에 맞춰 컨테이너 높이를 늘려 오버플로우 방지
                SizedBox(
                  height: 72.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildMBTISelectionChip('ENFP', '열정적인', selectedMBTI),
                      _buildMBTISelectionChip('INTJ', '전략적인', selectedMBTI),
                      _buildMBTISelectionChip('ISFP', '예술적인', selectedMBTI),
                      _buildMBTISelectionChip('ENTP', '혁신적인', selectedMBTI),
                      _buildMBTISelectionChip('INFJ', '통찰력 있는', selectedMBTI),
                      _buildMBTISelectionChip('ESTJ', '체계적인', selectedMBTI),
                      _buildMBTISelectionChip('INFP', '이상주의적인', selectedMBTI),
                      _buildMBTISelectionChip('ISTP', '실용적인', selectedMBTI),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // 검색 바
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: '이름, 관심사로 검색',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: Icon(Icons.filter_list, color: Colors.grey[600]),
              ),
              onChanged: (value) {
                searchQuery.value = value;
              },
            ),
          ),
          SizedBox(height: 20.h),
          // 사용자 목록
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) {
              final mbtiTypes = ['ENFP', 'INTJ', 'ISFP', 'ENTP', 'INFJ', 'ESTJ', 'INFP', 'ISTP'];
              final mbtiDescriptions = [
                '열정적이고 창의적인',
                '전략적이고 분석적인',
                '예술적이고 감성적인',
                '혁신적이고 도전적인',
                '통찰력 있고 공감적인',
                '체계적이고 책임감 있는',
                '이상주의적이고 창의적인',
                '실용적이고 적응력 있는'
              ];
              
              final user = UserModel(
                uid: 'mbti-user-$index',
                email: 'mbti${index + 1}@example.com',
                name: '${mbtiTypes[index]} 사용자${index + 1}',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                mbtiType: mbtiTypes[index],
                profileImageUrl: null,
                stats: UserStats(
                  friendCount: (index + 1) * 3,
                  chatCount: (index + 1) * 2,
                  lastLoginAt: DateTime.now(),
                ),
              );
              
              return _buildMBTICompatibilityUserListItem(
                user,
                Get.find<ChatController>(),
                selectedMBTI.value,
                mbtiDescriptions[index],
              );
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  /// MBTI 선택 칩 위젯
  Widget _buildMBTISelectionChip(String mbti, String description, RxString selectedMBTI) {
    final isSelected = selectedMBTI.value == mbti;
    
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: () => selectedMBTI.value = mbti,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF9C27B0) 
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF9C27B0) 
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mbti,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 위치 기반 사용자 목록 항목 위젯
  Widget _buildLocationBasedUserListItem(
    UserModel user,
    ChatController controller,
    LocationService locationService,
  ) {
    // 현재 위치가 있을 때 거리 계산
    String distanceText = '위치 정보 없음';
    if (locationService.currentPosition != null && user.latitude != null && user.longitude != null) {
      final distance = locationService.calculateDistance(
        locationService.currentPosition!.latitude,
        locationService.currentPosition!.longitude,
        user.latitude!,
        user.longitude!,
      );
      distanceText = locationService.formatDistance(distance);
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 프로필 이미지 또는 아바타
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Center(
              child: user.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: Image.network(
                        user.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            user.name.characters.first,
                            style: TextStyle(
                              color: _getMBTIColor(user.mbtiType),
                              fontWeight: FontWeight.bold,
                              fontSize: 24.sp,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      user.name.characters.first,
                      style: TextStyle(
                        color: _getMBTIColor(user.mbtiType),
                        fontWeight: FontWeight.bold,
                        fontSize: 24.sp,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 20.w),
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        user.mbtiType!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: _getMBTIColor(user.mbtiType),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        user.locationName ?? '위치 정보 없음',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      distanceText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '친구 ${user.stats.friendCount}명 • 채팅 ${user.stats.chatCount}개',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 채팅 시작 버튼
          ElevatedButton(
            onPressed: () {
              Get.back(); // 화면 닫기
              controller.startPrivateChatWith(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text(
              '채팅',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// MBTI 궁합 기반 사용자 목록 항목 위젯
  Widget _buildMBTICompatibilityUserListItem(
    UserModel user,
    ChatController controller,
    String selectedMBTI,
    String mbtiDescription,
  ) {
    // MBTI 궁합 점수 계산 (간단한 예시)
    final compatibilityScore = _calculateMBTICompatibility(selectedMBTI, user.mbtiType ?? '');
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 프로필 이미지 또는 아바타
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Center(
              child: user.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: Image.network(
                        user.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            user.name.characters.first,
                            style: TextStyle(
                              color: _getMBTIColor(user.mbtiType),
                              fontWeight: FontWeight.bold,
                              fontSize: 24.sp,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      user.name.characters.first,
                      style: TextStyle(
                        color: _getMBTIColor(user.mbtiType),
                        fontWeight: FontWeight.bold,
                        fontSize: 24.sp,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 20.w),
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _getMBTIColor(user.mbtiType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        user.mbtiType!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: _getMBTIColor(user.mbtiType),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  mbtiDescription,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 16.sp,
                      color: Colors.red[400],
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '궁합 점수: $compatibilityScore%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '친구 ${user.stats.friendCount}명 • 채팅 ${user.stats.chatCount}개',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 채팅 시작 버튼
          ElevatedButton(
            onPressed: () {
              Get.back(); // 화면 닫기
              controller.startPrivateChatWith(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text(
              '채팅',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// MBTI 궁합 점수 계산 (간단한 예시)
  int _calculateMBTICompatibility(String selectedMBTI, String userMBTI) {
    if (selectedMBTI.isEmpty || userMBTI.isEmpty) return 0;
    
    // 간단한 궁합 점수 계산 (실제로는 더 복잡한 알고리즘 사용)
    if (selectedMBTI == userMBTI) return 95; // 같은 MBTI
    
    // 보완적인 궁합 (예시)
    final complementaryPairs = {
      'ENFP': ['INTJ', 'ISTJ'],
      'INTJ': ['ENFP', 'ESFP'],
      'ISFP': ['ENTJ', 'ESTJ'],
      'ENTP': ['ISFJ', 'INFJ'],
      'INFJ': ['ENTP', 'ESTP'],
    };
    
    if (complementaryPairs[selectedMBTI]?.contains(userMBTI) == true) {
      return 88;
    }
    
    // 기본 점수 (50-85 사이)
    return 50 + (userMBTI.hashCode % 36);
  }

  /// MBTI 유형별 색상 반환
  Color _getMBTIColor(String? mbtiType) {
    if (mbtiType == null) return Colors.grey;
    
    final mbtiColors = {
      'ENFP': const Color(0xFFFF6B6B), // 빨간색 계열
      'INTJ': const Color(0xFF4ECDC4), // 청록색 계열
      'ISFP': const Color(0xFF45B7D1), // 파란색 계열
      'ENTP': const Color(0xFF96CEB4), // 초록색 계열
      'INFJ': const Color(0xFFFECA57), // 노란색 계열
      'ESTJ': const Color(0xFFDDA0DD), // 보라색 계열
      'INFP': const Color(0xFFFFB6C1), // 분홍색 계열
      'ISTP': const Color(0xFFDEB887), // 갈색 계열
    };
    
    return mbtiColors[mbtiType] ?? Colors.grey;
  }

  /// 위치 기반 추천 새로고침
  Future<void> _refreshLocationBasedRecommendations(LocationService locationService) async {
    try {
      // 현재 위치 가져오기
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        Get.snackbar(
          '위치 업데이트',
          '현재 위치가 업데이트되었습니다.',
          backgroundColor: AppColors.primary.withOpacity(0.1),
          colorText: AppColors.primary,
        );
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '위치를 가져오는 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }
}
