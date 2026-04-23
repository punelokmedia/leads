import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
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
    // ✅ 1. Determine if it's sold out
    final isSoldOut = lead.status == 'SOLD_OUT';

    return Container(
      width: 370.w,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF898989)),
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
  final bool isSoldOut; // ✅ Added property to track status

  const _LeadImage({
    required this.imageUrl,
    required this.isSoldOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        // ✅ 3. Use a Stack to layer the images
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Bottom Layer: The Main Network Image
            Image.network(
              imageUrl,
              height: 223.h,
              width: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 700,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Container(
                height: 223.h,
                color: AppColors.grey102,
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
            ),

            // Top Layer: The Sold Out Stamp (Only shows if isSoldOut is true)
            if (isSoldOut) ...[
              // Optional: A slight white tint over the photo to make the red stamp pop
              Container(
                height: 223.h,
                width: double.infinity,
                color: Colors.white.withOpacity(0.5), 
              ),
              
              // The actual stamp image
              Image.asset(
                "assets/Images/home/sold_out.png", // ⚠️ Change this to your exact image path!
                width: 140.w, // Adjust the size of the stamp here
                fit: BoxFit.contain,
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
          Text(
            lead.title,
            style: AppTextStyles.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: AppColors.black,
              height: 20/16,
              letterSpacing: 0.1
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${lead.description} – \n${lead.address}',
            style: AppTextStyles.poppins(
              fontSize: 14.sp, 
              color: AppColors.black,
              height: 19/14,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w400
            ),
          ),
          SizedBox(height: 8.h),

          Container(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                SvgPicture.asset(
                  "assets/Icons/svg/history/history.svg",
                  height: 17.h,
                  width: 15.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '${lead.sharingCount} Sharing Leads',
                  style: AppTextStyles.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF444444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
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
                          fontSize: 14.sp,
                          color: AppColors.red237,
                          fontWeight: FontWeight.w700,
                          height: 16/14,
                          letterSpacing: 0.1,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '₹${lead.discountedPrice.toStringAsFixed(0)}/-',
                        style: AppTextStyles.poppins(
                          fontSize: 14.sp,
                          color: AppColors.green49, 
                          fontWeight: FontWeight.w700,
                          height: 16/14,
                          letterSpacing: 0.1
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 15.h),
                  Text(
                    lead.date,
                    style: AppTextStyles.poppins(
                      fontSize: 14.sp, 
                      color: AppColors.grey137
                    ),
                  ),
                ],
              ),
              _CartButton(
                quantity: cartQuantity,
                maxQuantity: lead.sharingCount, 
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                isSoldOut: lead.status == 'SOLD_OUT', // ✅ Pass the status down
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── REDESIGNED CART BUTTON ──────────────────────────────────────────────────
class _CartButton extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool isSoldOut; // ✅ New variable to track status

  const _CartButton({
    required this.quantity,
    required this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
    this.isSoldOut = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 1. Sold Out State (Gray Disabled Button)
    if (isSoldOut) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Sold Out',
          style: AppTextStyles.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 15.sp,
            letterSpacing: 0.1,
            height: 15 / 14,
          ),
        ),
      );
    }

    // 2. Empty Cart State (Add to Cart Button)
    if (quantity <= 0) {
      return GestureDetector(
        onTap: () {
          if (maxQuantity > 0) {
            onIncrement?.call(); // ✅ Safely call if not null
          } else {
            SnackbarHelper.showWarning(context, "No sharing leads available.");
          }
        },
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.green49),
            borderRadius: BorderRadius.circular(10.r),
            gradient: const LinearGradient(
              colors: [Color(0xFF62CB66), Color(0xFF49A54D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Add to Cart',
            style: AppTextStyles.poppins(
              color: AppColors.white,
              fontWeight: FontWeight.w400,
              fontSize: 15.sp,
              letterSpacing: 0.1,
              height: 15 / 14,
            ),
          ),
        ),
      );
    }

    // 3. Active State (Plus / Minus Buttons)
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
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              child: Icon(Icons.remove, size: 20.r, color: AppColors.green49),
            ),
          ),
          
          // ── Count Text ──
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
          
          // ── Plus Button ──
          InkWell(
            onTap: quantity < maxQuantity ? onIncrement : () {
              SnackbarHelper.showWarning(context,"Only $maxQuantity shares available for this lead.");
            },
            borderRadius: BorderRadius.horizontal(right: Radius.circular(8.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              child: Icon(
                Icons.add,
                size: 20.r,
                color: quantity < maxQuantity ? AppColors.green49 : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}