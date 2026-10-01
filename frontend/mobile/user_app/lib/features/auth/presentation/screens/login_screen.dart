// auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
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
            if (user?.isProfileComplete == true) {
              context.go(AppRouter.homePath);
            } else {
              context.go(AppRouter.tellUsAboutYourselfPath);
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      // ── Background Gradient ──
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface, // Top is white
              Theme.of(context).colorScheme.surface, // Middle is white
              Color(0xFF9F75FF), // Bottom fades into light purple
            ],
            stops: [
              0.0,
              0.65,
              1.0,
            ], // Controls where the gradient starts blending
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 22.h),

                // ── Logo ──
                Image.asset(
                  'assets/Images/login/lead_logo.png',
                  width: 150.w,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.storefront_rounded,
                    size: 56.r,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 24.h),

                // ── Title ──
                Text(
                  'Welcome Back',
                  style: AppTextStyles.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    height: 20 / 24,
                    letterSpacing: 0.01,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Sign in or create your account',
                  style: AppTextStyles.poppins(
                    fontSize: 16.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    height: 20 / 16,
                    letterSpacing: 0.01,
                  ),
                ),
                SizedBox(height: 44.h),

                // ── Backend Error Banner ──
                if (error != null) ...[
                  AuthErrorBanner(message: error),
                  SizedBox(height: 16.h),
                ],

                GoogleSignInButton(onTap: _onGoogleLogin, isLoading: isLoading),
                SizedBox(height: 24.h),
                const OrDivider(text: 'Or'),
                SizedBox(height: 16.h),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => context.push(
                          AppRouter.verifyNumberPath,
                          extra: {'isGoogle': false, 'phone': ''},
                        ),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Continue with phone'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                  ),
                ),
                SizedBox(height: 32.h),
                // ── Terms & Conditions ──
                Text(
                  "By continuing, you agree to our\nTerms & Conditions and Privacy Policy",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 21 / 14,
                  ),
                ),
                SizedBox(height: 34.h),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
