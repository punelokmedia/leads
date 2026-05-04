import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/features/payments/domain/payment_model.dart';
import 'package:user_app/features/payments/infra/payment_controller.dart';
import '../widgets/history_widgets.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  static const _tabs = ['All', 'Payment', 'Leads'];
  static const _kBg = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            const PaymentsAppBar(),
            HistoryTabBar(
              tabs: _tabs,
              selectedIndex: state.selectedTabIndex,
              onTap: (i) => controller.fetchHistory(i), // Triggers API call for tab
            ),
            
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A2CD9)))
                  : state.error != null
                      ? Center(child: Text(state.error!))
                      : state.items.isEmpty
                          ? const HistoryEmptyState(label: 'No records found')
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                // ✅ FIX: Compare directly against the string 'PAYMENT'
                                return item.type == 'PAYMENT' 
                                    ? PaymentCard(payment: item) 
                                    : LeadCard(lead: item);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}