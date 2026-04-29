import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/features/address/presentation/screens/add_address_screen.dart';
import 'package:user_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:user_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:user_app/features/auth/presentation/screens/login_screen.dart';
import 'package:user_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:user_app/features/auth/presentation/screens/register_screen.dart';
import 'package:user_app/features/auth/presentation/screens/tell_us_about_yourself_screen.dart';
import 'package:user_app/features/auth/presentation/screens/verify_number_screen.dart';
import 'package:user_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:user_app/features/cart/presentation/screens/payment_successful.dart';
import 'package:user_app/features/history/presentation/history_screen.dart';
import 'package:user_app/features/home/presentation/screens/home_screen.dart';
import 'package:user_app/features/home/presentation/screens/select_category_screen.dart';
import 'package:user_app/features/home/presentation/screens/select_city_screen.dart';
import 'package:user_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:user_app/features/profile/presentation/screens/edit_profile_screen.dart';

import 'package:user_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:user_app/features/shell/presentation/main_shell.dart';
import 'package:user_app/features/splash/presentation/onboarding_screen.dart';
import 'package:user_app/features/splash/presentation/splash_screen.dart';
import 'package:user_app/features/support/presentation/screens/help_support_screen.dart';
import 'package:user_app/features/support/presentation/screens/terms_conditions_screen.dart';

abstract final class AppRouter {
  static const String splashPath = '/';
  static const String onboardingPath = '/onboarding';
  static const login = '/login';
  static const String verifyNumberPath = '/verify-number';
  static const register = '/register';
  static const String tellUsAboutYourselfPath = '/tell-us-about-yourself';
  static const String homePath = '/home';
  static const String leadsPath = '/history';
  static const String profilePath = '/profile';
  static const String changePasswordPath = '/change-password';
  static const String editProfilePath = '/edit-profile';
  static const String addAddressPath = '/add-address';
  static const String cartPath = '/cart-Screen';
  static const String paymentsuccessPath = '/pay-success';
  static const String termsPath = '/terms-conditions';
  static const String helpSupportPath = '/help-support';
  static const String selectCategoryPath = '/select-category';
  static const String selectCityPath = '/select-city';
  static const String forgotPasswordPath = '/forgot-password';
  static const String otpVerificationPath = '/otp-verification';
  static const String forgotChangePasswordPath = '/forgot-change-password';

  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    routes: [
      GoRoute(
        path: splashPath,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: onboardingPath,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: verifyNumberPath,
        builder: (context, state) {
          final phoneString = state.extra as String? ?? '';
          return VerifyNumberScreen(phoneNumber: phoneString);
        },
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: tellUsAboutYourselfPath,
        builder: (context, state) => const TellUsAboutYourselfScreen(),
      ),
      GoRoute(
        path: changePasswordPath,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: otpVerificationPath,
        builder: (context, state) {
          final phoneString = state.extra as String? ?? '';
          return OtpVerificationScreen(phoneNumber: phoneString);
        },
      ),
      GoRoute(
        path: editProfilePath,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: addAddressPath,
        builder: (context, state) => const AddAddressScreen(),
      ),
      GoRoute(
        path: forgotChangePasswordPath,
        builder: (context, state) => const ForgotChangePasswordScreen(),
      ),
      GoRoute(path: cartPath, builder: (context, state) => const CartScreen()),
      GoRoute(
        path: paymentsuccessPath,
        builder: (context, state) {
          final orderId = state.extra as String?;
          return PaymentSuccessScreen(orderId: orderId ?? 'N/A');
        },
      ),
      GoRoute(
        path: termsPath,
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: helpSupportPath,
        builder: (context, state) => const HelpSupportScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return MainShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: homePath,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: selectCategoryPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const SelectCategoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: selectCityPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const SelectCityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: leadsPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: profilePath,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
