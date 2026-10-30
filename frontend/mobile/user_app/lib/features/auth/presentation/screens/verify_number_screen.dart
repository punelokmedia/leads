import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import '../../shared/auth_providers.dart';

class VerifyNumberScreen extends ConsumerStatefulWidget {
  final bool isGoogleAuth;
  final String phoneNumber;
  final String googleToken;

  const VerifyNumberScreen({
    super.key,
    required this.isGoogleAuth,
    required this.phoneNumber,
    required this.googleToken,
  });

  @override
  ConsumerState<VerifyNumberScreen> createState() => _VerifyNumberScreenState();
}

class _VerifyNumberScreenState extends ConsumerState<VerifyNumberScreen> {
  static const _navy = Color(0xFF061139);
  static const _muted = Color(0xFF8995AE);
  static const _blue = Color(0xFF0066FF);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.phoneNumber);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (ref.read(authIsLoadingProvider)) return;
    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showError(context, 'Please enter a valid mobile number');
      return;
    }
    FocusScope.of(context).unfocus();
    final phone = _phoneCtrl.text.trim();
    final controller = ref.read(authControllerProvider.notifier);
    void onSuccess(String otpCode) {
      if (!mounted) return;
      context.push(
        AppRouter.otpVerificationPath,
        extra: {
          'isGoogle': widget.isGoogleAuth,
          'phone': phone,
          'token': widget.isGoogleAuth ? widget.googleToken : '',
        },
      );
    }

    if (widget.isGoogleAuth) {
      await controller.requestOtpSession(
        phoneNumber: phone,
        token: widget.googleToken,
        onSuccess: onSuccess,
      );
    } else {
      await controller.sendOtp(phoneNumber: phone, onSuccess: onSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Form(
                      key: _formKey,
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
                                        context.go(AppRouter.login);
                                      }
                                    },
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _navy,
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
                          SizedBox(height: 39 * scale),
                          Text(
                            'Enter your\nmobile number',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.inter(
                              fontSize: 38 * scale,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                              height: 1.05,
                              letterSpacing: -1.5 * scale,
                            ),
                          ),
                          SizedBox(height: 17 * scale),
                          Text(
                            'We\u2019ll send you an OTP to verify\nyour number.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.inter(
                              fontSize: 17 * scale,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 33 * scale),
                          if (error != null) ...[
                            AuthErrorBanner(message: error),
                            SizedBox(height: 12 * scale),
                          ],
                          TextFormField(
                            controller: _phoneCtrl,
                            enabled: !isLoading,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.telephoneNumberNational,
                            ],
                            onFieldSubmitted: (_) => _onSendOtp(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: AppTextStyles.inter(
                              fontSize: 19 * scale,
                              fontWeight: FontWeight.w600,
                              color: _navy,
                            ),
                            decoration: InputDecoration(
                              hintText: '98765 43210',
                              hintStyle: AppTextStyles.inter(
                                fontSize: 19 * scale,
                                fontWeight: FontWeight.w600,
                                color: _muted,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 20 * scale,
                                horizontal: 16 * scale,
                              ),
                              border: _inputBorder(scale, _muted),
                              enabledBorder: _inputBorder(scale, _muted),
                              disabledBorder: _inputBorder(scale, _muted),
                              focusedBorder: _inputBorder(scale, _blue),
                              errorBorder: _inputBorder(scale, Colors.red),
                              focusedErrorBorder: _inputBorder(
                                scale,
                                Colors.red,
                              ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(
                                  left: 13 * scale,
                                  right: 16 * scale,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<String>(
                                      tooltip: 'Country code',
                                      enabled: !isLoading,
                                      initialValue: 'IN',
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'IN',
                                          child: Text('India (+91)'),
                                        ),
                                      ],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '\u{1F1EE}\u{1F1F3}',
                                            style: TextStyle(
                                              fontSize: 27 * scale,
                                            ),
                                          ),
                                          SizedBox(width: 10 * scale),
                                          Text(
                                            '+91',
                                            style: AppTextStyles.inter(
                                              fontSize: 19 * scale,
                                              fontWeight: FontWeight.w600,
                                              color: _navy,
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: _navy,
                                            size: 22 * scale,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10 * scale),
                                    Container(
                                      width: 1,
                                      height: 36 * scale,
                                      color: const Color(0xFFD7DDE7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mobile number is required';
                              }
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                return 'Enter a valid 10-digit number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 36 * scale),
                          SizedBox(
                            width: double.infinity,
                            height: 57 * scale,
                            child: FilledButton(
                              onPressed: isLoading ? null : _onSendOtp,
                              style: FilledButton.styleFrom(
                                backgroundColor: _blue,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Send OTP',
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

  OutlineInputBorder _inputBorder(double scale, Color color) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(18 * scale),
        borderSide: BorderSide(color: color, width: 1.3),
      );
}
