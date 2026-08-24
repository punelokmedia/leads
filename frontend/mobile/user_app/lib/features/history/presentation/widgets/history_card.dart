import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/core/widgets/app_network_image.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import '../../domain/history_model.dart';
import 'history_status_badge.dart';

class HistoryCard extends StatelessWidget {
  final HistoryModel item;
  final bool isHighlighted;

  const HistoryCard({
    super.key,
    required this.item,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.color159, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHeader(item: item),

            SizedBox(height: 12.h),

            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.white239,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: _CardDetails(item: item),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header: thumbnail + title + city ──────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final HistoryModel item;
  const _CardHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: AppNetworkImage(
            url: item.imageUrl,
            width: 65.w,
            height: 45.h,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 65.w,
              height: 45.h,
              color: AppColors.white239,
              child: Icon(
                Icons.broken_image_outlined,
                size: 20.r,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),

        SizedBox(width: 14.w),

        // Title and City
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.leadType,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.roboto(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12.r, color: AppColors.grey137),
                  SizedBox(width: 4.w),
                  Text(
                    item.city,
                    style: AppTextStyles.roboto(
                      fontSize: 12.sp,
                      color: AppColors.grey137,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Details: name, time, address, phone, sharing, status ──────────────────────
class _CardDetails extends ConsumerWidget {
  final HistoryModel item;
  const _CardDetails({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.customerName,
              style: AppTextStyles.roboto(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 1.48,
                color: AppColors.darkblue43,
              ),
            ),
            Text(
              item.time,
              style: AppTextStyles.roboto(
                fontSize: 12.sp,
                color: Colors.grey[500]!,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          item.address,
          style: AppTextStyles.roboto(
            fontSize: 14.sp,
            color: AppColors.darkblue43,
            fontWeight: FontWeight.w400,
            height: 1.48,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          item.phone,
          style: AppTextStyles.roboto(
            fontSize: 14.sp,
            color: AppColors.darkblue43,
            fontWeight: FontWeight.w400,
            height: 1.48,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  "assets/Icons/svg/history/history.svg",
                  height: 17.h,
                  width: 15.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${item.sharingCount} Sharing Leads',
                  style: AppTextStyles.roboto(
                    fontSize: 12.sp,
                    color: AppColors.darkblue43,
                    fontWeight: FontWeight.w500,
                    height: 1.48,
                  ),
                ),
              ],
            ),
            HistoryStatusBadge(status: item.status),
          ],
        ),

        // DOWNLOAD BUTTON
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          height: 40.h,
          child: OutlinedButton.icon(
            onPressed: item.isDownloaded
                ? null
                : () async {
                    // 1. Show starting message
                    SnackbarHelper.showWarning(context, "Starting download...");

                    // 2. Wait for the controller to download the file and return the path
                    final filePath = await ref
                        .read(cartControllerProvider.notifier)
                        .downloadLeads(item.orderId);

                    // 3. If it succeeded, show the Success SnackBar with an "OPEN" button
                    if (filePath != null && context.mounted) {
                      // Hide the "Starting download..." snackbar immediately
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                      // Show the success snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "File saved to Downloads!",
                            style: AppTextStyles.roboto(
                              fontSize: 13.sp,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: const Color(0xFF4CAF50), // Green
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          duration: const Duration(seconds: 15),

                          // ✅ Add the "OPEN" action button
                          action: SnackBarAction(
                            label: "OPEN",
                            textColor: Colors.white,
                            onPressed: () {
                              OpenFilex.open(filePath);
                            },
                          ),
                        ),
                      );
                    }
                  },
            icon: Icon(
              Icons.download_rounded,
              size: 20.r,
              color: item.isDownloaded ? Colors.grey[400] : AppColors.color159,
            ),
            label: Text(
              item.isDownloaded ? "Already Downloaded" : "Download Leads",
              style: AppTextStyles.roboto(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: item.isDownloaded
                    ? Colors.grey[400]
                    : AppColors.color159,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: item.isDownloaded
                    ? Colors.grey[300]!
                    : AppColors.color159,
                width: 1.5,
              ),
              backgroundColor: item.isDownloaded
                  ? Colors.grey[100]
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
