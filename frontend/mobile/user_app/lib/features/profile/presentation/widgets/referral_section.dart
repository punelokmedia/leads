import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../preview/business_details_page.dart' show accountText;

class ReferralSection extends StatefulWidget {
  const ReferralSection({
    super.key,
    this.initiallyExpanded = false,
    this.data,
    this.history = const [],
    this.filter = 'All referrals',
    this.onFilter,
    this.onMore,
    this.historyError,
    this.historyLoading = false,
    this.onRetry,
  });
  final bool initiallyExpanded, historyLoading;
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>> history;
  final String filter;
  final ValueChanged<String>? onFilter;
  final VoidCallback? onMore, onRetry;
  final String? historyError;
  @override
  State<ReferralSection> createState() => _ReferralSectionState();
}

class _ReferralSectionState extends State<ReferralSection> {
  static const blue = Color(0xFF2563EB),
      navy = Color(0xFF072565),
      muted = Color(0xFF52688D);
  String localFilter = 'All referrals';
  bool get preview => widget.data == null;
  String get code => widget.data?['referralCode']?.toString() ?? 'NEXTDEMO50';
  String? get link => preview
      ? 'https://example.com/r/NEXTDEMO50'
      : widget.data?['referralLink']?.toString();
  String get invitation =>
      'Join NextLead using my referral code $code${link == null ? '' : ': $link'}${preview ? ' (preview link)' : ''}';

