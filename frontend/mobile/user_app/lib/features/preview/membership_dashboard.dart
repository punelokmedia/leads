import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_amount_dialog.dart';
import 'preview_data.dart';
import 'home_dashboard.dart' show homeBlue, homeNavy, homeMuted;

class NextLeadMembership extends ConsumerStatefulWidget {
  final PreviewStore store;
  final VoidCallback onWallet;
  final VoidCallback onNotifications;
  final VoidCallback? onComparePlans;
  final VoidCallback? onReferAndEarn;
  final VoidCallback? onSignIn;

  const NextLeadMembership({
    super.key,
    required this.store,
    required this.onWallet,
    required this.onNotifications,
    this.onComparePlans,
    this.onReferAndEarn,
    this.onSignIn,
  });

  @override
  ConsumerState<NextLeadMembership> createState() => _NextLeadMembershipState();
}

class _NextLeadMembershipState extends ConsumerState<NextLeadMembership> {
  bool _upgrading = false;
  late final Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ref.read(dioProvider).post(
        'api/v1/wallet/verify',
        data: {
          'razorpayOrderId': response.orderId,
          'razorpayPaymentId': response.paymentId,
          'razorpaySignature': response.signature,
        },
      );
      // Once wallet is credited with ₹499, auto-activate membership
      await _activateMembershipViaWallet();
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Payment captured. Refreshing your wallet balance...',
        );
        ref.invalidate(walletProvider);
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _upgrading = false);
      SnackbarHelper.showError(context, 'Payment was cancelled or failed.');
    }
  }

  Future<void> _activateMembershipViaWallet() async {
    setState(() => _upgrading = true);
    try {
      if (widget.store.isLive) {
        await ref.read(dioProvider).post('api/v1/wallet/membership');
        ref.invalidate(walletProvider);
        await widget.store.refresh();
      } else {
        widget.store.activateMembership();
      }
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Pro Membership activated successfully! Full app access unlocked.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Wallet balance insufficient. Please add money and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  Future<void> _onUpgradePressed() async {
    if (_upgrading) return;

    // Check if user is signed in
    if (widget.store.isLive && (widget.store.profile['Full name'] ?? '').isEmpty) {
      if (widget.onSignIn != null) {
        widget.onSignIn!();
      } else {
        widget.store.account?.call(context);
      }
      return;
    }

    if (!widget.store.isLive) {
      _showUpgradeConfirmSheet(walletBalancePaise: 100000);
      return;
    }

    // Check wallet balance
    final walletData = ref.read(walletProvider).asData?.value;
    final int balancePaise = (walletData?['balancePaise'] as num? ?? 0).toInt();

    _showUpgradeConfirmSheet(walletBalancePaise: balancePaise);
  }

  void _showUpgradeConfirmSheet({required int walletBalancePaise}) {
    const int requiredPaise = 49900; // ₹499 in paise
    final bool hasEnough = walletBalancePaise >= requiredPaise;
    final double balanceRupees = walletBalancePaise / 100;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE6F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: homeBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NextLead Pro Membership',
                          style: TextStyle(
                            color: homeNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '₹499/month • Full App Access',
                          style: TextStyle(
                            color: homeBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFB78103), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Note: This is strictly the fee for app access. Leads are purchased separately.',
                        style: TextStyle(
                          color: Color(0xFF7C5600),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2EDFC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: homeNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹ ${balanceRupees.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: hasEnough ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (hasEnough)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _activateMembershipViaWallet();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: homeBlue,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Pay ₹499 & Activate Pro',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _topupAndActivate(requiredPaise);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: homeBlue,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Add ₹499 & Activate',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel', style: TextStyle(color: homeMuted)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _topupAndActivate(int amountPaise) async {
    setState(() => _upgrading = true);
    try {
      final response = await ref.read(dioProvider).post(
        'api/v1/wallet/topup',
        data: {'amountPaise': amountPaise},
      );
      final data = response.data['data'];
      _razorpay.open({
        'key': data['keyId'],
        'order_id': data['razorpayOrderId'],
        'amount': data['amountPaise'],
        'currency': 'INR',
        'name': 'NextLeads',
        'description': 'Pro Membership App Access Fee',
      });
    } catch (_) {
      if (mounted) {
        setState(() => _upgrading = false);
        SnackbarHelper.showError(context, 'Unable to initiate payment. Please retry.');
      }
    }
  }

  void _showFeeInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: homeBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Membership Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: homeNavy),
            ),
          ],
        ),
        content: const Text(
          '₹499/month is strictly the platform membership fee for app access, advanced search filters, priority customer support, and verified project access.\n\nLeads are purchased individually per project requirement.',
          style: TextStyle(color: Color(0xFF4A5568), fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: homeBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showComparePlansSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Plan Comparison',
                style: TextStyle(
                  color: homeNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Compare features between Free Guest and Pro Membership.',
                style: TextStyle(color: homeMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _planRow('App Access', 'Limited Preview', 'Full App Access'),
              const Divider(height: 16),
              _planRow('Lead Visibility', 'Masked Contact', 'Verified & Full Details'),
              const Divider(height: 16),
              _planRow('Filters', 'Basic Cities', 'Advanced Filter Engine'),
              const Divider(height: 16),
              _planRow('Customer Support', 'Standard Ticket', 'Priority Support'),
              const Divider(height: 16),
              _planRow('Lead Purchases', 'Separately', 'Separately'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: homeBlue,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _planRow(String feature, String freeVal, String proVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              feature,
              style: const TextStyle(
                color: homeNavy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeVal,
              style: const TextStyle(color: homeMuted, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              proVal,
              style: const TextStyle(
                color: homeBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReferAndEarnSheet(BuildContext context) {
    final String refCode = widget.store.isLive
        ? (widget.store.profile['Phone'] ?? 'NL2026').trim()
        : 'NLPRO2026';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EDFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: homeBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Refer Vendors & Earn Rewards',
                style: TextStyle(
                  color: homeNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Invite other contractors and professionals to NextLead. When they join and purchase verified leads, you earn wallet credits.',
                style: TextStyle(color: homeMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD7E5F9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Referral Code',
                          style: TextStyle(color: homeMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          refCode,
                          style: const TextStyle(
                            color: homeNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(ctx);
                        SnackbarHelper.showSuccess(context, 'Referral code copied to clipboard!');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE0EDFF),
                        foregroundColor: homeBlue,
                      ),
                      child: const Text('Copy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: homeBlue,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPro = widget.store.isProMember;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: widget.store.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Top Navigation Bar (matching existing screens) ──
            Row(
              children: [
                Image.asset(
                  'assets/branding/nextlead_wordmark.webp',
                  width: 133,
                  height: 47,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: widget.onWallet,
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: homeNavy,
                  ),
                  label: Text(
                    widget.store.isLive
                        ? ref.watch(walletProvider).when(
                            data: (data) =>
                                '₹ ${((data['balancePaise'] as num? ?? 0) / 100).toStringAsFixed(0)}',
                            loading: () => '...',
                            error: (_, _) => 'Wallet',
                          )
                        : 'Wallet',
                    style: const TextStyle(
                      color: homeNavy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDCE6F8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: widget.onNotifications,
                  icon: Badge(
                    isLabelVisible: widget.store.unread,
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: homeNavy,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Hero Header Section ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEMBERSHIP',
                        style: TextStyle(
                          color: homeBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Unlock the\nFull Potential',
                        style: TextStyle(
                          color: homeNavy,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Get complete access to the NextLead app and explore verified leads, advanced filters and more.',
                        style: TextStyle(
                          color: homeMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 2,
                  child: _HeroPhoneMockup(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Pro Membership Card ──
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0047FF), Color(0xFF0062CB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x280052CC),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Blue Header inside card
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'Most Popular',
                                      style: TextStyle(
                                        color: homeBlue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Pro Membership',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Full app access for growing businesses.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right side
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  '₹ 499',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  ' /month',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showFeeInfoDialog(context),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white70,
                                    size: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                ),
                              ),
                              child: const Text(
                                'App access only (not for leads)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Nested White Box for Features & Action Button
                  Container(
                    margin: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _featureRow(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Premium & verified leads',
                          subtitle: 'Get authentic and high-quality leads.',
                        ),
                        const SizedBox(height: 14),
                        _featureRow(
                          icon: Icons.filter_alt_rounded,
                          title: 'Advanced filters',
                          subtitle: 'Find the right leads, faster.',
                        ),
                        const SizedBox(height: 14),
                        _featureRow(
                          icon: Icons.headset_mic_rounded,
                          title: 'Priority support',
                          subtitle: 'Get quick help, whenever you need it.',
                        ),
                        const SizedBox(height: 14),
                        _featureRow(
                          icon: Icons.phone_android_rounded,
                          title: 'Access to all app features',
                          subtitle: 'Explore the full power of NextLead.',
                        ),
                        const SizedBox(height: 20),

                        // Action Button
                        if (isPro)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F7ED),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: const Color(0xFF48BB78)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF2F855A),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pro Membership Active',
                                  style: TextStyle(
                                    color: Color(0xFF2F855A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _upgrading ? null : _onUpgradePressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: homeBlue,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 2,
                              ),
                              child: _upgrading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Upgrade to Pro',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Compare Plans Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compare Plans',
                      style: TextStyle(
                        color: homeNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose the plan that fits your needs.',
                      style: TextStyle(
                        color: homeMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    if (widget.onComparePlans != null) {
                      widget.onComparePlans!();
                    } else {
                      _showComparePlansSheet(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            color: homeBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: homeBlue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Refer & Earn Section ──
            InkWell(
              onTap: () {
                if (widget.onReferAndEarn != null) {
                  widget.onReferAndEarn!();
                } else {
                  _showReferAndEarnSheet(context);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EEFC)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0EDFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: homeBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refer & Earn',
                            style: TextStyle(
                              color: homeNavy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Invite your friends and earn free app access benefits.',
                            style: TextStyle(
                              color: homeMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: homeNavy,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Footer Branding ──
            Center(
              child: Column(
                children: [
                  const Text(
                    'More Leads. More Opportunities.',
                    style: TextStyle(
                      color: homeNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Image.asset(
                    'assets/branding/nextlead_wordmark.webp',
                    width: 115,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFDCE6F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: homeBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: homeNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  color: homeMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Floating tilted phone mockup with surrounding icon badges
class _HeroPhoneMockup extends StatelessWidget {
  const _HeroPhoneMockup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 135,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background soft glow
          Positioned(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDCE6F7).withOpacity(0.5),
              ),
            ),
          ),

          // Tilted Smartphone
          Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 72,
              height: 122,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0F1E4A), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F0052CC),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Notch
                  Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1E4A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/branding/nextlead_arrow.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Full App Access',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: homeNavy,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  // Bottom bar line
                  Container(
                    width: 22,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Badges around Phone
          // Top Left: People
          Positioned(
            left: 0,
            top: 6,
            child: _floatingBadge(Icons.people_rounded),
          ),
          // Bottom Left: Verified Shield
          Positioned(
            left: 8,
            bottom: 8,
            child: _floatingBadge(Icons.verified_user_rounded),
          ),
          // Top Right: Filter
          Positioned(
            right: 0,
            top: 10,
            child: _floatingBadge(Icons.filter_alt_rounded),
          ),
          // Bottom Right: Insights / Analytics
          Positioned(
            right: 4,
            bottom: 12,
            child: _floatingBadge(Icons.insights_rounded),
          ),
        ],
      ),
    );
  }

  Widget _floatingBadge(IconData icon) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE6F7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0052CC),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 13, color: homeBlue),
    );
  }
}

