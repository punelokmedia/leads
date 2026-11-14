import 'package:flutter/material.dart';
import 'profile_design.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'preview_data.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter_svg/flutter_svg.dart';
import 'business_details_page.dart' show accountText;

class NextLeadProfile extends ConsumerWidget {
  final PreviewStore store;
  final VoidCallback onEdit,
      onWallet,
      onNotifications,
      onMembership,
      onSaved,
      onLeads,
      onSupport,
      onPassword,
      onPreferences,
      onTerms,
      onLogout,
      onMore;
  const NextLeadProfile({
    super.key,
    required this.store,
    required this.onEdit,
    required this.onWallet,
    required this.onNotifications,
    required this.onMembership,
    required this.onSaved,
    required this.onLeads,
    required this.onSupport,
    required this.onPassword,
    required this.onPreferences,
    required this.onTerms,
    required this.onLogout,
    required this.onMore,
  });
  static const assets = 'assets/Nextlead Mobile  App Asetes';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProfileDesign(
    store: store,
    onEdit: onEdit,
    onWallet: onWallet,
    onNotifications: onNotifications,
    onMembership: onMembership,
    onSaved: onSaved,
    onSupport: onSupport,
    onPassword: onPassword,
    onPreferences: onPreferences,
    onTerms: onTerms,
    onLogout: () => _confirmLogout(context),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x330F172A),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          constraints: const BoxConstraints(maxWidth: 330),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: const BorderSide(color: Color(0x85797C80)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/figma/logout-icon.svg',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Log out of NextLead?',
                  textAlign: TextAlign.center,
                  style: accountText(
                    20,
                    color: const Color(0xFF0F172A),
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You’ll need to sign in again to access your vendor account.',
                  textAlign: TextAlign.center,
                  style: accountText(
                    13,
                    color: const Color(0xFF52688D),
                  ).copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE57E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF0066FF),
                          size: 24,
                        ),
                        const SizedBox(width: 11),
                        const SizedBox(
                          height: 28,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Color(0xC9334155),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your account data and saved leads will remain saved.',
                            style: accountText(
                              11,
                              color: const Color(0xFF665A34),
                            ).copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                for (final logout in [true, false]) ...[
                  if (!logout) const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, logout),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, logout ? 49 : 43),
                      foregroundColor: logout
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0066FF),
                      side: BorderSide(
                        color: logout
                            ? const Color(0xFFF87171)
                            : const Color(0xFF0066FF),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: accountText(
                        15,
                        weight: logout ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    child: Text(logout ? 'Log Out' : 'Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) onLogout();
  }
}
