import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

enum PaymentStatus { success, failed, pending }

class PaymentHistoryModel {
  final String id;
  final String title;
  final String location;
  final String customerName;
  final String date;
  final double amount;
  final PaymentStatus status;

  const PaymentHistoryModel({
    required this.id,
    required this.title,
    required this.location,
    required this.customerName,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class LeadHistoryModel {
  final String id;
  final String leadType;
  final String location;
  final String customerName;
  final String phone;
  final double amount;
  final String internalOrderId;

  const LeadHistoryModel({
    required this.id,
    required this.leadType,
    required this.location,
    required this.customerName,
    required this.phone,
    required this.amount,
    required this.internalOrderId,
  });
}

final paymentHistoryProvider = Provider<List<PaymentHistoryModel>>(
  (_) => [
    const PaymentHistoryModel(
      id: '1',
      title: 'Interior Design Project',
      location: 'Mumbai, Maharashtra',
      customerName: 'Rahul Sharma',
      date: '30th April',
      amount: 250000,
      status: PaymentStatus.success,
    ),
    const PaymentHistoryModel(
      id: '2',
      title: 'Interior Design Project',
      location: 'Mumbai, Maharashtra',
      customerName: 'Rahul Sharma',
      date: '30th April',
      amount: 250000,
      status: PaymentStatus.success,
    ),
    const PaymentHistoryModel(
      id: '3',
      title: 'Renovation Project',
      location: 'Pune, Maharashtra',
      customerName: 'Suresh Patil',
      date: '28th April',
      amount: 180000,
      status: PaymentStatus.failed,
    ),
  ],
);

final leadHistoryProvider = Provider<List<LeadHistoryModel>>(
  (_) => [
    const LeadHistoryModel(
      id: '1',
      leadType: 'Interior Design',
      location: 'Mumbai, Maharashtra',
      customerName: 'Amit Verma',
      phone: '+91 982347359',
      amount: 250000,
      internalOrderId: 'ORD001',
    ),
    const LeadHistoryModel(
      id: '2',
      leadType: 'Interior Design',
      location: 'Mumbai, Maharashtra',
      customerName: 'Amit Verma',
      phone: '+91 982347359',
      amount: 250000,
      internalOrderId: 'ORD002',
    ),
    const LeadHistoryModel(
      id: '3',
      leadType: 'Plumbing',
      location: 'Pune, Maharashtra',
      customerName: 'Vijay More',
      phone: '+91 900000001',
      amount: 75000,
      internalOrderId: 'ORD003',
    ),
  ],
);

const _kPurple = Color(0xFF4A2CD9);
const _kPurpleLight = Color(0xFFEEEBFB);
const _kGreen = Color(0xFF1B8A3E);
const _kRed = Color(0xFFD32F2F);
const _kGrey = Color(0xFF777777);
const _kBorder = Color(0xFFD8D5F5);
const _kBg = Color(0xFFF5F5F5);

class PaymentsScreen extends HookConsumerWidget {
  const PaymentsScreen({super.key});

  static const _tabs = ['All', 'Payment', 'Leads'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState(0);

    final payments = ref.watch(paymentHistoryProvider);
    final leads = ref.watch(leadHistoryProvider);

    Widget body() {
      switch (tabIndex.value) {
        case 1:
          return _PaymentList(payments: payments);
        case 2:
          return _LeadList(leads: leads);
        default:
          return _AllList(payments: payments, leads: leads);
      }
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _PaymentsAppBar(),

            _TabBar(
              tabs: _tabs,
              selectedIndex: tabIndex.value,
              onTap: (i) => tabIndex.value = i,
            ),

            // ── Content ─────────────────────────────────────
            Expanded(child: body()),
          ],
        ),
      ),
    );
  }
}

class _PaymentsAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Payments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),

          SizedBox(width: 36.w),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CUSTOM TAB BAR
