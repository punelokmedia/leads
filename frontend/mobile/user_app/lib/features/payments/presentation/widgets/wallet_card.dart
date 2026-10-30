import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'wallet_amount_dialog.dart';
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
  int _selectedAmount = 500;
  String _filter = 'All';
  final _historyKey = GlobalKey();
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

  Future<void> _addMoney({int? presetPaise}) async {
    if (_busy) return;
    final amountPaise =
        presetPaise ??
        await showDialog<int>(
          context: context,
          builder: (context) => const WalletAmountDialog(),
        );
    if (amountPaise == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final response = await ref
          .read(dioProvider)
          .post('api/v1/wallet/topup', data: {'amountPaise': amountPaise});
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

  static const blue = Color(0xFF0066FF);
  static const navy = Color(0xFF08133E);
  static const muted = Color(0xFF7888AE);
  String _money(num paise) =>
      '\u20b9 ${NumberFormat('#,##0.##', 'en_IN').format(paise / 100)}';

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return wallet.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => TextButton(
        onPressed: _refresh,
        child: const Text('Retry loading wallet'),
      ),
      data: (data) {
        final frozen = data['frozen'] == true;
        final allEntries = [...data['entries'] as List, ..._olderEntries];
        final entries = allEntries
            .where(
              (entry) =>
                  _filter == 'All' ||
                  (_filter == 'Added'
                      ? (entry['amountPaise'] as num) >= 0
                      : (entry['amountPaise'] as num) < 0),
            )
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/branding/nextlead_wordmark.webp',
                  width: 145,
                  height: 48,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: blue,
                    size: 19,
                  ),
                  label: Text(
                    _money(data['balancePaise'] as num),
                    style: const TextStyle(color: navy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Wallet',
              style: TextStyle(
                fontSize: 27,
                color: navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your wallet, view transactions and add funds.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0F8FF), Color(0xFFE3EFFF)],
                ),
              ),
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
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                color: muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _money(data['balancePaise'] as num),
                              style: const TextStyle(
                                color: navy,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Use wallet balance to purchase leads and membership plans.',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 72,
                        color: blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy || frozen ? null : () => _addMoney(),
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Add Money'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final target = _historyKey.currentContext;
                            if (target != null) {
                              Scrollable.ensureVisible(
                                target,
                                duration: const Duration(milliseconds: 300),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: blue,
                            side: const BorderSide(color: blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('View History'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (frozen)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Wallet under security review. Contact support before making payments.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Quick Add Money',
              style: TextStyle(
                fontSize: 20,
                color: navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final amount in [500, 1000, 2000, 5000])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: InkWell(
                        onTap: _busy || frozen
                            ? null
                            : () => setState(() => _selectedAmount = amount),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedAmount == amount
                                ? const Color(0xFFE5F1FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: _selectedAmount == amount
                                  ? blue
                                  : const Color(0xFFE6ECF7),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _money(amount * 100),
                              style: const TextStyle(
                                color: navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: FilledButton(
                onPressed: _busy || frozen
                    ? null
                    : () => _addMoney(presetPaise: _selectedAmount * 100),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Add ${_money(_selectedAmount * 100)}  →'),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              key: _historyKey,
              children: [
                const Expanded(
                  child: Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 19,
                      color: navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Filter transactions',
                  initialValue: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                  itemBuilder: (_) => ['All', 'Added', 'Spent']
                      .map(
                        (value) =>
                            PopupMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_outlined,
                          color: muted,
                          size: 18,
                        ),
                        Text(
                          _filter == 'All' ? ' Filter' : ' $_filter',
                          style: const TextStyle(color: muted),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 17,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFEDF1F8)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  for (var i = 0; i < entries.length; i++) ...[
                    _transaction(entries[i]),
                    if (i < entries.length - 1)
                      const Divider(height: 1, color: Color(0xFFEDF1F8)),
                  ],
                ],
              ),
            ),
            if ((_historyLoaded ? _nextCursor : data['nextCursor']) != null)
              Center(
                child: TextButton(
                  onPressed: _loadingHistory
                      ? null
                      : () => _loadHistory(
                          (_historyLoaded ? _nextCursor : data['nextCursor'])
                              as String,
                        ),
                  child: Text(
                    _loadingHistory ? 'Loading...' : 'Load older transactions',
                  ),
                ),
              ),
            Center(
              child: TextButton(
                onPressed: _loadingHistory ? null : _refresh,
                child: const Text('Refresh balance'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _transaction(dynamic entry) {
    final amount = entry['amountPaise'] as num;
    final credit = amount >= 0;
    final color = credit ? const Color(0xFF00AD66) : const Color(0xFFFF5057);
    final title = switch (entry['kind']) {
      'TOPUP' => 'Added Money',
      'REFERRAL' => 'Referral Reward',
      'LEAD' => 'Purchase Leads',
      'MEMBERSHIP' => 'Membership Plan',
      'REVERSAL' => 'Reversal',
      _ => 'Wallet Transaction',
    };
    final date = DateTime.tryParse('${entry['createdAt']}')?.toLocal();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(
          credit
              ? Icons.add_circle
              : entry['kind'] == 'MEMBERSHIP'
              ? Icons.workspace_premium_outlined
              : Icons.shopping_cart_outlined,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: navy,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        date == null ? '' : DateFormat('dd MMM yyyy, hh:mm a').format(date),
        style: const TextStyle(color: muted, fontSize: 11),
      ),
      trailing: Text(
        '${credit ? '+' : '-'} ${_money(amount.abs())}',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(
            '${credit ? '+' : '-'} ${_money(amount.abs())}\n'
            '${date == null ? '' : DateFormat('dd MMM yyyy, hh:mm a').format(date)}\n'
            'Transaction: ${entry['_id'] ?? ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
