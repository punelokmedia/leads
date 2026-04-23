// auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_field_widgets.dart';
import '../../shared/auth_providers.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      // 2. Show a SnackBar or Toast for immediate feedback
      SnackbarHelper.showError(
        context,
        'Please fill all required fields correctly',
      );

      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          onSuccess: () => context.go(AppRouter.homePath), // adjust route
        );
  }

  void _onGoogleLogin() {
    ref
        .read(authControllerProvider.notifier)
        .googleAuth(onSuccess: () => context.go(AppRouter.homePath));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F0F0),
              Color(0xFFF0F0F0),
              Color.fromARGB(255, 255, 198, 28),
            ],
            stops: [0.40, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(child: const AuthLogo()),
                  SizedBox(height: 32.h),

                  // Title
                  Center(
                    child: Text(
                      'Welcome Back',
                      style: AppTextStyles.poppins(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        height: 20 / 24,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Center(
                    child: Text(
                      'Login to access your account',
                      style: AppTextStyles.poppins(
                        fontSize: 16.sp,
                        color: AppColors.grey77,
                        fontWeight: FontWeight.w500,
                        height: 20 / 16,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Error banner
                  if (error != null) ...[
                    AuthErrorBanner(message: error),
                    SizedBox(height: 12.h),
                  ],

                  // Email
                  AuthTextField(
                    label: 'Email ID',
                    hint: 'Enter your email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Password
                  PasswordField(
                    controller: _passwordCtrl,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 10.h),

                  // Remember me + Forgot password
                  Row(
                    children: [
                      SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: const Color(0xFFFFC107),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Remember me',
                        style: AppTextStyles.poppins(
                          fontSize: 14.sp,
                          color: AppColors.grey77,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push(AppRouter.forgotPasswordPath),
                        child: Text(
                          'Forget password ?',
                          style: AppTextStyles.poppins(
                            fontSize: 14.sp,
                            color: AppColors.grey77,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Login button
                  AuthPrimaryButton(
                    label: 'Login',
                    isLoading: isLoading,
                    onTap: _onLogin,
                  ),
                  SizedBox(height: 33.h),

                  // Or divider
                  const OrDivider(),
                  SizedBox(height: 16.h),

                  // Google button
                  Center(child: GoogleSignInButton(onTap: _onGoogleLogin)),
                  SizedBox(height: 24.h),

                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTextStyles.poppins(
                            fontSize: 14.sp,
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                            height: 20 / 14,
                            letterSpacing: 0.1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(authControllerProvider.notifier)
                                .clearError();
                            context.push(AppRouter.register);
                          },
                          child: Text(
                            'Sign Up',
                            style: AppTextStyles.poppins(
                              fontSize: 14.sp,
                              color: AppColors.red237,
                              fontWeight: FontWeight.w500,
                              height: 20 / 14,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
