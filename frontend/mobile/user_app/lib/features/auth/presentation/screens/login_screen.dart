// auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import '../../shared/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final phone = _phoneCtrl.text.trim();

    // ── Manual Validation (Prevents ugly red text in the TextField) ──
    if (phone.isEmpty) {
      SnackbarHelper.showError(context, 'Mobile number is required');
      return;
    }
    if (phone.length < 10) {
      SnackbarHelper.showError(
        context,
        'Please enter a valid 10-digit mobile number',
      );
      return;
    }

    // Proceed to next screen
    context.push(AppRouter.verifyNumberPath, extra: phone);
  }

  void _onGoogleLogin() {
    ref
        .read(authControllerProvider.notifier)
        .googleAuth(onSuccess: () => context.go(AppRouter.verifyNumberPath));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      // ── Background Gradient ──
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white, // Top is white
              Colors.white, // Middle is white
              Color(0xFF9F75FF), // Bottom fades into light purple
            ],
            stops: [
              0.0,
              0.65,
              1.0,
            ], // Controls where the gradient starts blending
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 22.h),

                // ── Logo ──
                Image.asset('assets/Images/login/lead_logo.png', width: 150.w),
                SizedBox(height: 24.h),

                // ── Title ──
                Text(
                  'Welcome Back',
                  style: AppTextStyles.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    height: 20 / 24,
                    letterSpacing: 0.01,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Login to access your account',
                  style: AppTextStyles.poppins(
                    fontSize: 16.sp,
                    color: AppColors.grey77,
                    fontWeight: FontWeight.w500,
                    height: 20 / 16,
                    letterSpacing: 0.01,
                  ),
                ),
                SizedBox(height: 44.h),

                // ── Backend Error Banner ──
                if (error != null) ...[
                  AuthErrorBanner(message: error),
                  SizedBox(height: 16.h),
                ],

                // ── Mobile Number Label ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter Mobile Number',
                    style: AppTextStyles.poppins(
                      fontSize: 18.sp,
                      color: AppColors.grey77,
                      height: 20 / 18,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                // ── Custom Mobile Number Field with Soft Shadow ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: AppTextStyles.poppins(
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '9845 372784',
                      hintStyle: AppTextStyles.poppins(
                        fontSize: 16.sp,
                        color: AppColors.grey163,
                        height: 20 / 16,
                        letterSpacing: 0.01,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 18.h),
                      border: InputBorder.none, // Kept clean
                      enabledBorder: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF4522C2),
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+91',
                              style: AppTextStyles.poppins(
                                fontSize: 16.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              width: 1.w,
                              height: 24.h,
                              color: Colors.grey[300],
                            ),
                            SizedBox(width: 8.w),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 50.h),

                // ── Continue Button ──
                AuthPrimaryButton(
                  label: 'Continue',
                  isLoading: isLoading,
                  onTap: _onContinue,
                ),
                SizedBox(height: 61.h),

                // ── Or Divider ──
                const OrDivider(),
                SizedBox(height: 93.h),

                // ── Google Button ──
                GoogleSignInButton(onTap: _onGoogleLogin),
                SizedBox(height: 39.h),

                // ── Terms & Conditions ──
                Text(
                  "By continuing, you agree to our\nTerms & Conditions and Privacy Policy",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                    height: 21 / 14,
                  ),
                ),
                SizedBox(height: 34.h),

                // ── Sign Up Link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.poppins(
                        fontSize: 16.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                        height: 20 / 16,
                        letterSpacing: 0.01,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(authControllerProvider.notifier).clearError();
                        context.push(AppRouter.register);
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.poppins(
                          fontSize: 14.sp,
                          color: AppColors.red237, // Red text
                          fontWeight: FontWeight.w500,
                          height: 20 / 16,
                          letterSpacing: 0.01,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
