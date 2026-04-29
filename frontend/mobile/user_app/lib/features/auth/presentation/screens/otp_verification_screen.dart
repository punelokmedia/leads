import 'dart:async';
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

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber; // Added to display the dynamic phone number

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  // Updated to 6 controllers for a 6-digit OTP
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Timer state
  Timer? _timer;
  int _start = 25;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _start = 25);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
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
      backgroundColor: Colors.white, // ✅ Plain white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Enter OTP',
          style: AppTextStyles.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 20/24,
            letterSpacing: 0.01
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25.r,
            color: AppColors.grey102,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 89.h),

              // ── Subtitle ──
              Text(
                'We have sent a 6 digit OTP ON',
                style: AppTextStyles.poppins(
                  color: AppColors.grey137,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  height: 20/16,
                  letterSpacing: 0.01
                ),
              ),
              SizedBox(height: 12.h),

              // ── Phone Number ──
              Text(
                widget.phoneNumber, 
                style: AppTextStyles.poppins(
                  color: AppColors.purple73, 
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.01,
                  height:20/24
                ),
              ),
              SizedBox(height: 40.h),

              // ── 6 OTP Boxes Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48.w, // Adjusted width to fit 6 boxes
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: _focusNodes[index].hasFocus
                            ? const Color(0xFF4522C2)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: AppTextStyles.poppins(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          setState(() {}); // Trigger rebuild to update border color
                          _onOtpChanged(v, index);
                        },
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 18.h),

              // ── Timer ──
              Text(
                'Resend OTP IN 00:${_start.toString().padLeft(2, '0')}',
                style: AppTextStyles.poppins(
                  color: AppColors.grey137,
                  fontSize: 20.sp,
                  height: 20/20,
                  letterSpacing: 0.01,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30.h),

              // ── Primary Button ──
              AuthPrimaryButton(
                label: 'Send OTP', // Note: Image says "Send OTP", but this acts as Verify
                isLoading: state.isLoading,
                onTap: () {
                  if (_otp.length == 6) {
                    ref
                        .read(forgotPasswordControllerProvider.notifier)
                        .verifyOtp(_otp);
                        onSuccess: () => context.push(AppRouter.tellUsAboutYourselfPath);
                  } else {
                    SnackbarHelper.showWarning(context, 'Enter complete 6-digit OTP');
                  }
                },
              ),
              SizedBox(height: 24.h),

              // ── Resend Code Text ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't recieve OTP? ",
                    style: AppTextStyles.poppins(
                      color: AppColors.grey102,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      height: 20/16,
                      letterSpacing: 0.01
                    ),
                  ),
                  GestureDetector(
                    onTap: _start == 0
                        ? () {
                            // Trigger resend logic
                            _startTimer();
                            // final email = ref.read(forgotPasswordControllerProvider).email;
                            // ref.read(forgotPasswordControllerProvider.notifier).sendOtp(email);
                          }
                        : null, // Disabled if timer is still running
                    child: Text(
                      'Resend',
                      style: AppTextStyles.poppins(
                        color: _start == 0 
                            ? AppColors.purple72 
                            : Colors.grey[400], // Greyed out while timer is active
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        height: 20/16,
                        letterSpacing: 0.01
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50.h),

              // ── Bottom Illustration ──
              Image.asset(
                'assets/Images/login/otp_illustration.png', // Ensure you save your image here
                height: 212.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}