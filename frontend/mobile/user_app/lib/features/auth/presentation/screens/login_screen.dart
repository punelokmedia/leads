import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import '../../shared/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _assets = 'assets/Nextlead Mobile  App Asetes';
  static const _navy = Color(0xFF061139);
  static const _muted = Color(0xFF8291AF);
  static const _blue = Color(0xFF0047FF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authControllerProvider.notifier).clearError();
    });
  }

  void _onGoogleLogin() {
    ref
        .read(authControllerProvider.notifier)
        .googleAuth(
          onSuccess: (String token) {
            if (!mounted) return;
            final user = ref.read(authControllerProvider).user;
            context.go(
              user?.isProfileComplete == true
                  ? AppRouter.homePath
                  : AppRouter.tellUsAboutYourselfPath,
            );
          },
        );
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
                    '$_assets/NextLead Arrow only.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = math.min(constraints.maxWidth / 426, 1.25);
                  final height = math.max(constraints.maxHeight, 780 * scale);
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25 * scale),
                        child: Column(
                          children: [
                            SizedBox(height: 16 * scale),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: 'Back',
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go(AppRouter.onboardingPath);
                                        }
                                      },
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: _navy,
                                  size: 24 * scale,
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.045),
                            Image.asset(
                              'assets/branding/nextlead_wordmark.webp',
                              width: 248 * scale,
                              height: 86 * scale,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: height * 0.085),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Welcome back!',
                                style: AppTextStyles.inter(
                                  fontSize: 43 * scale,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5 * scale,
                                  color: _navy,
                                ),
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              'Log in to continue.',
                              style: AppTextStyles.inter(
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                              ),
                            ),
                            SizedBox(height: height * 0.065),
                            if (error != null) ...[
                              AuthErrorBanner(message: error),
                              SizedBox(height: 12 * scale),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 62 * scale,
                              child: OutlinedButton(
                                onPressed: isLoading ? null : _onGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _navy,
                                  side: const BorderSide(
                                    color: _muted,
                                    width: 1.5,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : _buttonContent(
                                        'Goggle icon.svg',
                                        'Continue with Google',
                                        _navy,
                                        scale,
                                      ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 40 * scale,
                                vertical: 17 * scale,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE0E5EE)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16 * scale,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: AppTextStyles.inter(
                                        fontSize: 15 * scale,
                                        color: _muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: Color(0xFFE0E5EE)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 62 * scale,
                              child: FilledButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.push(
                                        AppRouter.verifyNumberPath,
                                        extra: {'isGoogle': false, 'phone': ''},
                                      ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                child: _buttonContent(
                                  'Phone icon.svg',
                                  'Continue with Phone',
                                  Colors.white,
                                  scale,
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.24),
                            Text(
                              'By continuing, you agree to our',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.inter(
                                fontSize: 14 * scale,
                                color: _muted,
                                height: 1.5,
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _policyLink(
                                  'Terms & Conditions',
                                  AppRouter.termsPath,
                                  scale,
                                ),
                                Text(
                                  ' and ',
                                  style: AppTextStyles.inter(
                                    fontSize: 14 * scale,
                                    color: _muted,
                                  ),
                                ),
                                _policyLink(
                                  'Privacy Policy.',
                                  AppRouter.privacyPath,
                                  scale,
                                ),
                              ],
                            ),
                            SizedBox(height: 24 * scale),
                          ],
                        ),
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

  Widget _buttonContent(String icon, String label, Color color, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          '$_assets/$icon',
          width: 28 * scale,
          height: 28 * scale,
          colorFilter: icon == 'Phone icon.svg'
              ? ColorFilter.mode(color, BlendMode.srcIn)
              : null,
        ),
        SizedBox(width: 16 * scale),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _policyLink(String label, String route, double scale) {
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: AppTextStyles.inter(
            fontSize: 14 * scale,
            color: _muted,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
