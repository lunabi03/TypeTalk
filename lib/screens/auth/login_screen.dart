import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/app_button.dart';
import 'package:typetalk/core/widgets/app_text_field.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/services/auth_service.dart';
import 'package:typetalk/controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.instance;
  final _authController = AuthController.instance;
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 처리
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      // 로그인 성공
      Get.offAllNamed(AppRoutes.start);
    }
  }

  // 비밀번호 재설정
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      Get.snackbar('알림', '이메일을 입력해주세요.');
      return;
    }

    await _authService.sendPasswordResetEmail(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),
                
                // 로고 및 타이틀
                Center(
                  child: Column(
                    children: [
                      Text(
                        'TypeTalk',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'MBTI 기반 소셜 채팅',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 60.h),
                
                // 로그인 폼
                Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                
                // 이메일 입력
                AppTextField(
                  controller: _emailController,
                  hint: '이메일을 입력하세요',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return '올바른 이메일 형식을 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                
                // 비밀번호 입력
                AppTextField(
                  controller: _passwordController,
                  hint: '비밀번호를 입력하세요',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.h),
                
                // 비밀번호 찾기
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      '비밀번호를 잊으셨나요?',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // 로그인 버튼
                AppButton(
                  text: '로그인',
                  onPressed: _isLoading ? null : _handleLogin,
                  isDisabled: _isLoading,
                ),
                
                SizedBox(height: 24.h),
                
                // 또는 구분선
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.textSecondary.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        '또는',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.textSecondary.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
                
                // 소셜 로그인 버튼들
                _buildSocialLoginButtons(),
                
                SizedBox(height: 24.h),
                
                // 회원가입 링크
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요? ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.signup);
                        },
                        child: Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 소셜 로그인 버튼들 위젯
  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        // Google 로그인 버튼
        _buildSocialLoginButton(
          onPressed: _handleGoogleLogin,
          backgroundColor: Colors.white,
          borderColor: AppColors.textSecondary.withOpacity(0.3),
          textColor: AppColors.textPrimary,
          icon: Icons.g_mobiledata, // Google 아이콘 대신 임시 아이콘
          text: 'Google로 로그인',
        ),
        
        SizedBox(height: 12.h),
        
        // Apple 로그인 버튼
        _buildSocialLoginButton(
          onPressed: _handleAppleLogin,
          backgroundColor: Colors.black,
          borderColor: Colors.black,
          textColor: Colors.white,
          icon: Icons.apple,
          text: 'Apple로 로그인',
        ),
      ],
    );
  }

  // 소셜 로그인 버튼 위젯
  Widget _buildSocialLoginButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required IconData icon,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: textColor,
            ),
            SizedBox(width: 12.w),
            Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Google 로그인 처리
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authController.signInWithGoogle();
      if (result != null) {
        Get.offAllNamed(AppRoutes.start);
      }
    } catch (e) {
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Apple 로그인 처리
  Future<void> _handleAppleLogin() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authController.signInWithApple();
      if (result != null) {
        Get.offAllNamed(AppRoutes.start);
      }
    } catch (e) {
      Get.snackbar('오류', 'Apple 로그인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
