import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/core/network/dio_provider.dart';

final walletProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ref.watch(dioProvider).get('api/v1/wallet');
  return Map<String, dynamic>.from(response.data['data']);
});

class WalletCard extends ConsumerStatefulWidget {
  const WalletCard({super.key});
  @override
  ConsumerState<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends ConsumerState<WalletCard> {
  late final Razorpay _gateway;
  bool _busy = false;
  bool _loadingHistory = false;
  final List<dynamic> _olderEntries = [];
  String? _nextCursor;
  bool _historyLoaded = false;

  void _refresh() {
    _olderEntries.clear();
    _nextCursor = null;
    _historyLoaded = false;
    ref.invalidate(walletProvider);
  }

  Future<void> _loadHistory(String cursor) async {
    if (_loadingHistory) return;
    setState(() => _loadingHistory = true);
    try {
      final response = await ref
          .read(dioProvider)
          .get('api/v1/wallet/history', queryParameters: {'cursor': cursor});
      if (!mounted) return;
      setState(() {
        _olderEntries.addAll(response.data['data']['entries'] as List);
        _nextCursor = response.data['data']['nextCursor'] as String?;
        _historyLoaded = true;
      });
    } catch (_) {
      _message('Unable to load older transactions. Please retry.');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _gateway = Razorpay();
    _gateway.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse payment,
    ) async {
      try {
        await ref
            .read(dioProvider)
            .post(
              'api/v1/wallet/verify',
              data: {
                'razorpayOrderId': payment.orderId,
                'razorpayPaymentId': payment.paymentId,
                'razorpaySignature': payment.signature,
              },
            );
        _message('Money added to your wallet.');
      } catch (_) {
        _message(
          'Confirmation pending. Refresh your wallet before paying again.',
        );
      }
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    });
    _gateway.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse payment) {
      if (mounted) setState(() => _busy = false);
      _message('Payment cancelled or failed.');
    });
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  void dispose() {
    _gateway.clear();
    super.dispose();
  }

  Future<void> _addMoney() async {
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add money with Razorpay'),
        children: [
          for (final value in [100, 500, 1000, 2000])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Text('₹$value'),
            ),
        ],
      ),
    );
    if (amount == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post('api/v1/wallet/topup', data: {'amountPaise': amount * 100});
      final data = response.data['data'];
      _gateway.open({
        'key': data['keyId'],
        'order_id': data['razorpayOrderId'],
        'amount': data['amountPaise'],
        'currency': 'INR',
        'name': 'Next Leads',
        'description': 'Wallet top-up',
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _message('Unable to start top-up. Please retry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Wallet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            wallet.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(walletProvider),
                child: const Text('Retry loading wallet'),
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${((data['balancePaise'] as num) / 100).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 36),
                  ),
                  const Text(
                    'Referral rewards: eligible purchases of at least INR 50; up to INR 100 total.',
                  ),
                  const SizedBox(height: 16),
                  if (data['frozen'] == true)
                    const Text('Wallet under security review. Contact support before making payments.', style: TextStyle(color: Colors.red)),
                  const Text(
                    'Wallet history',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if ((data['entries'] as List).isEmpty)
                    const Text(
                      'No transactions yet. Your confirmed top-ups will appear here.',
                    ),
                  for (final entry in [
                    ...data['entries'] as List,
                    ..._olderEntries,
                  ])
                    ListTile(
                      title: Text(switch (entry['kind']) {
                        'TOPUP' => 'Money added via Razorpay',
                        'REFERRAL' => 'Referral reward',
                        'LEAD' => 'Lead purchase',
                        'MEMBERSHIP' => 'Membership purchase',
                        'REVERSAL' => 'Payment or referral reversal',
                        _ => 'Wallet transaction',
                      }),
                      subtitle: Text(
                        DateTime.parse(
                          entry['createdAt'].toString(),
                        ).toLocal().toString().split('.').first,
                      ),
                      trailing: Text(
                        '${(entry['amountPaise'] as num) >= 0 ? '+' : '-'}₹${((entry['amountPaise'] as num).abs() / 100).toStringAsFixed(2)}',
                      ),
                    ),
                  if ((_historyLoaded ? _nextCursor : data['nextCursor']) !=
                      null)
                    TextButton(
                      onPressed: _loadingHistory
                          ? null
                          : () => _loadHistory(
                              (_historyLoaded
                                      ? _nextCursor
                                      : data['nextCursor'])
                                  as String,
                            ),
                      child: Text(
                        _loadingHistory
                            ? 'Loading…'
                            : 'Load older transactions',
                      ),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _busy ? null : _addMoney,
              child: Text(_busy ? 'Payment in progress…' : 'Add money'),
            ),
            TextButton(
              onPressed: _loadingHistory ? null : _refresh,
              child: const Text('Refresh balance'),
            ),
          ],
        ),
      ),
    );
  }
}
