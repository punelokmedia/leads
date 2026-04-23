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
import '../widgets/auth_widgets.dart'; 

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    // Listen for step changes and errors
    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider, (prev, next) {
      if (prev?.step != next.step && next.step == ForgotPasswordStep.otp) {
        context.push(AppRouter.otpVerificationPath);
      }
      if (next.errorMessage != null) {
        SnackbarHelper.showError(context, next.errorMessage!);
        ref.read(forgotPasswordControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Centered Logo as per Figma Title area
        title: Image.asset(
          'assets/Images/home/logo_leads.png', // Correct path for your logo
          height: 60.h,
          fit: BoxFit.contain,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
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
              Color.fromARGB(255, 255, 198, 28)
            ],
            stops: [0.40, 0.70, 1.0],
          ),
        ),
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
                        SizedBox(height: 60.h),
                        // Figma Title
                        Center(
                          child: Text(
                            'Forget Password',
                            style: AppTextStyles.poppins(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              height: 20/24,
                              letterSpacing: 0.01
                            ),
                          ),
                        ),
                        SizedBox(height: 48.h),

                        // Label
                        Text(
                          'Email ID',
                          style: AppTextStyles.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey77,
                            height: 20/18,
                            letterSpacing: 0.01
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Enter your Email ID to change the password',
                          style: AppTextStyles.poppins(
                            fontSize: 14.sp,
                            color: AppColors.grey77,
                            height: 25/14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // TextFormField matching the "Pill" style in your image
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.poppins(
                              color: AppColors.grey163,
                              fontSize: 16.sp,
                              height: 20/16,
                              letterSpacing: 0.01,
                              fontWeight: FontWeight.w500
                            ),
                          decoration: InputDecoration(
                            hintText: 'johndoe@gmail.com',
                            hintStyle: AppTextStyles.poppins(
                              color: AppColors.grey163,
                              fontSize: 16.sp,
                              height: 20/16,
                              letterSpacing: 0.01,
                              fontWeight: FontWeight.w500
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
                            // Floating shadow effect through border
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        SizedBox(height: 85.h),

                        // Yellow Primary Button
                        AuthPrimaryButton(
                          label: 'Get OTP',
                          isLoading: state.isLoading,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              ref.read(forgotPasswordControllerProvider.notifier)
                                 .sendOtp(_emailController.text.trim());
                            }
                          },
                        ),

                        SizedBox(height: 20.h),
                        
                        Center(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Back to Login',
                              style: AppTextStyles.poppins(
                                fontSize: 14.sp,
                                color: AppColors.black,
                                fontWeight: FontWeight.w500,
                                height: 20/14,
                                letterSpacing: 0.01
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Figma Illustration at the bottom of the safe area
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Image.asset(
                  'assets/Images/login/forgot_password.png',
                  height: 185.h,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}