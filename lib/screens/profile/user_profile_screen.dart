import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:typetalk/models/user_model.dart';
import 'package:typetalk/services/real_user_repository.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/widgets/app_button.dart';

import 'package:typetalk/services/chat_invite_service.dart';

// 상대방 사용자 프로필 화면
class UserProfileScreen extends StatefulWidget {
  final String userId;
  
  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final RealUserRepository _userRepository = Get.find<RealUserRepository>();

  final ChatInviteService _inviteService = Get.find<ChatInviteService>();
  
  UserModel? _user;
  bool _isLoading = true;
  bool _isInviteSent = false;
  bool _isInvitePending = false;
  String? _pendingInviteId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkInviteStatus();
  }

  /// 사용자 프로필 로드
  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final user = await _userRepository.getUser(widget.userId);
      if (user != null) {
        setState(() => _user = user);
      }
    } catch (e) {
      print('사용자 프로필 로드 실패: $e');
      Get.snackbar(
        '오류',
        '사용자 정보를 불러올 수 없습니다.',
        backgroundColor: const Color(0xFFFF0000),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 초대 상태 확인
  Future<void> _checkInviteStatus() async {
    try {
      // 이미 보낸 초대가 있는지 확인
      final existingInvite = _inviteService.findInviteToUser(widget.userId);
      if (existingInvite != null) {
        setState(() {
          _isInviteSent = true;
          _isInvitePending = existingInvite.isPending;
          _pendingInviteId = existingInvite.inviteId;
        });
      }
    } catch (e) {
      print('초대 상태 확인 실패: $e');
    }
  }

  /// 대화 신청
  Future<void> _requestChat() async {
    try {
      setState(() => _isLoading = true);
      
      // 초대 생성
      final invite = await _inviteService.createDirectChatInvite(
        targetUserId: widget.userId,
        message: '안녕하세요! 대화를 나누고 싶어요.',
      );
      
      if (invite != null) {
        setState(() {
          _isInviteSent = true;
          _isInvitePending = true;
          _pendingInviteId = invite.inviteId;
        });
        
        Get.snackbar(
          '초대 전송 완료',
          '${_user?.name ?? '사용자'}에게 대화 신청을 보냈습니다.',
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('대화 신청 실패: $e');
      Get.snackbar(
        '오류',
        '대화 신청을 보낼 수 없습니다.',
        backgroundColor: const Color(0xFFFF0000),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 초대 취소
  Future<void> _cancelInvite() async {
    try {
      if (_pendingInviteId != null) {
        final success = await _inviteService.cancelInvite(_pendingInviteId!);
        if (success) {
          setState(() {
            _isInviteSent = false;
            _isInvitePending = false;
            _pendingInviteId = null;
          });
          
          Get.snackbar(
            '초대 취소 완료',
            '대화 신청을 취소했습니다.',
            backgroundColor: const Color(0xFFFF9800),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('초대 취소 실패: $e');
      Get.snackbar(
        '오류',
        '초대를 취소할 수 없습니다.',
        backgroundColor: const Color(0xFFFF0000),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          '사용자 프로필',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  /// 오류 상태 표시
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            '사용자 정보를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
                      AppButton(
              text: '다시 시도',
              onPressed: _loadUserProfile,
            ),
        ],
      ),
    );
  }

  /// 프로필 내용 표시
  Widget _buildProfileContent() {
    final user = _user!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 헤더
          _buildProfileHeader(user),
          SizedBox(height: 24.h),
          
          // 사용자 정보
          _buildUserInfo(user),
          SizedBox(height: 24.h),
          
          // MBTI 정보
          if (user.mbtiType != null) ...[
            _buildMBTIInfo(user),
            SizedBox(height: 24.h),
          ],
          
          // 활동 정보
          _buildActivityInfo(user),
          SizedBox(height: 32.h),
          
          // 액션 버튼
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 프로필 헤더
  Widget _buildProfileHeader(UserModel user) {
    return Center(
      child: Column(
        children: [
          // 프로필 이미지
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: user.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(user.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 60.w,
                    color: Colors.grey[400],
                  )
                : null,
          ),
          SizedBox(height: 16.h),
          
          // 사용자 이름
          Text(
            user.name,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          
          // 사용자 ID
          Text(
            '@${user.uid.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 사용자 정보
  Widget _buildUserInfo(UserModel user) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 정보',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          
          _buildInfoRow('이메일', user.email),
          _buildInfoRow('가입일', _formatDate(user.createdAt)),
          _buildInfoRow('마지막 로그인', _formatDate(user.stats.lastLoginAt)),
        ],
      ),
    );
  }

  /// MBTI 정보
  Widget _buildMBTIInfo(UserModel user) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF2196F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🧠 MBTI',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1976D2),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  user.mbtiType!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          Text(
            'MBTI 테스트 완료 횟수: ${user.mbtiTestCount}회',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  /// 활동 정보
  Widget _buildActivityInfo(UserModel user) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '활동 정보',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          
          _buildInfoRow('계정 생성', _formatDate(user.createdAt)),
          _buildInfoRow('프로필 업데이트', _formatDate(user.updatedAt)),
        ],
      ),
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼
  Widget _buildActionButtons() {
    if (_isInvitePending) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFFF9800)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: const Color(0xFFFF9800),
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '대화 신청이 대기 중입니다',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFFFF9800),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          AppButton(
            text: '신청 취소',
            onPressed: _cancelInvite,
            backgroundColor: const Color(0xFFFF9800),
          ),
        ],
      );
    } else if (_isInviteSent) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF4CAF50)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: const Color(0xFF4CAF50),
              size: 24.w,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '대화 신청이 전송되었습니다',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return AppButton(
        text: '대화 신청하기',
        onPressed: _requestChat,
        backgroundColor: AppColors.primary,
      );
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}
