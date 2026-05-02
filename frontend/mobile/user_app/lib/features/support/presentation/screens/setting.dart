import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/app/app_router.dart';

// ─────────────────────────────────────────
// Providers
// ─────────────────────────────────────────

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsState {
  final bool notificationsEnabled;
  final String userName;
  final String userEmail;

  const SettingsState({
    this.notificationsEnabled = true,
    this.userName = 'John Doe',
    this.userEmail = 'john.doe@example.com',
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    String? userName,
    String? userEmail,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }
}

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final scrollController = useScrollController();

    // Animation controller for illustration fade-in
    final animController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    final fadeAnim = useAnimation(
      CurvedAnimation(parent: animController, curve: Curves.easeOut),
    );

    useEffect(() {
      animController.forward();
      return null;
    }, []);

    const primaryColor = Color(0xFF6B5FE4);
    const backgroundColor = Color(0xFFF4F3FB);
    const cardColor = Colors.white;
    const textDark = Color(0xFF1A1A2E);
    const textLight = Color(0xFF9E9EB8);
    const dividerColor = Color(0xFFF0EFFE);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            _AppBar(primaryColor: primaryColor, textDark: textDark),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // ── General Section ──
                    _SectionLabel(label: 'General', textLight: textLight),
                    SizedBox(height: 10.h),
                    _SettingsCard(
                      cardColor: cardColor,
                      dividerColor: dividerColor,
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About App',
                          primaryColor: primaryColor,
                          onTap: () {
                            context.push(
                              AppRouter.aboutusPath,
                            ); // ✅ use push, not goNamed
                          },
                        ),
                        _Divider(color: dividerColor),
                        _SettingsTile(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notification Settings',
                          primaryColor: primaryColor,
                          trailing: Switch.adaptive(
                            value: settings.notificationsEnabled,
                            onChanged: (val) => ref
                                .read(settingsProvider.notifier)
                                .toggleNotifications(val),
                            activeColor: primaryColor,
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // ── Support Section ──
                    SizedBox(height: 32.h),
                    IllustrationSection(),

                    // ── Illustration ──
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final Color primaryColor;
  final Color textDark;

  const _AppBar({required this.primaryColor, required this.textDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: textDark,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          SizedBox(width: 38.w), // Balance the back button
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textLight;

  const _SectionLabel({required this.label, required this.textLight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Settings Card
// ─────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final Color cardColor;
  final Color dividerColor;
  final List<Widget> children;

  const _SettingsCard({
    required this.cardColor,
    required this.dividerColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────
// Settings Tile
// ─────────────────────────────────────────

class _SettingsTile extends HookWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.primaryColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) {
        isPressed.value = false;
        onTap();
      },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: isPressed.value
            ? primaryColor.withOpacity(0.04)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: primaryColor, size: 18.sp),
            ),
            SizedBox(width: 14.w),

            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: -0.1,
                ),
              ),
            ),

            // Trailing widget or chevron
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFFBEBED8),
                  size: 20.sp,
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Divider
// ─────────────────────────────────────────

class _Divider extends StatelessWidget {
  final Color color;

  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66.w,
      endIndent: 0,
      color: color,
    );
  }
}

class IllustrationSection extends HookConsumerWidget {
  const IllustrationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Image.asset(
        'assets/Images/home/setting.png',
        width: 363.w,
        height: 307.h,
        fit: BoxFit.contain,
      ),
    );
  }
}
