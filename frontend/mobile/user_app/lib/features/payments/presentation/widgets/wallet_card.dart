import 'package:flutter/material.dart';

/// Wallet UI preview. No payments or wallet updates are submitted.
class WalletCard extends StatelessWidget {
  const WalletCard({super.key});

  void _addMoney(BuildContext context) {
    var amount = 500;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add money',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a top-up amount. This is a frontend preview; no payment will be collected.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in [100, 500, 1000, 2000])
                      ChoiceChip(
                        label: Text('₹$value'),
                        selected: amount == value,
                        onSelected: (_) => setState(() => amount = value),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Payment preview'),
                          content: Text(
                            'Selected amount: ₹$amount\n\nRazorpay top-up will be connected later. No money has been charged and your wallet balance has not changed.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text('Preview ₹$amount top-up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _history(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sample wallet activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Illustrative transactions only. These are separate from your payment receipts.',
              ),
              for (final item in [
                ('Wallet top-up', 'Paid credit', '+₹500'),
                ('Referral reward', 'Friend A · First purchase', '+₹50'),
                ('Referral reward', 'Friend B · First purchase', '+₹50'),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(item.$1),
                  subtitle: Text(item.$2),
                  trailing: Text(item.$3),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'My Wallet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Text(
                  'PREVIEW',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Sample available balance'),
            Text(
              '₹600',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paid credit'),
                    Text(
                      '₹500',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Referral rewards'),
                    Text(
                      '₹100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _addMoney(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add money'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _history(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Wallet activity'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Frontend preview only. Sample credit cannot be spent. Wallet payments and referral credits will be connected later.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
