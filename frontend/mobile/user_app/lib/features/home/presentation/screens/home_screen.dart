import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/home/infra/home_controller.dart';
import 'package:user_app/features/home/presentation/widgets/home_app_bar.dart';
import 'package:user_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:user_app/features/home/presentation/widgets/lead_card.dart';
import 'package:user_app/features/home/presentation/widgets/state_widgets.dart';
import 'package:user_app/features/home/shared/home_providers.dart'
    hide cartCountProvider, isInCartProvider;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).loadLeads();
      ref.read(cartControllerProvider.notifier); // init cart
    });
  }

  void _onCartTap() => context.push(AppRouter.cartPath);

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: HomeAppBar(cartCount: cartCount, onCartTap: _onCartTap),
      body: Column(
        children: [
          const HomeSearchBar(),
          Expanded(child: _HomeLeadList(onAddToCart: _onAddToCart)),
        ],
      ),
    );
  }

  void _onAddToCart(LeadModel lead) async {
    final message = await ref
        .read(cartControllerProvider.notifier)
        .addLeadToCart(lead);
    if (message != null && mounted) {
      final isError = message.contains("already") || message.contains("Failed");

      if (isError) {
        SnackbarHelper.showError(context, message);
      } else {
        SnackbarHelper.showSuccess(context, message);
        ref.read(homeControllerProvider.notifier).loadLeads();
      }
    }
  }
}

class _HomeLeadList extends ConsumerWidget {
  final void Function(LeadModel) onAddToCart;
  const _HomeLeadList({required this.onAddToCart});

  Future<void> _handleMsg(BuildContext context, Future<String?> future) async {
    final msg = await future;
    if (msg != null && context.mounted) {
      final isError = msg.toLowerCase().contains("wrong") ||
          msg.toLowerCase().contains("failed");
      isError
          ? SnackbarHelper.showError(context, msg)
          : SnackbarHelper.showSuccess(context, msg);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final leads = ref.watch(leadsProvider);

    if (isLoading && leads.isEmpty) return const LeadListShimmer();
    if (errorMessage != null) {
      return ErrorStateWidget(
        message: errorMessage,
        onRetry: () => ref.read(homeControllerProvider.notifier).loadLeads(),
      );
    }
    if (leads.isEmpty) return const EmptyStateWidget(message: 'No leads available');

    return RefreshIndicator(
      color: AppColors.color159,
      onRefresh: () => ref.read(homeControllerProvider.notifier).loadLeads(),
      child: ListView.builder(
        itemCount: leads.length,
        padding: EdgeInsets.only(bottom: 20.h),
        
        cacheExtent: 500,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return _LeadListItem(lead: lead, onAddToCart: onAddToCart);
        },
      ),
    );
  }
}

class _LeadListItem extends ConsumerWidget {
  final LeadModel lead;
  final void Function(LeadModel) onAddToCart;

  const _LeadListItem({required this.lead, required this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartQty = ref.watch(cartQuantityProvider(lead.id.toString()));
    final notifier = ref.read(cartControllerProvider.notifier);

    // ✅ 1. Check if the lead is sold out
    final isSoldOut = lead.status == 'SOLD_OUT';

    return Stack(
      children: [
        // The Main Card
        LeadCard(
          lead: lead,
          cartQuantity: cartQty,
          
          // ✅ 2. Disable actions by passing null if sold out
          onIncrement: isSoldOut
              ? null
              : () => _handleMsg(
                    context,
                    notifier.incrementLead(lead),
                  ),
          onDecrement: isSoldOut
              ? null
              : () => _handleMsg(
                    context,
                    notifier.decrementLead(lead.id.toString()),
                  ),
        ),

        
      ],
    );
  }

  Future<void> _handleMsg(BuildContext context, Future<String?> future) async {
    final msg = await future;
    if (msg != null && context.mounted) {
      final isError = msg.toLowerCase().contains("wrong") || 
                                msg.toLowerCase().contains("failed") ||
                                msg.toLowerCase().contains("max") ||
                                msg.toLowerCase().contains("allow");
      isError
          ? SnackbarHelper.showError(context, msg)
          : SnackbarHelper.showSuccess(context, msg);
    }
  }
}
