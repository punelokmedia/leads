import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/network/session_events.dart';
import '../features/auth/shared/auth_providers.dart';
import '../features/profile/infra/profile_repository.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_theme.dart';

class UserApp extends ConsumerWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionExpiredProvider, (previous, next) {
      ref.read(isLoggedInProvider.notifier).markSessionExpired();
      ref.invalidate(authControllerProvider);
      ref.invalidate(profileControllerProvider);
      AppRouter.router.go(AppRouter.login);
    });
    return ScreenUtilPlusInit(
      designSize: const Size(412, 917),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp.router(
        title: 'Leads Sell',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppTheme.mode,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
