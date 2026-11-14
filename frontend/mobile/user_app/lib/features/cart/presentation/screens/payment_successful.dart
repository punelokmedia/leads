import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../app/app_router.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../preview/business_details_page.dart' show accountText;
import '../../../preview/lead_details_page.dart';
import '../../../preview/owned_lead_details_page.dart';
import '../../../preview/preview_data.dart';
import '../../../preview/profile_design.dart' show profileBackground;
import 'download_leads.dart';

final paymentConfirmationProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, orderId) async {
      if (orderId.isEmpty || orderId == 'N/A') {
        throw StateError('Order unavailable');
      }
      final dio = ref.watch(dioProvider);
      final history = (await dio.get(ApiEndpoints.history)).data;
      if (history is! Map ||
          history['success'] != true ||
          history['data'] is! List) {
        throw StateError('Order unavailable');
      }
      final order = (history['data'] as List)
          .whereType<Map>()
          .where((row) => '${row['orderId']}' == orderId)
          .firstOrNull;
      if (order == null ||
          order['status'] != 'PAID' ||
          order['totalAmount'] is! num ||
          (order['items'] as List? ?? []).isEmpty) {
        throw StateError('Payment is not confirmed');
      }
      final item = (order['items'] as List).first as Map;
      final response = (await dio.get(
        'api/v1/leads/get-lead/${item['leadId']}',
      )).data;
      if (response is! Map ||
          response['success'] != true ||
          response['data'] is! Map ||
          response['data']['isPurchased'] != true) {
        throw StateError('Lead access unavailable');
      }
      return {
        'order': Map<String, dynamic>.from(order),
        'lead': Map<String, dynamic>.from(response['data']),
      };
    });

const _blue = Color(0xFF0066FF),
    _navy = Color(0xFF072565),
    _muted = Color(0xFF64748B);
