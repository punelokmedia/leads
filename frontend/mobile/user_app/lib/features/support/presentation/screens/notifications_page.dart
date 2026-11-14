import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/app_router.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/shared/auth_providers.dart';
import '../../../payments/presentation/widgets/wallet_card.dart';
import '../../../preview/figma_widgets.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final List<Map<String, dynamic>> _items = [];
  String _filter = 'All';
  String? _cursor, _error;
  bool _loading = true, _saving = false;
  static const _filters = [
    'All',
    'New Leads',
    'Updates',
    'Payments',
    'Announcements',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  Future<void> _load({bool more = false}) async {
    if (!mounted) return;
    if (!ref.read(isLoggedInProvider)) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(dioProvider)
          .get(
            'api/v1/notifications',
            queryParameters: {if (more && _cursor != null) 'before': _cursor},
          );
      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['success'] != true) {
        throw StateError('Unable to load notifications');
      }
      final rows = (payload['data'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        for (final row in rows) {
          if (!_items.any((item) => item['_id'] == row['_id'])) _items.add(row);
        }
        _cursor = payload['nextCursor'] as String?;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load notifications. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _category(Map<String, dynamic> item) => switch (item['type']) {
    'NEW_LEAD' => 'New Leads',
    'PAYMENT_SUCCESS' || 'WALLET_CREDIT' || 'REFUND_COMPLETED' => 'Payments',
    'ANNOUNCEMENT' => 'Announcements',
    _ => 'Updates',
  };
  String _label(Map<String, dynamic> item) => switch (item['type']) {
    'NEW_LEAD' => 'New Lead',
    'MEMBERSHIP_ACTIVATED' => 'Membership',
    'ANNOUNCEMENT' => 'Announcement',
    'PAYMENT_SUCCESS' || 'WALLET_CREDIT' || 'REFUND_COMPLETED' => 'Payment',
    _ => 'Update',
  };
  DateTime? _date(Map<String, dynamic> item) =>
      DateTime.tryParse('${item['createdAt']}')?.toLocal();
  String _group(Map<String, dynamic> item) {
    final date = _date(item);
    if (date == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final days = today.difference(day).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7 && days > 0) return 'This Week';
    return 'Earlier';
  }

  Future<void> _read({Map<String, dynamic>? item}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final response = await ref
          .read(dioProvider)
          .patch(
            item == null
                ? 'api/v1/notifications/read-all'
                : "api/v1/notifications/${item['_id']}/read",
          );
      if (response.data['success'] != true) {
        throw StateError('Read update failed');
      }
      if (!mounted) return;
      setState(() {
        for (final row in _items) {
          if (item == null || row['_id'] == item['_id']) {
            row['readAt'] ??= DateTime.now().toIso8601String();
          }
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update read status. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _open(Map<String, dynamic> item) {
    if (item['readAt'] == null) _read(item: item);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item['title'] ?? ''}'),
        content: Text('${item['message'] ?? ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (previous == next) return;
      if (next) {
        _load();
      } else {
        setState(() {
          _items.clear();
          _cursor = null;
          _error = null;
          _loading = false;
        });
      }
    });
    final signedIn = ref.watch(isLoggedInProvider);
    final items = _items
        .where((item) => _filter == 'All' || _category(item) == _filter)
        .toList();
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      groups.putIfAbsent(_group(item), () => []).add(item);
    }
    return Scaffold(
      backgroundColor: figmaBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              FigmaHeader(
                onWallet: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      backgroundColor: figmaBackground,
                      body: SafeArea(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            WalletCard(onBack: () => Navigator.pop(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                onNotifications: () => _load(),
                unread: _items.any((item) => item['readAt'] == null),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: figmaInk,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          !signedIn ||
                              _saving ||
                              !_items.any((item) => item['readAt'] == null)
                          ? null
                          : () => _read(),
                      child: const Text('Mark all as read \u2713'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Stay updated with new leads, updates and important alerts.',
                  style: TextStyle(fontSize: 14, color: figmaMuted),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
                ),
                child: Row(
                  children: _filters
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: _filter == filter,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filter = filter),
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFFEAF3FF),
                            labelStyle: TextStyle(
                              color: _filter == filter ? figmaBlue : figmaInk,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: _filter == filter
                                    ? figmaBlue
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                decoration: const BoxDecoration(
                  color: figmaNavy,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                    bottom: Radius.circular(26),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    if (_error != null)
                      _status(
                        _error!,
                        action: TextButton(
                          onPressed: () => _load(),
                          child: const Text('Retry'),
                        ),
                      ),
                    if (!signedIn)
                      _status(
                        'Sign in to view your notifications.',
                        action: TextButton(
                          onPressed: () => context.push(AppRouter.login),
                          child: const Text('Sign in'),
                        ),
                      ),
                    if (signedIn &&
                        !_loading &&
                        _error == null &&
                        items.isEmpty)
                      _status(
                        _filter == 'All'
                            ? 'No notifications yet'
                            : 'No notifications in this category',
                        detail:
                            'Your updates will appear here when they arrive.',
                      ),
                    for (final group in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: Text(
                          group.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...group.value.map(_card),
                    ],
                    if (_cursor != null)
                      TextButton(
                        onPressed: _loading ? null : () => _load(more: true),
                        child: const Text(
                          'Load older notifications',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FigmaBottomNav(
        selected: -1,
        onSelect: (index) {
          final path = [
            AppRouter.homePath,
            AppRouter.leadsPath,
            AppRouter.cartPath,
            AppRouter.membershipPath,
            AppRouter.profilePath,
          ][index];
          context.go(path);
        },
      ),
    );
  }

  Widget _status(String title, {String? detail, Widget? action}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          size: 40,
          color: figmaBlue,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: figmaInk,
          ),
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: figmaMuted),
            ),
          ),
        ?action,
      ],
    ),
  );

  Widget _card(Map<String, dynamic> item) {
    final label = _label(item);
    final color = switch (label) {
      'Membership' => const Color(0xFFE9AB00),
      'Payment' => const Color(0xFF00AD80),
      'Announcement' => const Color(0xFF8B3DFF),
      'Update' => const Color(0xFFED4692),
      _ => figmaBlue,
    };
    final icon = switch (label) {
      'Membership' => Icons.star_rounded,
      'Payment' => Icons.credit_card,
      'Announcement' => Icons.campaign_outlined,
      'Update' => Icons.notifications_outlined,
      _ => Icons.assignment_outlined,
    };
    final date = _date(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _open(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: color.withValues(alpha: .09),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: figmaBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item['title'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: figmaInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['message'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: figmaMuted),
                      ),
                      if (date != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd MMM yyyy, h:mm a').format(date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: figmaMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  children: [
                    if (item['readAt'] == null)
                      const Icon(Icons.circle, size: 9, color: figmaBlue),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: figmaMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
