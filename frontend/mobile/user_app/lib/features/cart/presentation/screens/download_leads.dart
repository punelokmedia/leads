import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';

class DownloadLeadsDialog extends ConsumerWidget {
  final String orderId; 

  const DownloadLeadsDialog({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(cartIsLoadingProvider);

    ref.listen<String?>(cartErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        SnackbarHelper.showError(context, next);    
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Download',
              style: AppTextStyles.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF8B020),
              ),
            ),
            SizedBox(height: 20.h),
            Image.asset(
              'assets/Images/cart/dialog_illustration.png',
              height: 180.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20.h),
            Text(
              'Download the lead from the below option',
              textAlign: TextAlign.center,
              style: AppTextStyles.poppins(
                fontSize: 16.sp,
                color: AppColors.grey137,
              ),
            ),
            SizedBox(height: 30.h),
            GestureDetector(
              onTap: isLoading ? null : () async {
                await ref.read(cartControllerProvider.notifier).downloadLeads(orderId);
                if (context.mounted) {
                  SnackbarHelper.showSuccess(context, "Download started...");
                }
                // ignore: use_build_context_synchronously
                context.pop();
              },
              child: Container(
                width: double.infinity,
                height: 55.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC727),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                alignment: Alignment.center,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Download File',
                      style: AppTextStyles.poppins(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Only one time download available',
              style: AppTextStyles.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.red237,
              ),
            ),
          ],
        ),
      ),
    );
  }
}