import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/domain/forgot_state.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import 'package:user_app/features/auth/shared/forgot_password_provider.dart';

class ForgotChangePasswordScreen extends ConsumerStatefulWidget {
  const ForgotChangePasswordScreen({super.key});

  @override
  ConsumerState<ForgotChangePasswordScreen> createState() =>
      _ForgotChangePasswordScreenState();
}

class _ForgotChangePasswordScreenState
    extends ConsumerState<ForgotChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider, (
      prev,
      next,
    ) {
      if (!(prev?.isSuccess ?? false) && next.isSuccess) {
        SnackbarHelper.showSuccess(context, 'Password changed successfully!');

        context.go(AppRouter.login);
      }
      if (next.errorMessage != null) {
        SnackbarHelper.showError(context, next.errorMessage!);

        ref.read(forgotPasswordControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Change Password',
          style: AppTextStyles.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
            height: 20 / 24,
            letterSpacing: 0.01,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.r,
            color: Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h),

                        // New Password Label
                        Text(
                          'New Password',
                          style: AppTextStyles.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey137,
                            height: 20 / 18,
                            letterSpacing: 0.01,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          style: AppTextStyles.poppins(fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            hintStyle: AppTextStyles.poppins(
                              color: AppColors.grey163,
                              fontSize: 16.sp,
                              height: 0.1,
                              letterSpacing: 0.01,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 18.h,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),

                        SizedBox(height: 24.h),

                        // Confirm Password Label
                        Text(
                          'Confirm Password',
                          style: AppTextStyles.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey137,
                            height: 20 / 18,
                            letterSpacing: 0.01,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: AppTextStyles.poppins(fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText:
                                'Confirm Password', // Matches Figma example
                            hintStyle: AppTextStyles.poppins(
                              color: AppColors.grey163,
                              fontSize: 16.sp,
                              height: 0.1,
                              letterSpacing: 0.01,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 18.h,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 48.h),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 24.h),
                            child: Image.asset(
                              'assets/Images/login/reset_password.png',
                              height: 275.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        SizedBox(height: 100.h),
                        // Update Button
                        AuthPrimaryButton(
                          label: 'Update',
                          isLoading: state.isLoading,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              ref
                                  .read(
                                    forgotPasswordControllerProvider.notifier,
                                  )
                                  .changePassword(
                                    newPassword: _newPasswordController.text,
                                    confirmPassword:
                                        _confirmPasswordController.text,
                                  );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
