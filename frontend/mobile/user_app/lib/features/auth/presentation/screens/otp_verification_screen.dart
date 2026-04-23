import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/domain/forgot_state.dart'
    show ForgotPasswordState, ForgotPasswordStep;
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import 'package:user_app/features/auth/shared/forgot_password_provider.dart';
import '../widgets/auth_widgets.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider, (
      prev,
      next,
    ) {
      if (prev?.step != next.step &&
          next.step == ForgotPasswordStep.newPassword) {
        context.push(AppRouter.forgotChangePasswordPath);
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
        title: Text(
          'Verification',
          style: AppTextStyles.poppins(
            color: AppColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 22/24
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 34.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40.h),
                      Text(
                        'Enter your Verification Code',
                        style: AppTextStyles.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          height: 34/20
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Enter the verification code to confirm your identity.',
                        style: AppTextStyles.poppins(
                          color: AppColors.grey77,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 48.h),

                      // OTP Boxes Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Spacing like Figma
                        children: List.generate(4, (index) {
                          return Container(
                            width: 70
                                .w, // Slightly wider to match Figma proportion
                            height: 70.h,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                15.r,
                              ), // Rounded corners from Figma
                              border: Border.all(
                                color:
                                    AppColors.grey163, // Light grey border
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: AppTextStyles.poppins(
                                  fontSize: 28.sp, // Larger text for OTP
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder
                                      .none, // Hide default border to use Container's border
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) => _onOtpChanged(v, index),
                              ),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: 24.h),

                      // Resend Code logic
                      Row(
                        children: [
                          Text(
                            "I didn't received the code? ",
                            style: AppTextStyles.poppins(
                              color: AppColors.grey77,
                              fontSize: 13.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final email = ref
                                  .read(forgotPasswordControllerProvider)
                                  .email;
                              ref
                                  .read(
                                    forgotPasswordControllerProvider.notifier,
                                  )
                                  .sendOtp(email);
                            },
                            child: Text(
                              'Send again',
                              style: AppTextStyles.poppins(
                                color: const Color(
                                  0xFFE65100,
                                ), // Darker orange for visibility
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 48.h),

                      // Primary Verify Button
                      AuthPrimaryButton(
                        label: 'Verify',
                        isLoading: state.isLoading,
                        onTap: () {
                          if (_otp.length == 4) {
                            ref
                                .read(forgotPasswordControllerProvider.notifier)
                                .verifyOtp(_otp);
                          } else {
                            SnackbarHelper.showWarning(context, 'Enter complete OTP');
                            
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Illustration (from Figma)
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Image.asset(
                  'assets/Images/profile/change_password_illustration.png', // Ensure path is correct
                  height: 180.h,
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
