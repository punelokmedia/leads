import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Frontend preview only. Does not track invites or issue wallet credit.
class ReferralSection extends StatelessWidget {
  const ReferralSection({super.key, this.initiallyExpanded = false});
  final bool initiallyExpanded;
  static const code = 'NEXTDEMO50';
  static const link = 'https://example.com/r/$code';

  Future<void> _copy(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to copy. Select the link to copy it.'),
        ),
      );
    }
  }

  void _sharePreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share your invitation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy this message and paste it into WhatsApp or another app. Native sharing will be connected later.',
            ),
            SizedBox(height: 16),
            SelectableText(
              'Join NextLeads using my referral code $code: $link (preview link)',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => _copy(
              dialogContext,
              'Join NextLeads using my referral code $code: $link (preview link)',
            ),
            child: const Text('Copy invitation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(Icons.card_giftcard_outlined, color: colors.primary),
        title: const Text(
          'Refer & Earn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Invite friends. Earn credit for leads.'),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frontend preview · Sample code, link and rewards. Invites are not tracked and no wallet credit is issued.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow together. Earn ₹50.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sample offer: earn ₹50 in wallet credit when a friend completes their first paid lead purchase.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final stat in [
                ('Invited', '3'),
                ('Qualified', '2'),
                ('Rewards', '₹100'),
              ])
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        stat.$2,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(stat.$1),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Sample referral code'),
          Row(
            children: [
              const Expanded(
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _copy(context, code),
                child: const Text('Copy code'),
              ),
            ],
          ),
          const Text('Sample referral link'),
          const SizedBox(height: 8),
          const SelectableText(link),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _copy(context, link),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy link'),
              ),
              OutlinedButton.icon(
                onPressed: () => _sharePreview(context),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share invitation'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'How it works',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Share your link with a friend.\n2. Your friend joins and buys their first lead.\n3. Earn wallet credit for your next lead purchase.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Sample referral activity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          for (final item in [
            ('Friend A', 'First purchase completed', '+₹50'),
            ('Friend B', 'First purchase completed', '+₹50'),
            ('Friend C', 'Awaiting first purchase', 'Pending'),
          ]) ...[
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(item.$2, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.$3,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Sample rules: one reward per new account, no self-referrals. Referral credit is for lead purchases and cannot be withdrawn. Final rewards and rules will be confirmed at launch.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
