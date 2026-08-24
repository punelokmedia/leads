// features/auth/presentation/widgets/otp_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

// ── 1. OTP Header (Subtitle & Phone) ──
class OtpHeader extends StatelessWidget {
  final String phoneNumber;
  const OtpHeader({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'We have sent a 6 digit OTP ON',
          style: AppTextStyles.poppins(
            color: AppColors.grey137,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            height: 20 / 16,
            letterSpacing: 0.01,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          phoneNumber,
          style: AppTextStyles.poppins(
            color: AppColors.purple73,
            fontSize: 24.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.01,
            height: 20 / 24,
          ),
        ),
      ],
    );
  }
}

// ── 2. OTP Input Row (With Fixed Backspace Logic) ──
class OtpInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String, int) onChanged;
  final VoidCallback onUpdate; // Triggers UI rebuild for border colors

  const OtpInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 48.w,
          height: 52.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: focusNodes[index].hasFocus ? const Color(0xFF4522C2) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Center(
            // ✅ FIX: Focus widget listens to hardware keys to detect backspace on empty fields
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (controllers[index].text.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                    controllers[index - 1].clear(); // Clear previous box on backspace
                    onUpdate();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
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
                  onUpdate();
                  onChanged(v, index);
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── 3. Resend Action Row ──
class OtpResendRow extends StatelessWidget {
  final int timerStart;
  final VoidCallback onResendTap;

  const OtpResendRow({super.key, required this.timerStart, required this.onResendTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't recieve OTP? ",
          style: AppTextStyles.poppins(
            color: AppColors.grey102,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            height: 20 / 16,
            letterSpacing: 0.01,
          ),
        ),
        GestureDetector(
          onTap: timerStart == 0 ? onResendTap : null,
          child: Text(
            'Resend',
            style: AppTextStyles.poppins(
              color: timerStart == 0 ? AppColors.purple72 : Colors.grey[400],
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              height: 20 / 16,
              letterSpacing: 0.01,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 4. OTP Illustration ──
class OtpIllustration extends StatelessWidget {
  const OtpIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Images/login/otp_illustration.png',
      height: 212.h,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.sms_outlined,
        size: 80.r,
        color: AppColors.purple73,
      ),
    );
  }
}