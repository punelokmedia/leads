// features/auth/presentation/screens/otp_verification_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
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
    if (ref.read(authIsLoadingProvider)) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_otp)) {
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
            onSuccess: () {
              if (mounted) context.go(AppRouter.homePath);
            },
          );
    } else {
      ref
          .read(authControllerProvider.notifier)
          .verifyOtp(
            phoneNumber: widget.phoneNumber,
            otp: _otp,
            onSuccess: (needsProfile) {
              if (!mounted) return;
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
    if (_start > 0 || ref.read(authIsLoadingProvider)) return;
    void onSent(String otp) {
      if (!mounted) return;
      for (final controller in _controllers) {
        controller.clear();
      }
      _startTimer();
      _focusNodes.first.requestFocus();
    }

    final controller = ref.read(authControllerProvider.notifier);
    if (widget.isGoogleAuth) {
      controller.requestOtpSession(
        phoneNumber: widget.phoneNumber,
        token: widget.googleToken,
        onSuccess: onSent,
      );
    } else {
      controller.sendOtp(phoneNumber: widget.phoneNumber, onSuccess: onSent);
    }
  }

  String get _displayPhone {
    var digits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits.length == 10
        ? '+91 ${digits.substring(0, 5)} ${digits.substring(5)}'
        : widget.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF061139);
    const muted = Color(0xFF929DB6);
    const blue = Color(0xFF0047FF);
    final isLoading = ref.watch(authIsLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              left: -65,
              right: -60,
              bottom: -140,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.055,
                  child: Image.asset(
                    'assets/Nextlead Mobile  App Asetes/NextLead Arrow only.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = math.min(constraints.maxWidth / 393, 1.25);
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(horizontal: 19 * scale),
                    child: Column(
                      children: [
                        SizedBox(height: 12 * scale),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Back',
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go(
                                        AppRouter.verifyNumberPath,
                                        extra: {
                                          'phone': widget.phoneNumber,
                                          'isGoogle': widget.isGoogleAuth,
                                          'token': widget.googleToken,
                                        },
                                      );
                                    }
                                  },
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: navy,
                              size: 24 * scale,
                            ),
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Image.asset(
                          'assets/branding/nextlead_wordmark.webp',
                          width: 178 * scale,
                          height: 64 * scale,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 55 * scale),
                        Text(
                          'Enter OTP',
                          style: AppTextStyles.inter(
                            fontSize: 38 * scale,
                            fontWeight: FontWeight.w800,
                            color: navy,
                            letterSpacing: -1.5 * scale,
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Text(
                          'We have sent a 6-digit code to',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.inter(
                            fontSize: 17 * scale,
                            color: muted,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        Text(
                          _displayPhone,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.inter(
                            fontSize: 18 * scale,
                            color: navy,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 39 * scale),
                        if (error != null) ...[
                          AuthErrorBanner(message: error),
                          SizedBox(height: 12 * scale),
                        ],
                        Row(
                          children: List.generate(
                            6,
                            (index) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == 5 ? 0 : 9 * scale,
                                ),
                                child: Focus(
                                  onKeyEvent: (_, event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.backspace &&
                                        _controllers[index].text.isEmpty &&
                                        index > 0) {
                                      _controllers[index - 1].clear();
                                      _focusNodes[index - 1].requestFocus();
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    enabled: !isLoading,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    textInputAction: index == 5
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    autofillHints: index == 0
                                        ? const [AutofillHints.oneTimeCode]
                                        : null,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    style: AppTextStyles.inter(
                                      fontSize: 21 * scale,
                                      fontWeight: FontWeight.w700,
                                      color: navy,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 17 * scale,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8 * scale,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFAFB9D0),
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8 * scale,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8 * scale,
                                        ),
                                        borderSide: const BorderSide(
                                          color: blue,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onTap: () => _controllers[index].selection =
                                        TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              _controllers[index].text.length,
                                        ),
                                    onChanged: (value) {
                                      if (value.length > 1) {
                                        final digits = value.split('');
                                        final start = digits.length == 6
                                            ? 0
                                            : index;
                                        for (
                                          var i = start;
                                          i < 6 && i - start < digits.length;
                                          i++
                                        ) {
                                          _controllers[i].text =
                                              digits[i - start];
                                        }
                                        _focusNodes[math.min(
                                              start + digits.length,
                                              5,
                                            )]
                                            .requestFocus();
                                      } else if (value.isEmpty && index > 0) {
                                        _focusNodes[index - 1].requestFocus();
                                      } else {
                                        _onOtpChanged(value, index);
                                      }
                                    },
                                    onSubmitted: (_) {
                                      if (index == 5) _onVerify();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 23 * scale),
                        TextButton(
                          onPressed: _start == 0 && !isLoading
                              ? _onResend
                              : null,
                          child: Text(
                            _start > 0
                                ? 'Resend OTP in 00:${_start.toString().padLeft(2, '0')}'
                                : 'Resend OTP',
                            style: AppTextStyles.inter(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w500,
                              color: _start > 0 ? muted : blue,
                            ),
                          ),
                        ),
                        SizedBox(height: 25 * scale),
                        SizedBox(
                          width: double.infinity,
                          height: 57 * scale,
                          child: FilledButton(
                            onPressed: isLoading ? null : _onVerify,
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Verify OTP',
                                        style: AppTextStyles.inter(
                                          fontSize: 19 * scale,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 14 * scale),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 27 * scale,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: 32 * scale),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
