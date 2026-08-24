import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';

enum DrawerMenuItem {
  profile,
  notification,
  privacyPolicy,
  termsConditions,
  settings,
  helpSupport,
}

final activeDrawerMenuProvider = StateProvider<DrawerMenuItem>(
  (ref) => DrawerMenuItem.profile,
);

class _MenuItem {
  final DrawerMenuItem item;
  final IconData icon;
  final String label;
  final String? route;
  final bool useGo;

  const _MenuItem({
    required this.item,
    required this.icon,
    required this.label,
    this.route,
    this.useGo = false,
  });
}

class AppDrawerController {
  static OverlayEntry? _entry;

  static void open(BuildContext context) {
    if (_entry != null) return;
    final router = GoRouter.of(context);
    _entry = OverlayEntry(
      builder: (_) => _DrawerOverlay(onClose: close, router: router),
    );
    Navigator.of(context, rootNavigator: true).overlay?.insert(_entry!);
  }

  static void close() {
    _entry?.remove();
    _entry = null;
  }
}

class _DrawerOverlay extends HookConsumerWidget {
  final VoidCallback onClose;
  final GoRouter router;

  const _DrawerOverlay({required this.onClose, required this.router});

  static const _menuItems = <_MenuItem>[
    _MenuItem(
      item: DrawerMenuItem.profile,
      icon: Icons.person_outline_rounded,
      label: 'Profile Information',
      route: AppRouter.profilePath,
      useGo: true,
    ),
    _MenuItem(
      item: DrawerMenuItem.notification,
      icon: Icons.notifications_none_rounded,
      label: 'Notification',
      route: AppRouter.notificationPath,
    ),
    _MenuItem(
      item: DrawerMenuItem.privacyPolicy,
      icon: Icons.shield_outlined,
      label: 'Privacy Policy',
      route: AppRouter.privacyPath,
    ),
    _MenuItem(
      item: DrawerMenuItem.termsConditions,
      icon: Icons.people_outline_rounded,
      label: 'Terms & Conditions',
      route: AppRouter.termsPath,
    ),
    _MenuItem(
      item: DrawerMenuItem.settings,
      icon: Icons.settings_outlined,
      label: 'Settings',
      route: AppRouter.settingPath,
    ),
    _MenuItem(
      item: DrawerMenuItem.helpSupport,
      icon: Icons.help_outline_rounded,
      label: 'Help & Support',
      route: AppRouter.helpSupportPath,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeItem = ref.watch(activeDrawerMenuProvider);

    final animController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final slideAnim =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animController, curve: Curves.easeOutCubic),
        );

    final bgAnim = Tween<double>(
      begin: 0,
      end: 0.22,
    ).animate(CurvedAnimation(parent: animController, curve: Curves.easeOut));

    useEffect(() {
      animController.forward();
      return null;
    }, const []);

    void closeWithAnim() {
      animController.reverse().then((_) => onClose());
    }

    void onItemTap(_MenuItem data) {
      ref.read(activeDrawerMenuProvider.notifier).state = data.item;
      final route = data.route;
      closeWithAnim();
      if (route == null) return;
      Future.delayed(const Duration(milliseconds: 320), () {
        if (data.useGo) {
          router.go(route);
        } else {
          router.push(route);
        }
      });
    }

    void onLogout() {
      ref.read(authControllerProvider.notifier).logout();
      closeWithAnim();
      Future.delayed(const Duration(milliseconds: 320), () {
        router.go(AppRouter.login);
      });
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: bgAnim,
                builder: (_, _) => GestureDetector(
                  onTap: closeWithAnim,
                  child: Container(
                    color: Colors.black.withOpacity(bgAnim.value),
                  ),
                ),
              ),

              SlideTransition(
                position: slideAnim,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _DrawerPanel(
                    menuItems: _menuItems,
                    activeItem: activeItem,
                    onItemTap: onItemTap,
                    onClose: closeWithAnim,
                    onLogout: onLogout,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Drawer Panel
// ─────────────────────────────────────────

class _DrawerPanel extends StatelessWidget {
  final List<_MenuItem> menuItems;
  final DrawerMenuItem activeItem;
  final void Function(_MenuItem) onItemTap;
  final VoidCallback onClose;
  final VoidCallback onLogout;

  const _DrawerPanel({
    required this.menuItems,
    required this.activeItem,
    required this.onItemTap,
    required this.onClose,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Full device height — ignores SafeArea so it covers bottom nav too
    return SizedBox(
      width: 0.75.sw,
      height: MediaQuery.of(context).size.height,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          // top: true  keeps content below status bar
          // bottom: false  lets panel extend behind bottom nav
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14.h),

              // ── Hamburger close button ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                child: GestureDetector(onTap: onClose, child: _HamburgerIcon()),
              ),

              SizedBox(height: 20.h),

              // ── Menu items ──
              ...menuItems.map(
                (data) => _DrawerTile(
                  data: data,
                  isActive: activeItem == data.item,
                  onTap: () => onItemTap(data),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Divider(
                  color: Colors.grey.shade200,
                  thickness: 1,
                  height: 1,
                ),
              ),

              // ── Logout ──
              _LogoutTile(onTap: onLogout),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Hamburger Icon
// ─────────────────────────────────────────

class _HamburgerIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HamLine(width: 22.w),
        SizedBox(height: 5.h),
        _HamLine(width: 14.w),
        SizedBox(height: 5.h),
        _HamLine(width: 22.w),
      ],
    );
  }
}

class _HamLine extends StatelessWidget {
  final double width;
  const _HamLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2.h,
      decoration: BoxDecoration(
        color: AppColors.black19,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Drawer Tile
// ─────────────────────────────────────────

class _DrawerTile extends HookWidget {
  final _MenuItem data;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);

    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => isPressed.value = true,
          onTapUp: (_) {
            isPressed.value = false;
            onTap();
          },
          onTapCancel: () => isPressed.value = false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            color: isPressed.value
                ? AppColors.purple72.withOpacity(0.05)
                : Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            child: Row(
              children: [
                Icon(
                  data.icon,
                  size: 25.r,
                  color: isActive ? AppColors.purple72 : AppColors.grey94,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    data.label,
                    style: AppTextStyles.poppins(
                      fontSize: 16.sp,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.black19 : AppColors.grey77,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Logout Tile
// ─────────────────────────────────────────

class _LogoutTile extends HookWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

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
        duration: const Duration(milliseconds: 100),
        color: isPressed.value
            ? const Color(0xFFE03B3B).withOpacity(0.05)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              size: 20.r,
              color: const Color(0xFFE03B3B),
            ),
            SizedBox(width: 16.w),
            Text(
              'Logout',
              style: AppTextStyles.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE03B3B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
