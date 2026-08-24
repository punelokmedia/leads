// features/auth/presentation/screens/otp_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import 'package:user_app/features/auth/presentation/widgets/otp_widgets.dart'; // ✅ Import new widgets
import 'package:user_app/features/auth/shared/auth_providers.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool isGoogleAuth;
  final String googleToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.isGoogleAuth = false,
    this.googleToken = '',
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
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
        timer.cancel();
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
  }

  void _onVerify() {
    if (_otp.length != 6) {
      SnackbarHelper.showWarning(context, 'Enter complete 6-digit OTP');
      return;
    }

    if (widget.isGoogleAuth) {
      ref
          .read(authControllerProvider.notifier)
          .verifyOtpSession(
            phoneNumber: widget.phoneNumber,
            otp: _otp,
            token: widget.googleToken,
            onSuccess: () => context.go(AppRouter.homePath),
          );
    } else {
      ref
          .read(authControllerProvider.notifier)
          .verifyOtp(
            phoneNumber: widget.phoneNumber,
            otp: _otp,
            onSuccess: (needsProfile) {
              // ✅ Only go to profile setup if backend says they need it
              if (needsProfile) {
                context.push(AppRouter.tellUsAboutYourselfPath);
              } else {
                context.go(AppRouter.homePath); // ✅ Existing user → home
              }
            },
          );
    }
  }

  void _onResend() {
    _startTimer();
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});

    if (widget.isGoogleAuth) {
      ref
          .read(authControllerProvider.notifier)
          .requestOtpSession(
            phoneNumber: widget.phoneNumber,
            token: widget.googleToken,
            onSuccess: (otp) {},
          );
    } else {
      ref
          .read(authControllerProvider.notifier)
          .sendOtp(phoneNumber: widget.phoneNumber, onSuccess: (otp) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.error != null &&
          next.error!.isNotEmpty &&
          previous?.error != next.error) {
        SnackbarHelper.showError(context, next.error!);
        Future.microtask(
          () => ref.read(authControllerProvider.notifier).clearError(),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
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
            children: [
              SizedBox(height: 89.h),
              OtpHeader(phoneNumber: widget.phoneNumber), // ✅ Subtitle & Phone
              SizedBox(height: 40.h),

              OtpInputRow(
                // ✅ Fixes Backspace & Handles UI
                controllers: _controllers,
                focusNodes: _focusNodes,
                onChanged: _onOtpChanged,
                onUpdate: () => setState(() {}),
              ),
              SizedBox(height: 18.h),

              Text(
                'Resend OTP IN 00:${_start.toString().padLeft(2, '0')}',
                style: AppTextStyles.poppins(
                  color: AppColors.grey137,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30.h),

              AuthPrimaryButton(
                label: 'Verify OTP',
                isLoading: isLoading,
                onTap: _onVerify,
              ),
              SizedBox(height: 24.h),

              OtpResendRow(
                timerStart: _start,
                onResendTap: _onResend,
              ), // ✅ Resend Logic
              SizedBox(height: 50.h),

              const OtpIllustration(), // ✅ Illustration
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