  Future<void> copy(String value, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to copy. Please retry.')),
        );
      }
    }
  }

  void share([String? destination]) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        destination == null
            ? 'Share your invitation'
            : 'Share via $destination',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy this invitation and paste it into ${destination ?? 'your preferred app'}.',
            ),
            const SizedBox(height: 16),
            SelectableText(invitation),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () => copy(invitation, 'Invitation copied'),
          child: const Text('Copy invitation'),
        ),
      ],
    ),
  );

  Widget panel(Widget child, {Color color = Colors.white}) => Material(
    color: color,
    elevation: 2,
    shadowColor: const Color(0x66475569),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFD5DEEB)),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  Widget text(
    String value,
    double size, {
    Color color = const Color(0xFF0F172A),
    FontWeight weight = FontWeight.w500,
  }) => Text(
    value,
    style: accountText(size, color: color, weight: weight),
  );

  @override
  Widget build(BuildContext context) {
    final filter = widget.onFilter == null ? localFilter : widget.filter;
    final rows = widget.history
        .where(
          (row) =>
              filter == 'All referrals' ||
              (filter == 'Successful'
                  ? row['status'] == 'QUALIFIED'
                  : row['status'] != 'QUALIFIED'),
        )
        .toList();
    final invited = widget.data?['invited'],
        qualified = widget.data?['qualified'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x99F9FBFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: text(
                  'GROW TOGETHER',
                  11,
                  color: blue,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Refer & '),
                    TextSpan(
                      text: 'Earn',
                      style: TextStyle(color: blue),
                    ),
                  ],
                ),
                style: accountText(24, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Know a vendor who could benefit from more business leads? Invite them to NextLead and get rewarded.',
                style: accountText(
                  12,
                  color: const Color(0xFF334155),
                ).copyWith(height: 1.7),
              ),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 315),
                  child: AspectRatio(
                    aspectRatio: 315 / 101,
                    child: SvgPicture.asset(
                      'assets/figma/referral-network.svg',
                    ),
                  ),
                ),
              ),
            ],
          ),
          color: const Color(0xFFFFE57E),
        ),
        const SizedBox(height: 16),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                preview ? 'SAMPLE REFERRAL CODE' : 'YOUR REFERRAL CODE',
                11,
                color: muted,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9FF),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          code,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => copy(code, 'Referral code copied'),
                        icon: const Icon(Icons.copy_outlined, size: 14),
                        label: const Text('Copy code'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: accountText(11, weight: FontWeight.w600),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              text(
                'Share your unique code with your network.',
                11,
                color: muted,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: share,
                icon: const Icon(Icons.share_outlined, size: 22),
                label: const Text('Share referral invite'),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  textStyle: accountText(14, weight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final action in [
                    (
                      'WhatsApp',
                      Icons.chat_outlined,
                      const Color(0xFF22C55E),
                      () => share('WhatsApp'),
                    ),
                    (
                      'Email',
                      Icons.mail_outline,
                      const Color(0xFF3B82F6),
                      () => share('Email'),
                    ),
                    (
                      'Copy Link',
                      Icons.link,
                      const Color(0xFFF1F5F9),
                      link == null
                          ? null
                          : () => copy(link!, 'Invitation link copied'),
                    ),
                    (
                      'More',
                      Icons.more_horiz,
                      const Color(0xFFF1F5F9),
                      () => share(),
                    ),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          IconButton.filled(
                            onPressed: action.$4,
                            tooltip: action.$1,
                            style: IconButton.styleFrom(
                              backgroundColor: action.$3,
                              foregroundColor:
                                  action.$1 == 'WhatsApp' ||
                                      action.$1 == 'Email'
                                  ? Colors.white
                                  : const Color(0xFF334155),
                              minimumSize: const Size(44, 44),
                            ),
                            icon: Icon(action.$2, size: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action.$1,
                            textAlign: TextAlign.center,
                            style: accountText(10, color: muted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (preview)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: text(
                    'Preview only. Sample code and link; no rewards are issued.',
                    11,
                    color: muted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final stat in [
              (
                'Total referrals',
                invited?.toString() ?? '—',
                Icons.groups_outlined,
                blue,
                const Color(0xFFEFF6FF),
              ),
              (
                'Successful referrals',
                qualified?.toString() ?? '—',
                Icons.check,
                const Color(0xFF059669),
                const Color(0xFFECFDF5),
              ),
              (
                'Rewards earned',
                widget.data?['rewardsEarnedPaise'] is num
                    ? '₹${NumberFormat('#,##0.##', 'en_IN').format((widget.data!['rewardsEarnedPaise'] as num) / 100)}'
                    : '₹ —',
                Icons.card_giftcard,
                const Color(0xFFF59E0B),
                const Color(0xFFFFFBEB),
              ),
            ])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: stat.$1 == 'Rewards earned' ? 0 : 8,
                  ),
                  child: panel(
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: stat.$5,
                          child: Icon(stat.$3, color: stat.$4, size: 22),
                        ),
                        const SizedBox(height: 4),
                        text(stat.$2, 15, weight: FontWeight.w700),
                        Text(
                          stat.$1,
                          textAlign: TextAlign.center,
                          style: accountText(10, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text('How it works', 14, weight: FontWeight.w700),
              const SizedBox(height: 16),
              for (final step in const [
                (
                  '1',
                  'Share your code',
                  'Send your unique code to vendors in your network.',
                  Icons.link,
                ),
                (
                  '2',
                  'They join NextLead',
                  'Your referral signs up using your referral code.',
                  Icons.person_add_alt,
                ),
                (
                  '3',
                  'Track your rewards',
                  'Check referral status and any eligible rewards here.',
                  Icons.card_giftcard,
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(step.$4, size: 18, color: blue),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            text(
                              '${step.$1}   ${step.$2}',
                              12,
                              weight: FontWeight.w700,
                            ),
                            const SizedBox(height: 4),
                            text(step.$3, 11, color: muted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(
                'Referral history',
                14,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 4),
              text(
                'Track all your referrals and their status.',
                11,
                color: const Color(0xFFBFDBFE),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in [
                    'All referrals',
                    'Successful',
                    'Pending',
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: filter == label,
                      showCheckmark: false,
                      selectedColor: blue,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide.none,
                      labelStyle: accountText(
                        11,
                        color: filter == label
                            ? Colors.white
                            : const Color(0xFF334155),
                        weight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (_) {
                        if (widget.onFilter != null) {
                          widget.onFilter!(label);
                        } else {
                          setState(() => localFilter = label);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: text(
                            '# · DETAILS',
                            10,
                            color: const Color(0xFF94A3B8),
                            weight: FontWeight.w700,
                          ),
                        ),
                        text(
                          'STATUS',
                          10,
                          color: const Color(0xFF94A3B8),
                          weight: FontWeight.w700,
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0)),
                    if (widget.historyError != null) ...[
                      text(widget.historyError!, 12),
                      TextButton(
                        onPressed: widget.onRetry,
                        child: const Text('Retry history'),
                      ),
                    ] else if (rows.isEmpty && !widget.historyLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(
                                Icons.group_add_outlined,
                                color: blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            text(
                              filter == 'All referrals'
                                  ? 'No referrals yet'
                                  : 'No ${filter.toLowerCase()} referrals',
                              12,
                              weight: FontWeight.w700,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your referrals will appear here after you invite vendors.',
                              textAlign: TextAlign.center,
                              style: accountText(11, color: muted),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  copy(invitation, 'Invitation copied'),
                              child: const Text('Copy invite message'),
                            ),
                          ],
                        ),
                      ),
                    for (final row in rows)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: text(
                          'Referral ${row['_id']}',
                          11,
                          weight: FontWeight.w600,
                        ),
                        subtitle: text(
                          DateTime.tryParse('${row['createdAt']}') == null
                              ? ''
                              : DateFormat('d MMM yyyy').format(
                                  DateTime.parse(
                                    '${row['createdAt']}',
                                  ).toLocal(),
                                ),
                          10,
                          color: muted,
                        ),
                        trailing: text(
                          row['status'] == 'QUALIFIED'
                              ? 'Successful'
                              : '${row['status'] ?? 'Pending'}',
                          10,
                          color: row['status'] == 'QUALIFIED'
                              ? const Color(0xFF059669)
                              : muted,
                        ),
                      ),
                    if (widget.historyLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    if (widget.onMore != null && !widget.historyLoading)
                      TextButton(
                        onPressed: widget.onMore,
                        child: const Text('Load more'),
                      ),
                  ],
                ),
              ),
              if (widget.data?['pending'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: text(
                    'Pending referrals: ${widget.data!['pending']}',
                    11,
                    color: const Color(0xFFBFDBFE),
                  ),
                ),
              if (widget.data?['appliedReferral'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: text(
                    'Your referral: ${widget.data!['appliedReferral']['status']}',
                    11,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          color: navy,
        ),
      ],
    );
  }
}
