import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typetalk/core/theme/app_colors.dart';
import 'package:typetalk/core/theme/app_text_styles.dart';
import 'package:typetalk/core/widgets/app_button.dart';
import 'package:typetalk/core/widgets/app_text_field.dart';
import 'package:typetalk/routes/app_routes.dart';
import 'package:typetalk/controllers/auth_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingName = false;
  bool _isNameAvailable = false;
  bool _hasCheckedName = false;
  bool _isCheckingEmail = false;
  bool _isEmailAvailable = false;
  bool _hasCheckedEmail = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 이름 중복 확인 처리
  Future<void> _checkNameAvailability() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty || name.length < 2) {
      Get.snackbar('알림', '이름을 2자 이상 입력해주세요.');
      return;
    }

    setState(() {
      _isCheckingName = true;
    });

    try {
      final isAvailable = await _authController.checkNameAvailability(name);
      
      setState(() {
        _isNameAvailable = isAvailable;
        _hasCheckedName = true;
      });
      
      // 이름이 사용 불가능한 경우 입력창 포커스
      if (!isAvailable) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
      
    } catch (e) {
      print('이름 중복 확인 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingName = false;
        });
      }
    }
  }

  // 이메일 중복 확인 처리
  Future<void> _checkEmailAvailability() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      Get.snackbar('알림', '이메일을 입력해주세요.');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar('알림', '올바른 이메일 형식을 입력해주세요.');
      return;
    }

    setState(() {
      _isCheckingEmail = true;
    });

    try {
      final isAvailable = await _authController.checkEmailAvailability(email);
      
      setState(() {
        _isEmailAvailable = isAvailable;
        _hasCheckedEmail = true;
      });
      
      // 이메일이 사용 불가능한 경우 입력창 포커스
      if (!isAvailable) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
      
    } catch (e) {
      print('이메일 중복 확인 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  // 회원가입 처리
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // 이름 중복 확인이 완료되지 않았거나 사용 불가능한 경우
    if (!_hasCheckedName || !_isNameAvailable) {
      Get.snackbar(
        '알림', 
        '사용 가능한 이름인지 먼저 확인해주세요.',
        backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
        colorText: const Color(0xFFFF9800),
      );
      return;
    }

    // 이메일 중복 확인이 완료되지 않았거나 사용 불가능한 경우
    if (!_hasCheckedEmail || !_isEmailAvailable) {
      Get.snackbar(
        '알림', 
        '사용 가능한 이메일인지 먼저 확인해주세요.',
        backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
        colorText: const Color(0xFFFF9800),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      // AuthController에서 자동으로 리다이렉트 처리
      Get.snackbar('환영합니다!', '회원가입이 완료되었습니다.');
    } catch (e) {
      // 이메일 중복 오류인 경우 중복 확인 상태 초기화
      if (e.toString().contains('이미 사용 중인 이메일입니다')) {
        setState(() {
          _hasCheckedEmail = false;
          _isEmailAvailable = false;
        });
        Get.snackbar(
          '이메일 중복', 
          '이미 사용 중인 이메일입니다. 다른 이메일을 사용하거나 중복 확인을 다시 해주세요.',
          backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
          colorText: const Color(0xFFFF9800),
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar('오류', '회원가입 중 오류가 발생했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '회원가입',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32.h),
                
                // 환영 메시지
                Text(
                  'TypeTalk에\n오신 것을 환영합니다!',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'MBTI 기반의 새로운 소셜 경험을 시작해보세요',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // 이름 입력
                Text(
                  '이름',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                
                // 이름 입력 필드와 중복 확인 버튼
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _nameController,
                        hint: '이름을 입력하세요',
                        onChanged: (value) {
                          // 이름이 변경되면 중복 확인 상태 초기화
                          setState(() {
                            _hasCheckedName = false;
                            _isNameAvailable = false;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          if (value.trim().length < 2) {
                            return '이름은 2자 이상이어야 합니다';
                          }
                          if (_hasCheckedName && !_isNameAvailable) {
                            return '이미 사용 중인 이름입니다';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      height: 56.h,
                      child: Tooltip(
                        message: _nameController.text.trim().length < 2 
                            ? '이름을 2자 이상 입력해주세요'
                            : '이름 중복을 확인해주세요',
                        child: ElevatedButton(
                          onPressed: _isCheckingName 
                              ? null 
                              : _checkNameAvailability,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCheckingName 
                                ? AppColors.textSecondary.withOpacity(0.3)
                                : (_nameController.text.trim().length >= 2 
                                    ? AppColors.primary 
                                    : AppColors.textSecondary.withOpacity(0.5)),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isCheckingName
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  '중복확인',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 이름 중복 확인 결과 표시
                if (_hasCheckedName) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        _isNameAvailable ? Icons.check_circle : Icons.cancel,
                        size: 16.sp,
                        color: _isNameAvailable 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFFFF9800),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _isNameAvailable 
                            ? '"${_nameController.text.trim()}"은(는) 사용 가능한 이름입니다.'
                            : '"${_nameController.text.trim()}"은(는) 이미 사용 중인 이름입니다.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _isNameAvailable 
                              ? const Color(0xFF4CAF50) 
                              : const Color(0xFFFF9800),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                
                SizedBox(height: 20.h),
                
                // 이메일 입력
                Text(
                  '이메일',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                
                // 이메일 입력 필드와 중복 확인 버튼
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _emailController,
                        hint: '이메일을 입력하세요',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          // 이메일이 변경되면 중복 확인 상태 초기화
                          setState(() {
                            _hasCheckedEmail = false;
                            _isEmailAvailable = false;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          if (!GetUtils.isEmail(value)) {
                            return '올바른 이메일 형식을 입력해주세요';
                          }
                          if (_hasCheckedEmail && !_isEmailAvailable) {
                            return '이미 사용 중인 이메일입니다';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      height: 56.h,
                      child: Tooltip(
                        message: _emailController.text.trim().isEmpty || !GetUtils.isEmail(_emailController.text.trim())
                            ? '올바른 이메일을 입력해주세요'
                            : '이메일 중복을 확인해주세요',
                        child: ElevatedButton(
                          onPressed: _isCheckingEmail 
                              ? null 
                              : _checkEmailAvailability,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCheckingEmail 
                                ? AppColors.textSecondary.withOpacity(0.3)
                                : (_emailController.text.trim().isNotEmpty && GetUtils.isEmail(_emailController.text.trim())
                                    ? AppColors.primary 
                                    : AppColors.textSecondary.withOpacity(0.5)),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isCheckingEmail
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  '중복확인',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 이메일 중복 확인 결과 표시
                if (_hasCheckedEmail) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        _isEmailAvailable ? Icons.check_circle : Icons.cancel,
                        size: 16.sp,
                        color: _isEmailAvailable 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFFFF9800),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _isEmailAvailable 
                            ? '"${_emailController.text.trim()}"은(는) 사용 가능한 이메일입니다.'
                            : '"${_emailController.text.trim()}"은(는) 이미 사용 중인 이메일입니다.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _isEmailAvailable 
                              ? const Color(0xFF4CAF50) 
                              : const Color(0xFFFF9800),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                
                SizedBox(height: 20.h),
                
                // 비밀번호 입력
                Text(
                  '비밀번호',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                AppTextField(
                  controller: _passwordController,
                  hint: '비밀번호를 입력하세요 (6자 이상)',
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
                SizedBox(height: 20.h),
                
                // 비밀번호 확인
                Text(
                  '비밀번호 확인',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                AppTextField(
                  controller: _confirmPasswordController,
                  hint: '비밀번호를 다시 입력하세요',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호 확인을 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 40.h),
                
                // 회원가입 버튼
                AppButton(
                  text: _isLoading 
                      ? '가입 중...' 
                      : (_hasCheckedName && _isNameAvailable && _hasCheckedEmail && _isEmailAvailable 
                          ? '회원가입' 
                          : '이름 및 이메일 중복 확인 필요'),
                  onPressed: (_isLoading || !_hasCheckedName || !_isNameAvailable || !_hasCheckedEmail || !_isEmailAvailable) 
                      ? null 
                      : _handleSignup,
                  isDisabled: _isLoading || !_hasCheckedName || !_isNameAvailable || !_hasCheckedEmail || !_isEmailAvailable,
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
                
                // 로그인 링크
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요? ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: Text(
                          '로그인',
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
          text: 'Google로 계속하기',
        ),
        
        SizedBox(height: 12.h),
        
        // Apple 로그인 버튼
        _buildSocialLoginButton(
          onPressed: _handleAppleLogin,
          backgroundColor: Colors.black,
          borderColor: Colors.black,
          textColor: Colors.white,
          icon: Icons.apple,
          text: 'Apple로 계속하기',
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
      // signInWithGoogle이 성공하면 자동으로 리다이렉트됨
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
      // signInWithApple이 성공하면 자동으로 리다이렉트됨
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