// ─────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _TabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      tabs[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? _kPurple : _kGrey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Animated indicator
          Stack(
            children: [
              // Full-width grey underline
              Container(height: 2.h, color: Colors.grey.shade200),
              // Moving purple indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment(
                  // Maps 0→−1, 1→0, 2→1
                  -1.0 + (selectedIndex / (tabs.length - 1)) * 2,
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / tabs.length,
                  child: Container(
                    height: 2.5.h,
                    decoration: BoxDecoration(
                      color: _kPurple,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  LIST VIEWS
// ─────────────────────────────────────────────────────────────────

/// "All" tab — interleaves payments then leads
class _AllList extends StatelessWidget {
  final List<PaymentHistoryModel> payments;
  final List<LeadHistoryModel> leads;

  const _AllList({required this.payments, required this.leads});

  @override
  Widget build(BuildContext context) {
    final total = payments.length + leads.length;
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: total,
      itemBuilder: (_, i) {
        if (i < payments.length) {
          return _PaymentCard(payment: payments[i]);
        }
        return _LeadCard(lead: leads[i - payments.length]);
      },
    );
  }
}

class _PaymentList extends StatelessWidget {
  final List<PaymentHistoryModel> payments;
  const _PaymentList({required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return const _EmptyState(label: 'No payments yet');
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: payments.length,
      itemBuilder: (_, i) => _PaymentCard(payment: payments[i]),
    );
  }
}

class _LeadList extends StatelessWidget {
  final List<LeadHistoryModel> leads;
  const _LeadList({required this.leads});

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) return const _EmptyState(label: 'No leads yet');
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: leads.length,
      itemBuilder: (_, i) => _LeadCard(lead: leads[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PAYMENT CARD  (top half: icon + title + location)
//                (bottom half: name | amount + status)
// ─────────────────────────────────────────────────────────────────
class _PaymentCard extends StatelessWidget {
  final PaymentHistoryModel payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.status == PaymentStatus.success;
    final statusText = switch (payment.status) {
      PaymentStatus.success => 'Success',
      PaymentStatus.failed => 'Failed',
      PaymentStatus.pending => 'Pending',
    };
    final statusColor = switch (payment.status) {
      PaymentStatus.success => _kGreen,
      PaymentStatus.failed => _kRed,
      PaymentStatus.pending => Colors.orange,
    };

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _kBorder, width: 1.2),
      ),
      child: Column(
        children: [
          // ── Top row: icon + title + location ────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _kPurpleLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: _kPurple,
                    size: 26.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12.r,
                            color: _kGrey,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            payment.location,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.sp,
                              color: _kGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Bottom row: name + date | amount + status ───
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16.r),
              ),
            ),
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Name + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.customerName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      payment.date,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.sp,
                        color: _kGrey,
                      ),
                    ),
                  ],
                ),

                // Amount + status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹ ${_formatAmount(payment.amount)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _kGreen,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Status : ',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  LEAD CARD  (top half: icon + lead type + location)
//              (bottom half: name + phone | amount + download)
// ─────────────────────────────────────────────────────────────────
class _LeadCard extends StatelessWidget {
  final LeadHistoryModel lead;
  const _LeadCard({required this.lead});

  void _onDownload(BuildContext context) {
    // TODO: wire to your downloadLead(internalOrderId) API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading lead ${lead.internalOrderId}…'),
        backgroundColor: _kPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _kBorder, width: 1.2),
      ),
      child: Column(
        children: [
          // ── Top row: icon + title + location ────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _kPurpleLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.settings_accessibility_rounded,
                    color: _kPurple,
                    size: 26.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lead Type : ${lead.leadType}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12.r,
                            color: _kGrey,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            lead.location,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.sp,
                              color: _kGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Bottom row ───────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16.r),
              ),
            ),
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Name + phone
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.customerName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      lead.phone,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.sp,
                        color: _kGrey,
                      ),
                    ),
                  ],
                ),

                // Amount + download
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹ ${_formatAmount(lead.amount)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _kGreen,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: () => _onDownload(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Download',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.download_rounded,
                            size: 18.r,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56.r,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────
String _formatAmount(double amount) {
  // 250000 → "2,50,000"  (Indian numbering)
  final str = amount.toInt().toString();
  if (str.length <= 3) return str;
  final last3 = str.substring(str.length - 3);
  final rest = str.substring(0, str.length - 3);
  final result = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) result.write(',');
    result.write(rest[i]);
  }
  return '${result.toString()},$last3';
}
