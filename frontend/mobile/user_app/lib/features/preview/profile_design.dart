import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../payments/presentation/widgets/wallet_card.dart';
import 'preview_data.dart';
import 'service_categories_page.dart';
import 'location_service_area_page.dart';

const profileBackground = Color(0xFFE3EDFF);
const _ink = Color(0xFF0F172A);
const _blue = Color(0xFF0066FF);
const _navy = Color(0xFF072565);

Widget _svg(String name, double width, double height) => SvgPicture.asset(
  'assets/figma/profile-$name.svg',
  width: width,
  height: height,
);

TextStyle _text(
  double size, {
  Color color = _ink,
  FontWeight weight = FontWeight.w500,
}) => TextStyle(
  fontFamily: 'ProfileMontserrat',
  fontSize: size,
  height: 1.25,
  color: color,
  fontWeight: weight,
);

/// Native, interactive layout measured from the supplied 393 × 1294 SVG.
class ProfileDesign extends ConsumerWidget {
  final PreviewStore store;
  final VoidCallback onEdit,
      onWallet,
      onNotifications,
      onMembership,
      onSaved,
      onSupport,
      onPassword,
      onPreferences,
      onTerms,
      onLogout;
  const ProfileDesign({
    super.key,
    required this.store,
    required this.onEdit,
    required this.onWallet,
    required this.onNotifications,
    required this.onMembership,
    required this.onSaved,
    required this.onSupport,
    required this.onPassword,
    required this.onPreferences,
    required this.onTerms,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = store.isLive
        ? ref
              .watch(walletProvider)
              .when(
                data: (data) =>
                    '₹ ${((data['balancePaise'] as num? ?? 0) / 100).toStringAsFixed(0)}',
                loading: () => '…',
                error: (_, _) => 'Wallet',
              )
        : '₹ 500';
    return ColoredBox(
      color: profileBackground,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(balance),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 17, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile', style: _text(24, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your account, business details and\npreferences.',
                      style: _text(
                        12,
                        color: const Color(0xFF9498A1),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _account(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                child: _membership(),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFC5C5C5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        _row(
                          'business',
                          'Business Details',
                          'Update your company information',
                          onEdit,
                        ),
                        _row(
                          'categories',
                          'Service Categories',
                          'Manage your service categories',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ServiceCategoriesPage(store: store),
                            ),
                          ),
                        ),
                        _row(
                          'location',
                          'Location & Service Area',
                          'Set your city and service areas',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  LocationServiceAreaPage(store: store),
                            ),
                          ),
                        ),
                        _row(
                          'notifications',
                          'Notification Preferences',
                          'Manage what notifications you receive',
                          onPreferences,
                        ),
                        _row(
                          'saved',
                          'Saved',
                          'View your saved leads, categories and more',
                          onSaved,
                        ),
                        _row(
                          'password',
                          'Change Password',
                          'Update your account password',
                          onPassword,
                        ),
                        _row(
                          'support',
                          'Help & Support',
                          'Get help or contact support',
                          onSupport,
                        ),
                        _row(
                          'terms',
                          'Terms & Privacy',
                          'Read our terms and privacy policy',
                          onTerms,
                        ),
                        _row(
                          'logout',
                          'Logout',
                          'Sign out from your account',
                          onLogout,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String balance) => Container(
    height: 64,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x4294A3B8))),
      boxShadow: [
        BoxShadow(
          color: Color(0x08072565),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            left: constraints.maxWidth < 350 ? 22 : 39,
            top: 4.825,
            child: Image.asset(
              'assets/figma/profile-logo.png',
              width: 129.75,
              height: 43.35,
            ),
          ),
          Positioned(
            right: 81.25,
            top: 8.275,
            child: Material(
              color: const Color(0xFFFAFAFA),
              elevation: 2,
              shape: const StadiumBorder(
                side: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: InkWell(
                onTap: onWallet,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _svg('wallet', 24, 22),
                      const SizedBox(width: 5),
                      Text(balance, style: _text(10, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 31,
            top: 3,
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: onNotifications,
              icon: _svg('bell', 24, 26),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _account() {
    final profile = store.profile;
    final name = profile['Full name']?.trim() ?? '';
    final initials = name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((p) => p[0])
              .join()
              .toUpperCase();
    String value(String key) =>
        (profile[key] ?? '').trim().isEmpty ? 'Not provided' : profile[key]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x99DBEAFE)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    if (store.isLive)
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFD9E7FF),
                        child: Text(
                          initials,
                          style: _text(
                            23,
                            color: _navy,
                            weight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Image.asset(
                        'assets/figma/profile-sample-avatar.png',
                        width: 64,
                        height: 64,
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Semantics(
                        label: 'Edit profile photo',
                        button: true,
                        child: GestureDetector(
                          onTap: onEdit,
                          child: _svg('camera', 24, 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'Your profile' : name,
                                maxLines: 2,
                                style: _text(17, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                value('Service category'),
                                maxLines: 2,
                                style: _text(
                                  13,
                                  color: const Color(0xFF64748B),
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _pill('Edit Profile', onEdit),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!store.isLive)
                      Row(
                        children: [
                          _svg('verified', 14, 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Verified Business',
                              style: _text(
                                12,
                                color: const Color(0xFF10B981),
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        (profile['Business name'] ?? '').isEmpty
                            ? 'Business profile'
                            : profile['Business name']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          12,
                          color: const Color(0xFF10B981),
                          weight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0x80BFDBFE)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _detail('phone', value('Phone'))),
              const SizedBox(width: 12),
              Expanded(child: _detail('email', value('Email'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detail(
                  'pin',
                  [
                    profile['City'],
                    profile['State'],
                  ].whereType<String>().where((v) => v.isNotEmpty).join(', '),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _detail('category', value('Service category'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String icon, String value) => Row(
    children: [
      _svg(icon, 16, 16),
      const SizedBox(width: 8),
      Expanded(
        child: Tooltip(
          message: value,
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(
              12,
              color: const Color(0xFF334155),
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _membership() => Container(
    constraints: const BoxConstraints(minHeight: 74),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE57E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDBEAFE)),
    ),
    child: Row(
      children: [
        _svg('crown', 44, 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.isProMember || !store.isLive ? 'Pro Plan' : 'Membership',
                style: _text(15, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                !store.isLive
                    ? 'Valid till 12 Dec 2026'
                    : store.isProMember
                    ? 'Lifetime membership'
                    : 'Explore membership plans',
                style: _text(12, weight: FontWeight.w400),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        _pill('Manage Plan', onMembership),
      ],
    ),
  );

  Widget _pill(String label, VoidCallback action) => OutlinedButton(
    onPressed: action,
    style: OutlinedButton.styleFrom(
      foregroundColor: _blue,
      minimumSize: const Size(0, 30),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: const StadiumBorder(),
      side: const BorderSide(color: _blue),
      textStyle: _text(12, color: _blue, weight: FontWeight.w600),
    ),
    child: Text(label),
  );

  Widget _row(
    String icon,
    String title,
    String subtitle,
    VoidCallback action, {
    bool last = false,
  }) => Column(
    children: [
      InkWell(
        onTap: action,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _svg(icon, 40, 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: _text(
                              14,
                              color: last ? const Color(0xFFEF4444) : _ink,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: _text(
                              10.5,
                              color: const Color(0xFF94A3B8),
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(right: 18, child: _svg('chevron', 9, 13)),
            ],
          ),
        ),
      ),
      if (!last)
        const Divider(height: 1, thickness: 1, color: Color(0xFFC5C5C5)),
    ],
  );
}

/// Profile's compact navigation uses the original curved surface and icons.
class ProfileBottomNav extends StatelessWidget {
  final ValueChanged<int> onSelect;
  final int selected;
  const ProfileBottomNav({
    super.key,
    required this.onSelect,
    this.selected = 4,
  });
  static const labels = ['Home', 'My Leads', 'Cart', 'Membership', 'Profile'];
  static const icons = ['home', 'leads', 'cart', 'membership', 'profile'];
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: profileBackground,
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: Container(
          height: 134,
          constraints: const BoxConstraints(maxWidth: 726),
          margin: const EdgeInsets.fromLTRB(17, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: _navy,
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final slot = (bounds.maxWidth - 20) / 5;
                  final center = selected >= 0 && selected < 5
                      ? 10 + slot * (selected + .5)
                      : -1.0;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _BottomNavSurface(center)),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 0,
                        bottom: 24,
                        child: Row(
                          children: List.generate(
                            5,
                            (i) => Expanded(
                              child: Semantics(
                                button: true,
                                selected: i == selected,
                                label: labels[i],
                                child: InkWell(
                                  onTap: () => onSelect(i),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Positioned(
                                        top: i == selected ? 10 : 58,
                                        child: i == selected
                                            ? Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: _blue,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 4,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: SvgPicture.asset(
                                                    'assets/figma/profile-nav-${icons[i]}.svg',
                                                    width: 25,
                                                    height: 24,
                                                    colorFilter:
                                                        const ColorFilter.mode(
                                                          Colors.white,
                                                          BlendMode.srcIn,
                                                        ),
                                                  ),
                                                ),
                                              )
                                            : _svg('nav-${icons[i]}', 25, 24),
                                      ),
                                      Positioned(
                                        top: i == selected ? 88 : 86,
                                        left: 0,
                                        right: 0,
                                        child: ExcludeSemantics(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              labels[i],
                                              maxLines: 1,
                                              style: _text(
                                                12,
                                                color: i == selected
                                                    ? _blue
                                                    : _ink,
                                                weight: i == selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 11,
                        child: Center(
                          child: ColoredBox(
                            color: _navy,
                            child: SizedBox(width: 135, height: 1),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BottomNavSurface extends CustomPainter {
  final double center;
  const _BottomNavSurface(this.center);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, 42);
    if (center >= 0) {
      path
        ..lineTo(center - 43, 42)
        ..cubicTo(center - 32, 42, center - 32, 82, center, 82)
        ..cubicTo(center + 32, 82, center + 32, 42, center + 43, 42);
    }
    path
      ..lineTo(size.width, 42)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BottomNavSurface oldDelegate) =>
      oldDelegate.center != center;
}
