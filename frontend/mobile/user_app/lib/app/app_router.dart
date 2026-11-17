import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_page_transition.dart';
import 'package:user_app/features/auth/presentation/screens/account_created_screen.dart';
import 'package:user_app/features/address/presentation/screens/add_address_screen.dart';
import 'package:user_app/features/auth/presentation/screens/login_screen.dart';
import 'package:user_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:user_app/features/auth/presentation/screens/choose_city_screen.dart';
import 'package:user_app/features/auth/presentation/screens/choose_category_screen.dart';
import 'package:user_app/features/auth/presentation/screens/tell_us_about_yourself_screen.dart';
import 'package:user_app/features/auth/presentation/screens/verify_number_screen.dart';
import 'package:user_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:user_app/features/cart/presentation/screens/payment_successful.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/preview/live_home.dart';
import 'package:user_app/features/home/presentation/screens/lead_details_screen.dart';
import 'package:user_app/features/splash/presentation/splash_screen.dart';
import 'package:user_app/features/support/presentation/screens/setting.dart';
import 'package:user_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:user_app/features/profile/presentation/screens/edit_profile_screen.dart';

import 'package:user_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:user_app/features/splash/presentation/onboarding_screen.dart';
import 'package:user_app/features/support/presentation/screens/about_us_page.dart';
import 'package:user_app/features/support/presentation/screens/help_support_screen.dart';
import 'package:user_app/features/support/presentation/screens/notifications_page.dart';
import 'package:user_app/features/support/presentation/screens/privacy_policy_screen.dart';
import 'package:user_app/features/support/presentation/screens/terms_conditions_screen.dart';

abstract final class AppRouter {
  static GoRoute _route({
    required String path,
    required Widget Function(BuildContext, GoRouterState) builder,
  }) => GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      transitionsBuilder: AppPageTransitionsBuilder.transition,
      child: builder(context, state),
    ),
  );
  static const String splashPath = '/';
  static const String onboardingPath = '/onboarding';
  static const login = '/login';
  static const String accountCreatedPath = '/account-created';
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
  static const String membershipPath = '/membership';
  static const String paymentsPath = '/payments';
  static const String leadDetailsPath = '/lead-details';

  static const String changePasswordPath = '/change-password';
  static const String editProfilePath = '/edit-profile';
  static const String addAddressPath = '/add-address';
  static const String cartPath = '/cart-Screen';
  static const primaryTabPaths = [
    homePath,
    leadsPath,
    cartPath,
    membershipPath,
    profilePath,
  ];
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
      _route(
        path: splashPath,
        builder: (context, state) => const SplashScreen(),
      ),

      _route(
        path: onboardingPath,
        builder: (context, state) => const OnboardingScreen(),
      ),

      _route(path: login, builder: (context, state) => const LoginScreen()),
      _route(
        path: accountCreatedPath,
        builder: (context, state) => const AccountCreatedScreen(),
      ),
      _route(path: register, builder: (context, state) => const LoginScreen()),
      _route(
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

      _route(
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
      _route(
        path: AppRouter.leadDetailsPath,
        builder: (context, state) {
          // ✅ Extract the lead object from the extra parameter
          final lead = state.extra as LeadModel;
          return LeadDetailsScreen(lead: lead);
        },
      ),
      _route(
        path: tellUsAboutYourselfPath,
        builder: (context, state) => const TellUsAboutYourselfScreen(),
      ),
      _route(
        path: changePasswordPath,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      _route(
        path: chooseWorkCityPath,
        builder: (context, state) => const ChooseWorkCityScreen(),
      ),
      _route(
        path: chooseCategoryPath,
        builder: (context, state) => const ChooseCategoryScreen(),
      ),
      _route(
        path: completePaymentPath,
        builder: (context, state) => const LiveHome(initialPage: 4),
      ),
      _route(
        path: membershipPath,
        builder: (context, state) => const LiveHome(initialPage: 4),
      ),

      _route(
        path: editProfilePath,
        builder: (context, state) => const EditProfileScreen(),
      ),
      _route(
        path: addAddressPath,
        builder: (context, state) => const AddAddressScreen(),
      ),
      _route(
        path: notificationPath,
        builder: (context, state) => const NotificationScreen(),
      ),
      _route(
        path: privacyPath,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      _route(path: cartPath, builder: (context, state) => const CartScreen()),
      _route(
        path: paymentsuccessPath,
        builder: (context, state) {
          final orderId = state.extra as String?;
          return PaymentSuccessScreen(orderId: orderId ?? 'N/A');
        },
      ),
      _route(
        path: termsPath,
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      _route(
        path: helpSupportPath,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      _route(
        path: aboutusPath,
        builder: (context, state) => const AboutUsPage(),
      ),
      _route(
        path: settingPath, // no leading slash — relative to /home
        builder: (context, state) => const SettingsPage(),
      ),

      _route(
        path: '/account',
        builder: (context, state) => const ProfileScreen(),
      ),
      _route(path: homePath, builder: (context, state) => const LiveHome()),
      _route(
        path: leadsPath,
        builder: (context, state) => const LiveHome(initialPage: 1),
      ),
      _route(
        path: paymentsPath,
        builder: (context, state) => const LiveHome(initialPage: 2),
      ),
      _route(
        path: profilePath,
        builder: (context, state) => const LiveHome(initialPage: 3),
      ),
    ],
  );
}
