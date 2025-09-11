import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/app_button.dart';
import 'package:typetalk/core/widgets/app_text_field.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _autoLogin = true; // 자동 로그인 기본값 ON

  @override
  void initState() {
    super.initState();
    _loadAutoLoginSetting();

    // 로그인 상태 변경을 감지하여 자동 리다이렉트
    _authController.currentUserId.listen((uid) {
      if (_autoLogin && uid.isNotEmpty) {
        Get.offAllNamed(AppRoutes.start);
      }
    });
  }

  // 자동 로그인 설정 로드 및 적용
  Future<void> _loadAutoLoginSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('auto_login_enabled');
    if (mounted) {
      setState(() {
        _autoLogin = saved ?? true; // 저장값 없으면 기본 ON
      });
    }

    // 이미 세션이 있으면 바로 메인으로 이동
    if (_autoLogin && _authController.isLoggedIn) {
      Get.offAllNamed(AppRoutes.start);
    }
    // 혹시 초기화 지연 대비하여 한 번 더 지연 체크
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_autoLogin && _authController.isLoggedIn) {
        Get.offAllNamed(AppRoutes.start);
      }
    });
  }

  Future<void> _saveAutoLoginSetting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_login_enabled', _autoLogin);
  }

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

    try {
      await _authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // 로그인 성공 시 자동 로그인 설정 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_login_enabled', _autoLogin);
    } catch (e) {
      // 로그인 실패 시 오류 메시지는 AuthController에서 처리되므로
      // 여기서는 추가 처리가 필요하지 않음
      print('로그인 화면에서 오류 처리: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 비밀번호 재설정
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      Get.snackbar('알림', '이메일을 입력해주세요.');
      return;
    }

    try {
      await _authController.sendPasswordResetEmail(_emailController.text.trim());
      Get.snackbar('성공', '비밀번호 재설정 이메일이 전송되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '비밀번호 재설정 이메일 전송에 실패했습니다.');
    }
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
                
                // 자동 로그인 스위치
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '자동 로그인',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: _autoLogin,
                      onChanged: (v) async {
                        setState(() => _autoLogin = v);
                        await _saveAutoLoginSetting();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

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
          icon: Icons.g_mobiledata, // Google 아이콘 (실제로는 Google 로고 이미지를 사용하는 것이 좋음)
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
      await _authController.signInWithGoogle();
      // 자동 로그인 설정 저장 (구글 로그인 포함)
      await _saveAutoLoginSetting();
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
      await _authController.signInWithApple();
      // 자동 로그인 설정 저장 (애플 로그인 포함)
      await _saveAutoLoginSetting();
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
