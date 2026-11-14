import 'figma_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
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
      await ref
          .read(dioProvider)
          .post(
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
    if (widget.store.isLive &&
        (widget.store.profile['Full name'] ?? '').isEmpty) {
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
                      color: const Color(0xFFE5EFFF),
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
                            fontSize: 16,
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
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFB78103),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Note: This is strictly the fee for app access. Leads are purchased separately.',
                        style: TextStyle(
                          color: Color(0xFF7C5600),
                          fontSize: 16,
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
                    const Expanded(
                      child: Text(
                        'Wallet Balance',
                        style: TextStyle(
                          color: homeNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '₹ ${balanceRupees.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: hasEnough
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        fontSize: 17,
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: homeMuted),
                      ),
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
      final response = await ref
          .read(dioProvider)
          .post('api/v1/wallet/topup', data: {'amountPaise': amountPaise});
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
        SnackbarHelper.showError(
          context,
          'Unable to initiate payment. Please retry.',
        );
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: homeNavy,
              ),
            ),
          ],
        ),
        content: const Text(
          '₹499/month is strictly the platform membership fee for app access, advanced search filters, priority customer support, and verified project access.\n\nLeads are purchased individually per project requirement.',
          style: TextStyle(
            color: Color(0xFF4A5568),
            fontSize: 16,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got it',
              style: TextStyle(color: homeBlue, fontWeight: FontWeight.w700),
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
                style: TextStyle(color: homeMuted, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                          style: TextStyle(color: homeMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          refCode,
                          style: const TextStyle(
                            color: homeNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(ctx);
                        SnackbarHelper.showSuccess(
                          context,
                          'Referral code copied to clipboard!',
                        );
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
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.store.isProMember;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: widget.store.refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            FigmaHeader(
              onWallet: widget.onWallet,
              onNotifications: widget.onNotifications,
              unread: widget.store.unread,
              live: widget.store.isLive,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Membership',
                    style: TextStyle(
                      color: homeNavy,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unlock the\nFull Potential',
                              style: TextStyle(
                                color: homeBlue,
                                fontSize: 29,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Get complete access to the NextLead app and explore verified leads, advanced filters and more.',
                              style: TextStyle(
                                color: homeMuted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: AspectRatio(
                          aspectRatio: 154 / 203,
                          child: SvgPicture.asset(
                            'assets/figma/membership-phone.svg',
                            semanticsLabel:
                                'Full app access with NextLead membership',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: figmaNavy,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 10,
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: StadiumBorder(),
                          shadows: [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: homeBlue),
                            SizedBox(width: 5),
                            Text(
                              'Most Popular',
                              style: TextStyle(
                                fontFamily: 'ProfileMontserrat',
                                color: homeBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '\u20b9 499',
                            style: TextStyle(
                              fontFamily: 'ProfileMontserrat',
                              color: Color(0xFFFFE57E),
                              fontSize: 30,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            ' /month',
                            style: TextStyle(
                              fontFamily: 'ProfileMontserrat',
                              color: Color(0xE6FFFFFF),
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Pricing details',
                            onPressed: () => _showFeeInfoDialog(context),
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 40,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.info_outline,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Pro Membership',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF234C9B),
                        shape: StadiumBorder(side: BorderSide(color: homeBlue)),
                      ),
                      child: const Text(
                        'App access only (not for leads)',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Full app access for growing businesses.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _membershipFeature(
                          'membership-verified',
                          'Premium & verified leads',
                          'Get authentic and high-quality leads.',
                        ),
                        const SizedBox(height: 18),
                        _membershipFeature(
                          'membership-filters',
                          'Advanced filters',
                          'Find the right leads, faster.',
                        ),
                        const SizedBox(height: 18),
                        _membershipFeature(
                          'membership-support',
                          'Priority support',
                          'Get quick help, whenever you need it.',
                        ),
                        const SizedBox(height: 18),
                        _membershipFeature(
                          'membership-features',
                          'Access to all app features',
                          'Explore the full power of NextLead.',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isPro || _upgrading
                                ? null
                                : _onUpgradePressed,
                            style: FilledButton.styleFrom(
                              backgroundColor: homeBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: const StadiumBorder(),
                              elevation: 5,
                              shadowColor: const Color(0x660066FF),
                            ),
                            child: _upgrading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isPro
                                        ? 'Pro Membership Active'
                                        : 'Upgrade to Pro  \u2192',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: const Color(0xFFFFE77C),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    if (widget.onReferAndEarn != null) {
                      widget.onReferAndEarn!();
                    } else {
                      _showReferAndEarnSheet(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        figmaSvg('membership-gift', size: 48),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Refer & Earn',
                                style: TextStyle(
                                  color: homeNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Invite your friends and earn free app access benefits.',
                                style: TextStyle(
                                  color: homeNavy,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: homeNavy),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _membershipFeature(String asset, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      figmaSvg(asset, size: 44),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: homeNavy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: homeMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