String _money(num value) =>
    '₹ ${NumberFormat('#,##0.##', 'en_IN').format(value)}';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentSuccessScreen({super.key, required this.orderId});
  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  final store = PreviewStore.empty();
  bool downloading = false;
  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  Future<void> receipt(Map<String, dynamic> order) async {
    if (downloading) return;
    setState(() => downloading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final id = widget.orderId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${directory.path}/Receipt_$id.txt');
      await file.writeAsString(
        'NextLead — Payment Receipt\n\nOrder: ${widget.orderId}\nStatus: PAID\n'
        'Amount: ${_money(order['totalAmount'] as num)}\nPaid at: ${order['paidAt'] ?? 'Not provided'}\n'
        'Payment method: ${order['paymentMethod'] ?? 'Not provided'}\n\n'
        '${(order['items'] as List).map((item) => '${item['title']} — ${_money(item['total'] as num? ?? item['price'] as num? ?? 0)}').join('\n')}\n',
      );
      await OpenFilex.open(file.path);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Receipt saved')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save receipt. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  PreviewLead lead(
    Map<String, dynamic> row,
    Map<String, dynamic> order,
  ) => PreviewLead(
    id: '${row['leadDisplayId'] ?? row['_id']}',
    backendId: '${row['_id']}',
    title: '${row['title'] ?? ''}',
    category: -1,
    city: '${row['city'] ?? ''}',
    state: '${row['state'] ?? ''}',
    budget: row['budget'] is Map
        ? (row['budget']['max'] as num?)?.toInt() ?? 0
        : 0,
    budgetLabel: (row['budgetRange'] ?? '').toString().isEmpty
        ? null
        : '${row['budgetRange']}',
    fee: ((order['items'] as List).first['price'] as num?) ?? 0,
    description: '${row['description'] ?? ''}',
    propertyType: '${row['propertyType'] ?? ''}',
    area:
        '${row['areaSize'] ?? row['areaSqFt'] ?? row['area'] ?? ''}${row['areaSqFt'] == null ? '' : ' sq ft'}',
    timeline: '${row['timeline'] ?? ''}',
    postedAt: DateTime.tryParse('${row['createdAt'] ?? ''}'),
    joined: true,
  );

  @override
  Widget build(BuildContext context) {
    final confirmation = ref.watch(paymentConfirmationProvider(widget.orderId));
    return Scaffold(
      backgroundColor: profileBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: confirmation.when(
              loading: () => Column(
                children: [
                  _header(),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (_, _) => Column(
                children: [
                  _header(),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Unable to load the confirmed payment details.',
                              textAlign: TextAlign.center,
                              style: accountText(15),
                            ),
                            TextButton(
                              onPressed: () => ref.invalidate(
                                paymentConfirmationProvider(widget.orderId),
                              ),
                              child: const Text('Retry'),
                            ),
                            TextButton(
                              onPressed: () => context.go(AppRouter.homePath),
                              child: const Text('Go to Home'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              data: (data) {
                final order = data['order'] as Map<String, dynamic>,
                    row = data['lead'] as Map<String, dynamic>;
                final item = lead(row, order);
                final category = row['category'] is Map
                    ? '${row['category']['displayName'] ?? row['category']['name'] ?? 'Project'}'
                    : 'Project';
                final details = LeadDetailsPreview(
                  lead: item,
                  store: store,
                  categoryName: category,
                );
                final count = (order['items'] as List).length;
                return ListView(
                  children: [
                    _header(),
                    SizedBox(
                      height: 110,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 210,
                            child: SvgPicture.asset(
                              'assets/figma/payment-celebration.svg',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Payment Successful!',
                      textAlign: TextAlign.center,
                      style: accountText(
                        24,
                        color: const Color(0xFF0F172A),
                        weight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 6, 30, 29),
                      child: Text(
                        'You can now access the complete lead details\nand connect with the client.',
                        textAlign: TextAlign.center,
                        style: accountText(
                          12,
                          color: _muted,
                        ).copyWith(height: 1.5),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          details.summary(context),
                          if (count > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                '$count leads purchased in this order',
                                style: accountText(13, color: Colors.white),
                              ),
                            ),
                          const SizedBox(height: 20),
                          _benefits(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(23, 18, 22, 8),
                      child: Text(
                        'Payment Details',
                        style: accountText(16, weight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 23),
                      child: Material(
                        color: const Color(0xFFFFE57E),
                        elevation: 2,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(17),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: _blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(9),
                                      child: Icon(
                                        Icons.description_outlined,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      count > 1
                                          ? 'Lead Access Fees ($count)'
                                          : 'Lead Access Fee',
                                      style: accountText(
                                        12,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _money(order['totalAmount'] as num),
                                    style: accountText(
                                      16,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              _row(
                                'Payment Method',
                                '${order['paymentMethod'] ?? 'Not provided'}',
                              ),
                              const SizedBox(height: 8),
                              _row(
                                'Transaction ID',
                                '${order['paymentId'] ?? widget.orderId}',
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 14, bottom: 4),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: downloading
                                          ? null
                                          : () => receipt(order),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft,
                                      ),
                                      icon: downloading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.download_outlined,
                                              color: _blue,
                                              size: 20,
                                            ),
                                      label: Text(
                                        'Download Receipt',
                                        style: accountText(
                                          12,
                                          color: const Color(0xFFEF4444),
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'More download options',
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      color: _blue,
                                      size: 20,
                                    ),
                                    onSelected: (_) => showDialog<void>(
                                      context: context,
                                      builder: (_) => DownloadLeadsDialog(
                                        orderId: widget.orderId,
                                      ),
                                    ),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'leads',
                                        child: Text('Download your Leads'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(23, 28, 22, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              if (count > 1) {
                                context.go(AppRouter.leadsPath);
                                return;
                              }
                              store.leads = [item];
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => OwnedLeadDetailsPage(
                                    lead: item,
                                    store: store,
                                    categoryName: category,
                                  ),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: const StadiumBorder(),
                              textStyle: accountText(
                                14,
                                color: Colors.white,
                                weight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 22,
                            ),
                            label: Text(
                              count > 1
                                  ? 'View Purchased Leads →'
                                  : 'View Complete Lead Details →',
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => context.go(AppRouter.homePath),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _blue,
                              minimumSize: const Size(0, 50),
                              side: const BorderSide(color: _blue),
                              shape: const StadiumBorder(),
                              textStyle: accountText(
                                14,
                                color: _blue,
                                weight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Go to Home →'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => SizedBox(
    height: 66,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(27, 4, 18, 0),
      child: Row(
        children: [
          Image.asset(
            'assets/figma/profile-logo.png',
            width: 129.75,
            height: 43.35,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            onPressed: () => context.go(AppRouter.homePath),
            icon: const Icon(Icons.close, color: Color(0xFF0F172A), size: 24),
          ),
        ],
      ),
    ),
  );

  Widget _row(String label, String value) => Row(
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: accountText(
            11,
            color: const Color(0xFF475569),
            weight: FontWeight.w400,
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: SelectableText(
          value,
          maxLines: 1,
          textAlign: TextAlign.right,
          style: accountText(11, weight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _benefits() => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: _blue),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you can now see?',
            style: accountText(
              14,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final text in [
                      'Complete project requirements',
                      'Client contact details (Name, Phone, Location)',
                      'Additional images and documents (if available)',
                      'Direct communication with the client',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: _blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                text,
                                style: accountText(
                                  11,
                                  color: Colors.white,
                                ).copyWith(height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SvgPicture.asset(
                'assets/figma/payment-access-document.svg',
                width: 90,
                height: 115,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
