import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/profile/domain/profile_model.dart';
import 'package:user_app/features/profile/presentation/widgets/logout_bottom_sheet.dart';
import 'package:user_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:user_app/features/profile/presentation/widgets/profile_menu_tile.dart';
import 'package:user_app/features/profile/presentation/widgets/profile_shimmer.dart';
import 'package:user_app/features/profile/presentation/widgets/profile_signin_header.dart';
import 'package:user_app/features/profile/shared/profile_providers.dart';
// Assuming you have an auth provider that checks secure storage
// import 'package:user_app/features/auth/shared/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (isLoggedIn) {
      // Use Future.microtask to avoid state update during build
      Future.microtask(
        () => ref.read(profileControllerProvider.notifier).loadProfile(),
      );
    }
  }

  void _onLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Allows custom rounded corners
      isScrollControlled: true,
      builder: (_) => LogoutBottomSheet(
        onConfirm: () async {
          // 1. Close the bottom sheet first
          context.pop();

          // 2. Perform the logout logic
          await ref.read(authControllerProvider.notifier).logout();

          // 3. Optional: Clear specific profile data
          ref.invalidate(profileDataProvider);

          // 4. Navigate back to login
          context.go(AppRouter.login);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check Auth State (fetched from Secure Storage via provider)
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final profileState = ref.watch(profileControllerProvider);
    
    final isLoading = profileState.isLoading;
    final profile = profileState.profile;
    final isLoggingOut = profileState.isLoggingOut;

    if (isLoggedIn && profile == null && !isLoading && profileState.errorMessage == null) {
      Future.microtask(() => ref.read(profileControllerProvider.notifier).loadProfile());
    }
    

    return Scaffold(
      backgroundColor: AppColors.grey241,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isLoggedIn && profile != null) ...[
              ProfileHeader(
                profile: profile,
                onEditProfile: () async {
                  await context.push(AppRouter.editProfilePath);
                  if (mounted) {
                    ref.read(profileControllerProvider.notifier).loadProfile();
                  }
                },
              ),
            ] else if (!isLoggedIn) ...[
              const ProfileSignInHeader(),
            ] else if (isLoading) ...[
              const ProfileHeaderShimmer(),
            ],

            SizedBox(height: 30.h),

            // Common Menu Items
            ProfileMenuTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {
                context.push(AppRouter.helpSupportPath);
              },
            ),
            ProfileMenuTile(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () {
                context.push(AppRouter.termsPath);
              },
            ),

            // 3. Conditional Logout/Sign-In Tile
            ProfileLogoutTile(
              onTap: _onLogout,
              isLoading: isLoggingOut,
              isEnabled: isLoggedIn, // Use your provider's state here
            ),

            SizedBox(height: 40.h),

            // Illustration at the bottom (conditional based on Figma)
            Center(
              child: Image.asset(
                isLoggedIn
                    ? 'assets/Images/profile/profile_illustration.png'
                    : 'assets/Images/profile/no_account_illustration.png',
                height: 180.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
