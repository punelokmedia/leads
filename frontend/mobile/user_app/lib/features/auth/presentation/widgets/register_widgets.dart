// features/auth/presentation/widgets/register_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';

// ── 1. Background Gradient Widget ──
class RegisterBackground extends StatelessWidget {
  final Widget child;
  const RegisterBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerLow,
            Theme.of(context).colorScheme.surfaceContainerLow,
            Color.fromARGB(255, 255, 198, 28),
          ],
          stops: [0.40, 0.70, 1.0],
        ),
      ),
      child: child,
    );
  }
}

// ── 2. Header (Logo & Titles) ──
class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Image.asset(
            'assets/Images/home/logo_leads.png',
            width: 169.w,
            height: 56.h,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Text(
              'Next Leads',
              style: AppTextStyles.poppins(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Center(
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Text(
            'Almost there, just sign up!',
            style: TextStyle(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 3. Footer (Login Link) ──
class RegisterFooter extends ConsumerWidget {
  const RegisterFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Already have an account? ',
            style: AppTextStyles.poppins(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              letterSpacing: 0.1,
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(authControllerProvider.notifier).clearError();
              context.pop();
            },
            child: Text(
              'Login',
              style: AppTextStyles.poppins(
                fontSize: 14.sp,
                color: AppColors.red237,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
