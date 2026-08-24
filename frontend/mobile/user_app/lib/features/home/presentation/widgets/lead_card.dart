import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/core/widgets/app_network_image.dart';
import 'package:user_app/features/home/domain/leads_model.dart';

class LeadCard extends StatelessWidget {
  final LeadModel lead;
  final int cartQuantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const LeadCard({
    super.key,
    required this.lead,
    required this.cartQuantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = lead.status == 'SOLD_OUT';

    return Container(
      width: 370.w,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey223),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeadImage(
            imageUrl: lead.imageUrl,
            isSoldOut: isSoldOut,
          ),
          _LeadCardBody(
            lead: lead,
            cartQuantity: cartQuantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ],
      ),
    );
  }
}

class _LeadImage extends StatelessWidget {
  final String imageUrl;
  final bool isSoldOut;

  const _LeadImage({
    required this.imageUrl,
    required this.isSoldOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppNetworkImage(
              url: imageUrl,
              height: 190.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: Container(
                height: 190.h,
                color: AppColors.grey102,
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
            ),

            if (isSoldOut) ...[
              Container(
                height: 190.h,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              Center(
                child: Image.asset(
                  "assets/Images/home/sold_out.png",
                  width: 124.w,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeadCardBody extends StatelessWidget {
  final LeadModel lead;
  final int cartQuantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const _LeadCardBody({
    required this.lead,
    required this.cartQuantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: AppColors.black,
                    height: 1.3,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.white239,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12.r,
                      color: AppColors.grey117,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      lead.city,
                      style: AppTextStyles.poppins(
                        fontSize: 11.sp,
                        color: AppColors.grey117,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            lead.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.poppins(
              fontSize: 13.sp,
              color: AppColors.grey77,
              height: 1.45,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            lead.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.poppins(
              fontSize: 12.sp,
              color: AppColors.grey117,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          SizedBox(height: 10.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: AppColors.white239,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  "assets/Icons/svg/history/history.svg",
                  height: 15.h,
                  width: 14.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${lead.sharingCount} Sharing Leads',
                  style: AppTextStyles.poppins(
                    fontSize: 12.sp,
                    color: AppColors.darkblue43,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹ ${lead.originalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.poppins(
                          fontSize: 12.sp,
                          color: AppColors.red237,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: 0.1,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.red237,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '₹${lead.discountedPrice.toStringAsFixed(0)}/-',
                        style: AppTextStyles.poppins(
                          fontSize: 17.sp,
                          color: AppColors.green49,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    lead.date,
                    style: AppTextStyles.poppins(
                      fontSize: 12.sp,
                      color: AppColors.grey137,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _CartButton(
                quantity: cartQuantity,
                maxQuantity: lead.sharingCount,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                isSoldOut: lead.status == 'SOLD_OUT',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool isSoldOut;

  const _CartButton({
    required this.quantity,
    required this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
    this.isSoldOut = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSoldOut) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.grey[500],
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          'Sold Out',
          style: AppTextStyles.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            letterSpacing: 0.1,
            height: 1.1,
          ),
        ),
      );
    }

    if (quantity <= 0) {
      return GestureDetector(
        onTap: () {
          if (maxQuantity > 0) {
            onIncrement?.call();
          } else {
            SnackbarHelper.showWarning(context, "No sharing leads available.");
          }
        },
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.green49, width: 1.1),
            borderRadius: BorderRadius.circular(10.r),
            color: AppColors.green49,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Add to Cart',
            style: AppTextStyles.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              letterSpacing: 0.1,
              height: 1.1,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.green49, width: 1.5),
        borderRadius: BorderRadius.circular(10.r),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(8.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Icon(Icons.remove, size: 19.r, color: AppColors.green49),
            ),
          ),

          Container(
            constraints: BoxConstraints(minWidth: 24.w),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: AppTextStyles.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),

          InkWell(
            onTap: quantity < maxQuantity
                ? onIncrement
                : () {
                    SnackbarHelper.showWarning(
                      context,
                      "Only $maxQuantity shares available for this lead.",
                    );
                  },
            borderRadius: BorderRadius.horizontal(right: Radius.circular(8.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Icon(
                Icons.add,
                size: 19.r,
                color: quantity < maxQuantity ? AppColors.green49 : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}