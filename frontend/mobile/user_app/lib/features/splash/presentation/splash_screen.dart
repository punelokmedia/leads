// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      
      
      context.go(AppRouter.onboardingPath);
      return;
    }

    final authState = ref.read(authControllerProvider);

    if (authState.user != null) {
      context.go(AppRouter.homePath);
    } else {
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            bottom: 60.h,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/Images/login/city_splash.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // ── 2. Content & Loading Bar (Top Layer) ──
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo ──
                Center(
                  child: Image.asset(
                    'assets/Icons/appIcon/splash_screen.png',
                    width: 236.h,
                  ),
                ),

                const Spacer(flex: 4),

                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Container(
                      width: 180.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF38159E),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 15.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
