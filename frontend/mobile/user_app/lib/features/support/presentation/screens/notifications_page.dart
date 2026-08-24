import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

// ─────────────────────────────────────────
// Models
// ─────────────────────────────────────────

enum NotificationType { newLead, leadAccepted, payment }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}

// ─────────────────────────────────────────
// State & Provider
// ─────────────────────────────────────────

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier()
    : super([
        const NotificationItem(
          id: '1',
          type: NotificationType.newLead,
          title: 'New Lead Available',
          subtitle: 'Interior Design Project at Mumbai',
          time: '10:30 AM',
        ),
        const NotificationItem(
          id: '2',
          type: NotificationType.leadAccepted,
          title: 'Lead Accepted',
          subtitle: 'You have accepted a new lead',
          time: 'Wednesday',
          isRead: true,
        ),
        const NotificationItem(
          id: '3',
          type: NotificationType.payment,
          title: 'Payment Successful',
          subtitle: '₹400 payment successful',
          time: '20 May',
          isRead: true,
        ),
      ]);

  void markAsRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>(
      (ref) => NotificationNotifier(),
    );

// ─────────────────────────────────────────
// Notification Screen
// ─────────────────────────────────────────

class NotificationScreen extends HookConsumerWidget {
  const NotificationScreen({super.key});

  static const Color _bg = Color(0xFFF4F3FB);
  static const Color _purple = Color(0xFF6B5FE4);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textSub = Color(0xFF9E9EB8);
  static const Color _divider = Color(0xFFEAE8F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    // Stagger animation
    final animController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    useEffect(() {
      animController.forward();
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              purple: _purple,
              textDark: _textDark,
              onMarkAll: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? _EmptyState(purple: _purple, textSub: _textSub)
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: _divider, height: 1, thickness: 1),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final delay = index * 0.12;

                        return AnimatedBuilder(
                          animation: animController,
                          builder: (context, child) {
                            final progress =
                                ((animController.value - delay).clamp(
                                  0.0,
                                  1.0,
                                ) /
                                (1.0 - delay).clamp(0.01, 1.0));
                            final curve = Curves.easeOutCubic.transform(
                              progress,
                            );
                            return Opacity(
                              opacity: curve,
                              child: Transform.translate(
                                offset: Offset(0, (1 - curve) * 24),
                                child: child,
                              ),
                            );
                          },
                          child: _NotificationTile(
                            item: item,
                            purple: _purple,
                            textDark: _textDark,
                            textSub: _textSub,
                            onTap: () => ref
                                .read(notificationProvider.notifier)
                                .markAsRead(item.id),
                            onDismiss: () => ref
                                .read(notificationProvider.notifier)
                                .deleteNotification(item.id),
                          ),
                        );
                      },
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
  final Color purple;
  final Color textDark;
  final VoidCallback onMarkAll;

  const _AppBar({
    required this.purple,
    required this.textDark,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (context.canPop()) context.pop();
            },
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.sp,
              color: textDark,
            ),
          ),

          // Title
          Expanded(
            child: Center(
              child: Text(
                'Notification',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // Placeholder to balance title
          SizedBox(width: 20.w),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Notification Tile
// ─────────────────────────────────────────

class _NotificationTile extends HookWidget {
  final NotificationItem item;
  final Color purple;
  final Color textDark;
  final Color textSub;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.item,
    required this.purple,
    required this.textDark,
    required this.textSub,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: const Color(0xFFFF5C5C).withOpacity(0.1),
        child: Icon(
          Icons.delete_outline_rounded,
          color: const Color(0xFFFF5C5C),
          size: 22.sp,
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) {
          isPressed.value = false;
          onTap();
        },
        onTapCancel: () => isPressed.value = false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: isPressed.value
              ? purple.withOpacity(0.04)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              _NotificationIcon(type: item.type),
              SizedBox(width: 14.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: textDark,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: textSub,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: purple.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Unread dot
              if (!item.isRead) ...[
                SizedBox(width: 8.w),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: purple,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Notification Icon
// ─────────────────────────────────────────

class _NotificationIcon extends StatelessWidget {
  final NotificationType type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 46.w, height: 46.w, child: _buildIcon());
  }

  Widget _buildIcon() {
    switch (type) {
      case NotificationType.newLead:
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3DC),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.notifications_rounded,
              color: const Color(0xFFFFC107),
              size: 22.sp,
            ),
          ),
        );

      case NotificationType.leadAccepted:
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFDCF5E8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.group_rounded,
              color: const Color(0xFF34A853),
              size: 22.sp,
            ),
          ),
        );

      case NotificationType.payment:
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFDCEBFF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.credit_card_rounded,
              color: const Color(0xFF4285F4),
              size: 20.sp,
            ),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color purple;
  final Color textSub;

  const _EmptyState({required this.purple, required this.textSub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: purple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              color: purple.withOpacity(0.4),
              size: 32.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 13.sp, color: textSub),
          ),
        ],
      ),
    );
  }
}
