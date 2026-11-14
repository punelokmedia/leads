import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../preview/business_details_page.dart'
    show AccountPageHeader, accountText;
import '../../../preview/preview_data.dart';
import '../../../preview/profile_design.dart' show profileBackground;

const _blue = Color(0xFF0066FF);
const _options = [
  (
    'newLeads',
    'New lead alerts',
    'Get notified when matching leads are available.',
    true,
  ),
  ('leadUpdates', 'Lead updates', "Changes to leads you've unlocked.", true),
  ('payments', 'Payment & wallet', 'Top-ups, purchases and refunds.', true),
  (
    'membership',
    'Membership updates',
    'Plan expiry and membership news.',
    true,
  ),
  (
    'referrals',
    'Referral rewards',
    'Updates when you earn referral rewards.',
    true,
  ),
  (
    'announcements',
    'Offers & announcements',
    'Tips, promotions and product news.',
    false,
  ),
  (
    'whatsapp',
    'WhatsApp notifications',
    'Receive important updates on WhatsApp.',
    false,
  ),
];

class NotificationPreferencesPage extends ConsumerStatefulWidget {
  final PreviewStore store;
  const NotificationPreferencesPage({super.key, required this.store});
  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  late final values = {
    for (final option in _options)
      option.$1: ValueNotifier(
        widget.store.notificationPreferences?[option.$1] ?? option.$4,
      ),
  };
  bool loading = false;
  bool saving = false;
  String? error;
  static const path = 'api/v1/notifications/preferences';

  @override
  void initState() {
    super.initState();
    if (widget.store.isLive && widget.store.notificationPreferences == null) {
      Future.microtask(load);
    }
  }

  @override
  void dispose() {
    for (final value in values.values) {
      value.dispose();
    }
    super.dispose();
  }

  Map<String, bool> read(dynamic payload) {
    if (payload is! Map ||
        payload['success'] != true ||
        payload['data'] is! Map) {
      throw StateError('Unable to load preferences');
    }
    return {
      for (final option in _options)
        option.$1: payload['data'][option.$1] is bool
            ? payload['data'][option.$1] as bool
            : option.$4,
    };
  }

  Future<void> load() async {
    if (!mounted || loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = read((await ref.read(dioProvider).get(path)).data);
      if (!mounted) return;
      widget.store.notificationPreferences = data;
      for (final entry in data.entries) {
        values[entry.key]!.value = entry.value;
      }
    } catch (_) {
      if (mounted) error = 'Could not load preferences.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (saving ||
        loading ||
        (widget.store.isLive && widget.store.notificationPreferences == null)) {
      return;
    }
    setState(() => saving = true);
    final draft = values.map((key, value) => MapEntry(key, value.value));
    try {
      final changes = Map.fromEntries(
        draft.entries.where(
          (e) => widget.store.notificationPreferences?[e.key] != e.value,
        ),
      );
      final saved = widget.store.isLive && changes.isNotEmpty
          ? read((await ref.read(dioProvider).patch(path, data: changes)).data)
          : draft;
      if (!mounted) return;
      widget.store.notificationPreferences = saved;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification preferences saved')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save preferences. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: profileBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            children: [
              AccountPageHeader(store: widget.store),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Preferences',
                      style: accountText(
                        24,
                        color: const Color(0xFF0F172A),
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose which updates you want to receive.',
                      style: accountText(
                        14,
                        color: const Color(0xFF9498A1),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE57E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0ECFC)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/figma/location-banner.svg',
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set your preferred city and service',
                                style: accountText(
                                  13,
                                  color: const Color(0xFF0F172A),
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'to find nearby projects.',
                                style: accountText(12, weight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (loading) const LinearProgressIndicator(minHeight: 2),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Expanded(child: Text(error!, style: accountText(12))),
                      TextButton(
                        onPressed: loading ? null : load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: IgnorePointer(
                  ignoring:
                      loading ||
                      saving ||
                      (widget.store.isLive &&
                          widget.store.notificationPreferences == null),
                  child: Column(
                    children: [
                      for (final option in _options) ...[
                        if (option != _options.first)
                          const SizedBox(height: 13),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFEAF3FF),
                                  child: SvgPicture.asset(
                                    'assets/figma/preferences-${option.$1}.svg',
                                    width: option.$1 == 'whatsapp' ? 18 : 20,
                                    height: option.$1 == 'whatsapp' ? 18 : 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.$2,
                                        style: accountText(
                                          15,
                                          color: const Color(0xFF0F172A),
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        option.$3,
                                        style: accountText(
                                          12,
                                          color: const Color(0xFF7B8DA8),
                                          weight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _PreferenceSwitch(
                                  key: ValueKey('preference-${option.$1}'),
                                  label: option.$2,
                                  value: values[option.$1]!,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE57E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: _blue, size: 18),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'You can change these preferences anytime.',
                            style: accountText(
                              13,
                              color: const Color(0xFF0F172A),
                              weight: FontWeight.w400,
                            ).copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(23, 32, 22, 39),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed:
                          loading ||
                              saving ||
                              (widget.store.isLive &&
                                  widget.store.notificationPreferences == null)
                          ? null
                          : save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 51),
                        shape: const StadiumBorder(),
                        textStyle: accountText(
                          15,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Preferences'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.maybePop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          minimumSize: const Size(0, 29),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: const StadiumBorder(),
                          textStyle: accountText(14, weight: FontWeight.w700),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreferenceSwitch extends StatelessWidget {
  final String label;
  final ValueNotifier<bool> value;
  const _PreferenceSwitch({
    super.key,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: value,
    builder: (context, enabled, _) => Semantics(
      label: label,
      toggled: enabled,
      onTap: () => value.value = !enabled,
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTap: () => value.value = !enabled,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: enabled ? _blue : const Color(0xFFD2D6DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: enabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
