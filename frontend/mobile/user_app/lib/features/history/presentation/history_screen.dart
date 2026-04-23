import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/history/presentation/widgets/history_card.dart';
import 'package:user_app/features/history/presentation/widgets/history_status_badge.dart';
import 'package:user_app/features/history/shared/history_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      if (isLoggedIn) {
        ref.read(historyControllerProvider.notifier).loadHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _HistoryAppBar(),
      body: const _HistoryBody(),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      
      title: Text(
        'History',
        style: AppTextStyles.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
          letterSpacing: 0.1,
          height: 20 / 24,
        ),
      ),
    );
  }
}

// ── Body: delegates to loading / error / empty / list ────────────────────────
class _HistoryBody extends ConsumerWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isLoading = ref.watch(historyIsLoadingProvider);
    final error = ref.watch(historyErrorProvider);
    final items = ref.watch(historyItemsProvider);
    final isEmpty = ref.watch(historyIsEmptyProvider);


    if (!isLoggedIn) {
      return const _HistoryLoginRequiredView();
    }
    if (isLoading && items.isEmpty) return const HistoryShimmerList();


    if (error != null) {
      return HistoryErrorState(
        message: error,
        onRetry: () =>
            ref.read(historyControllerProvider.notifier).loadHistory(),
      );
    }


    if (isEmpty) return const HistoryEmptyState();
    return RefreshIndicator(
      color: AppColors.color159,
      onRefresh: () =>
          ref.read(historyControllerProvider.notifier).loadHistory(),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 10.h, bottom: 24.h),
        itemCount: items.length,
        itemBuilder: (_, index) =>
            HistoryCard(item: items[index], isHighlighted: index == 0),
      ),
    );
  }
}

class _HistoryLoginRequiredView extends StatelessWidget {
  const _HistoryLoginRequiredView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 80.r, color: Colors.grey[300]),
            SizedBox(height: 24.h),
            Text(
              'Login to see History',
              style: AppTextStyles.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Please login to view your purchased leads and transaction history.',
              textAlign: TextAlign.center,
              style: AppTextStyles.roboto(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 30.h),
            ElevatedButton(
              onPressed: () => context.push(AppRouter.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.color159,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Go to Login',
                style: AppTextStyles.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}