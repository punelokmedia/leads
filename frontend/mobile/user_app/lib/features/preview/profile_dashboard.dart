import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../payments/presentation/widgets/wallet_card.dart';
import 'preview_data.dart';
import 'home_dashboard.dart';

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
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = store.profile;
    final name = profile['Full name']?.trim() ?? '';
    final initials = name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();
    final joined = store.leads.where((lead) => lead.joined).length;
    final saved = store.leads.where((lead) => lead.saved).length;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        children: [
          Row(
            children: [
              Image.asset(
                'assets/branding/nextlead_wordmark.webp',
                width: 146,
                height: 47,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onWallet,
                icon: _asset('Wallet Icon.svg', 19),
                label: Text(
                  store.isLive
                      ? ref
                            .watch(walletProvider)
                            .when(
                              data: (data) =>
                                  '\u20b9 ${((data['balancePaise'] as num? ?? 0) / 100).toStringAsFixed(0)}',
                              loading: () => '...',
                              error: (_, _) => 'Wallet',
                            )
                      : 'Wallet',
                  style: const TextStyle(color: homeNavy),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDCE6F8)),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotifications,
                icon: Badge(
                  isLabelVisible: store.unread,
                  child: _asset('notifications_icon.svg', 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 27,
              color: homeNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Manage your account, business details and preferences.',
            style: TextStyle(fontSize: 12, color: homeMuted),
          ),
          const SizedBox(height: 16),
          _panel(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Color(0xFFEEF5FF)],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 31,
                        backgroundColor: const Color(0xFFD9E7FF),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: homeNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Your profile' : name,
                              style: const TextStyle(
                                color: homeNavy,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              profile['Service category'] ?? '',
                              style: const TextStyle(
                                color: homeMuted,
                                fontSize: 13,
                              ),
                            ),
                            if ((profile['Business name'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  profile['Business name']!,
                                  style: const TextStyle(
                                    color: homeMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: homeBlue,
                          side: const BorderSide(color: homeBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: LayoutBuilder(
                    builder: (context, size) {
                      final details = [
                        (Icons.phone_outlined, profile['Phone'] ?? ''),
                        (Icons.mail_outline, profile['Email'] ?? ''),
                        (
                          Icons.location_on_outlined,
                          [profile['City'], profile['State']]
                              .where(
                                (value) => value != null && value.isNotEmpty,
                              )
                              .join(', '),
                        ),
                        (
                          Icons.business_center_outlined,
                          profile['Service category'] ?? '',
                        ),
                      ];
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: details
                            .map(
                              (item) => SizedBox(
                                width: size.maxWidth < 340
                                    ? size.maxWidth
                                    : (size.maxWidth - 12) / 2,
                                child: Row(
                                  children: [
                                    Icon(item.$1, size: 20, color: homeNavy),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        item.$2.isEmpty
                                            ? 'Not provided'
                                            : item.$2,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: homeNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          _panel(
            color: const Color(0xFFF0F5FF),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF1D3),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFF2AA00),
                ),
              ),
              title: const Text(
                'Membership',
                style: TextStyle(color: homeNavy, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'View your membership options',
                style: TextStyle(color: homeMuted, fontSize: 12),
              ),
              trailing: OutlinedButton(
                onPressed: onMembership,
                child: const Text(
                  'Manage Plan',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _panel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _stat(
                    Icons.description_outlined,
                    '$joined',
                    'My Leads',
                    homeBlue,
                    onLeads,
                  ),
                  _stat(
                    Icons.bookmark_outline,
                    '$saved',
                    'Saved',
                    const Color(0xFF8460EB),
                    onSaved,
                  ),
                  _stat(
                    Icons.category_outlined,
                    '${store.categories.length}',
                    'Categories',
                    const Color(0xFF00AD66),
                    onMore,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          _panel(
            child: Column(
              children: [
                _row(
                  Icons.business_outlined,
                  'Business Details',
                  'Update your company information',
                  onEdit,
                ),
                _row(
                  Icons.grid_view_rounded,
                  'Service Categories',
                  'Manage your service categories',
                  onEdit,
                ),
                _row(
                  Icons.location_on_outlined,
                  'Location & Service Area',
                  'Set your city and service areas',
                  onEdit,
                ),
                _row(
                  Icons.notifications_none,
                  'Notification Preferences',
                  'Manage what notifications you receive',
                  onPreferences,
                ),
                _row(
                  Icons.bookmark_border,
                  'Saved',
                  'View your saved leads, categories and more',
                  onSaved,
                  color: const Color(0xFFFF4E60),
                ),
                _row(
                  Icons.lock_outline,
                  'Change Password',
                  'Update your account password',
                  onPassword,
                ),
                _row(
                  Icons.help_outline,
                  'Help & Support',
                  'Get help or contact support',
                  onSupport,
                ),
                _row(
                  Icons.description_outlined,
                  'Terms & Privacy',
                  'Read our terms and privacy policy',
                  onTerms,
                  divider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          _panel(
            child: _row(
              Icons.logout,
              'Logout',
              'Sign out from your account',
              () => _confirmLogout(context),
              color: const Color(0xFFFF4E60),
              divider: false,
            ),
          ),
          TextButton(
            onPressed: onMore,
            child: const Text('More options · Referrals & wallet'),
          ),
        ],
      ),
    );
  }

  Widget _asset(String file, double size) =>
      SvgPicture.asset('$assets/$file', width: size, height: size);

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x990A1832),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 36, 26, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFFFE8EC),
                child: Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF3038),
                  size: 48,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Log out of NextLead?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: homeNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You’ll need to sign in again to access your vendor account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: homeMuted, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: homeBlue,
                      size: 32,
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'Your account data and saved leads will remain saved.',
                        style: TextStyle(
                          color: homeNavy,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3038),
                    side: const BorderSide(
                      color: Color(0xFFFF4C55),
                      width: 1.4,
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: homeBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) onLogout();
  }

  Widget _panel({required Widget child, Color color = Colors.white}) =>
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFFE6EDF9)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: child,
      );
  Widget _stat(
    IconData icon,
    String value,
    String label,
    Color color,
    VoidCallback action,
  ) => Expanded(
    child: InkWell(
      onTap: action,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    color: homeNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: homeMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _row(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action, {
    Color color = homeNavy,
    bool divider = true,
  }) => Column(
    children: [
      ListTile(
        onTap: action,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        leading: CircleAvatar(
          radius: 19,
          backgroundColor: color == homeNavy
              ? const Color(0xFFEEF4FF)
              : color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: homeNavy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: homeMuted, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right, color: homeMuted, size: 20),
      ),
      if (divider)
        const Padding(
          padding: EdgeInsets.only(left: 62),
          child: Divider(height: 1, color: Color(0xFFE6EDF9)),
        ),
    ],
  );
}
