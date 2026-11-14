import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_router.dart';
import '../../../preview/figma_widgets.dart';
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
  final VoidCallback? onBack;
  const WalletCard({super.key, this.onBack});
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

  Widget _walletIllustration() => SizedBox(
    width: 107,
    height: 108,
    child: Stack(
      children: [
        for (final v in <(String, double, double, double, double)>[
          ('750-2035-imgVector1', 2.13, 23.08, 81.12, 62.38),
          ('750-2035-imgVector2', 8.96, 19.04, 66.31, 31.82),
          ('750-2035-imgVector3', 0, 30.79, 82.55, 55.6),
          ('750-2035-imgVector4', 0, 32.47, 82.55, 13.48),
          ('750-2035-imgVector5', 0, 53.53, 82.55, 7.16),
          ('750-2035-imgVector6', 53.07, 60.27, 35.38, 35.38),
          ('750-2035-imgVector7', 56.44, 63.64, 28.64, 28.64),
        ])
          Positioned(
            left: v.$2,
            top: v.$3,
            width: v.$4,
            height: v.$5,
            child: figmaSvg(v.$1, size: v.$4),
          ),
        const Positioned(
          left: 64,
          top: 64,
          child: Text('₹', style: TextStyle(color: Colors.white, fontSize: 23)),
        ),
      ],
    ),
  );

  static const blue = figmaBlue;
  static const navy = figmaInk;
  static const muted = figmaMuted;
  String _money(num paise) =>
      '\u20b9 ${NumberFormat('#,##0.##', 'en_IN').format(paise / 100)}';

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final data = wallet.asData?.value;
    final unavailable = data == null;
    final frozen = unavailable || data['frozen'] == true;
    final allEntries = [
      ...(data?['entries'] as List? ?? const []),
      ..._olderEntries,
    ];
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
        FigmaHeader(
          onWallet: _refresh,
          onNotifications: () => context.push(AppRouter.notificationPath),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.onBack != null)
              IconButton(
                tooltip: 'Back to home',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 20, color: navy),
              ),
            const Text(
              'Wallet',
              style: TextStyle(
                fontSize: 24,
                color: navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
            gradient: const LinearGradient(colors: [figmaNavy, figmaNavy]),
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
                          'AVAILABLE BALANCE',
                          style: TextStyle(
                            color: Color(0xFF00BBFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data == null
                              ? (wallet.isLoading
                                    ? 'Loading...'
                                    : 'Unavailable')
                              : _money(data['balancePaise'] as num),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Use wallet balance to purchase leads and membership plans.',
                          style: TextStyle(
                            color: Color(0xFFA6BADF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _walletIllustration(),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy || frozen ? null : () => _addMoney(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
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
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                        foregroundColor: blue,
                        backgroundColor: Colors.white,
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
        if (wallet.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(),
          ),
        if (wallet.hasError)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loadError(wallet.error),
                    style: const TextStyle(fontSize: 14, color: navy),
                  ),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry loading wallet'),
                  ),
                ],
              ),
            ),
          ),
        if (!unavailable && frozen)
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
            fontSize: 16,
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
                  fontSize: 16,
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
                    (value) => PopupMenuItem(value: value, child: Text(value)),
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
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    unavailable
                        ? (wallet.isLoading
                              ? 'Loading transactions...'
                              : 'Transactions are unavailable. Retry loading your wallet.')
                        : 'No transactions found.',
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
        if ((_historyLoaded ? _nextCursor : data?['nextCursor']) != null)
          Center(
            child: TextButton(
              onPressed: _loadingHistory
                  ? null
                  : () => _loadHistory(
                      (_historyLoaded ? _nextCursor : data?['nextCursor'])
                          as String,
                    ),
              child: Text(
                _loadingHistory ? 'Loading...' : 'Load older transactions',
              ),
            ),
          ),
        Center(
          child: Column(
            children: [
              TextButton(
                onPressed: _loadingHistory ? null : _refresh,
                child: const Text('Refresh balance'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _loadError(Object? error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Sign in again to load your wallet.';
      }
      if (error.response?.statusCode == 404) {
        return 'Wallet is currently unavailable. Please try again later.';
      }
    }
    return 'Unable to load your wallet. Check your connection and retry.';
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
