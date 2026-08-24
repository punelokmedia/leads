import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/features/address/presentation/screens/add_address_screen.dart';
import 'package:user_app/features/auth/presentation/screens/complete_payment_screen.dart';
import 'package:user_app/features/auth/presentation/screens/login_screen.dart';
import 'package:user_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:user_app/features/auth/presentation/screens/register_screen.dart';
import 'package:user_app/features/auth/presentation/screens/choose_city_screen.dart';
import 'package:user_app/features/auth/presentation/screens/choose_category_screen.dart';
import 'package:user_app/features/auth/presentation/screens/tell_us_about_yourself_screen.dart';
import 'package:user_app/features/auth/presentation/screens/verify_number_screen.dart';
import 'package:user_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:user_app/features/cart/presentation/screens/payment_successful.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/home/presentation/screens/home_screen.dart';
import 'package:user_app/features/home/presentation/screens/lead.dart';
import 'package:user_app/features/home/presentation/screens/lead_details_screen.dart';
import 'package:user_app/features/splash/presentation/splash_screen.dart';
import 'package:user_app/features/support/presentation/screens/setting.dart';
import 'package:user_app/features/payments/presentation/screens/paymets.dart';
import 'package:user_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:user_app/features/profile/presentation/screens/edit_profile_screen.dart';

import 'package:user_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:user_app/features/shell/presentation/main_shell.dart';
import 'package:user_app/features/splash/presentation/onboarding_screen.dart';
import 'package:user_app/features/support/presentation/screens/about_us_page.dart';
import 'package:user_app/features/support/presentation/screens/help_support_screen.dart';
import 'package:user_app/features/support/presentation/screens/notifications_page.dart';
import 'package:user_app/features/support/presentation/screens/privacy_policy_screen.dart';
import 'package:user_app/features/support/presentation/screens/terms_conditions_screen.dart';

abstract final class AppRouter {
  static const String splashPath = '/';
  static const String onboardingPath = '/onboarding';
  static const login = '/login';
  static const String verifyNumberPath = '/verify-number';
  static const register = '/register';
  static const String tellUsAboutYourselfPath = '/tell-us-about-yourself';
  static const String completePaymentPath = '/complete-payment';
  static const String homePath = '/home';
  static const String drawerPath = '/drawer';
  static const String settingPath = '/setting';
  static const String leadsPath = '/history';
  static const String chooseWorkCityPath = '/choose-work-city';
  static const String chooseCategoryPath = '/choose-category';
  static const String profilePath = '/profile';
  static const String paymentsPath = '/payments';
  static const String leadDetailsPath = '/lead-details';

  static const String changePasswordPath = '/change-password';
  static const String editProfilePath = '/edit-profile';
  static const String addAddressPath = '/add-address';
  static const String cartPath = '/cart-Screen';
  static const String paymentsuccessPath = '/pay-success';

  static const String termsPath = '/terms-conditions';
  static const String helpSupportPath = '/help-support';
  static const String aboutusPath = '/aboutus';
  static const String notificationPath = '/notification';
  static const String privacyPath = '/privacy-policy';
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

      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: verifyNumberPath,
        builder: (context, state) {
          final extraData = state.extra as Map<String, dynamic>? ?? {};

          final isGoogle = extraData['isGoogle'] as bool? ?? false;
          final phoneString = extraData['phone'] as String? ?? '';
          final tokenString = extraData['token'] as String? ?? '';

          return VerifyNumberScreen(
            isGoogleAuth: isGoogle,
            phoneNumber: phoneString,
            googleToken: tokenString,
          );
        },
      ),

      GoRoute(
        path: otpVerificationPath,
        builder: (context, state) {
          bool isGoogle = false;
          String phoneString = '';
          String tokenString = '';

          if (state.extra is Map) {
            final extraData = state.extra as Map;
            isGoogle = extraData['isGoogle'] as bool? ?? false;
            phoneString = extraData['phone'] as String? ?? '';
            tokenString = extraData['token'] as String? ?? '';
          } else if (state.extra is String) {
            phoneString = state.extra as String;
          }

          return OtpVerificationScreen(
            phoneNumber: phoneString,
            isGoogleAuth: isGoogle,
            googleToken: tokenString,
          );
        },
      ),
      GoRoute(
        path: AppRouter.leadDetailsPath,
        builder: (context, state) {
          // ✅ Extract the lead object from the extra parameter
          final lead = state.extra as LeadModel;
          return LeadDetailsScreen(lead: lead);
        },
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
        path: chooseWorkCityPath,
        builder: (context, state) => const ChooseWorkCityScreen(),
      ),
      GoRoute(
        path: chooseCategoryPath,
        builder: (context, state) => const ChooseCategoryScreen(),
      ),
      GoRoute(
        path: completePaymentPath,
        builder: (context, state) => const CompletePaymentScreen(),
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
        path: notificationPath,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: privacyPath,
        builder: (context, state) => const PrivacyPolicyScreen(),
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
      GoRoute(
        path: aboutusPath,
        builder: (context, state) => const AboutUsPage(),
      ),
      GoRoute(
        path: settingPath, // no leading slash — relative to /home
        builder: (context, state) => const SettingsPage(),
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
                path: leadsPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const LeadsScreen(),
              ),
            ],
          ),
          // StatefulShellBranch(
          //   routes: <RouteBase>[
          //     GoRoute(
          //       path: selectCityPath,
          //       builder: (BuildContext context, GoRouterState state) =>
          //           const _city(),
          //     ),
          //   ],
          // ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: paymentsPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const PaymentsScreen(),
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
