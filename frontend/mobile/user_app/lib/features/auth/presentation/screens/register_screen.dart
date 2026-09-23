// auth/presentation/screens/register_screen.dart

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
import 'package:user_app/features/auth/presentation/widgets/register_widgets.dart';
import '../../shared/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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

    context.push(
      AppRouter.verifyNumberPath,
      extra: {
        'isGoogle': false,
        'phone': phone,
      },
    );
  }

  void _onGoogleSignUp() {
    ref.read(authControllerProvider.notifier).googleAuth(
      onSuccess: (String token) {
        if (!mounted) return;
        context.go(AppRouter.homePath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      body: RegisterBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 22.h),
                const RegisterHeader(),
                SizedBox(height: 44.h),

                if (error != null) ...[
                  AuthErrorBanner(message: error),
                  SizedBox(height: 16.h),
                ],

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
                      border: InputBorder.none,
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
                AuthPrimaryButton(
                  label: 'Continue',
                  isLoading: isLoading,
                  onTap: _onContinue,
                ),
                SizedBox(height: 61.h),
                const OrDivider(text: 'Or Sign up With'),
                SizedBox(height: 93.h),
                GoogleSignInButton(onTap: _onGoogleSignUp),
                SizedBox(height: 39.h),
                Text(
                  "By continuing, you agree to our\nTerms & Conditions and Privacy Policy",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey77,
                    height: 21 / 14,
                  ),
                ),
                SizedBox(height: 34.h),
                const RegisterFooter(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
