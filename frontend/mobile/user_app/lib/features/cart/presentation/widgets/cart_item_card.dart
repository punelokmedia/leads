import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/widgets/app_network_image.dart';
import '../../domain/cart_model.dart';

class CartItemCard extends StatelessWidget {
  final CartLead item;
  final VoidCallback onDelete;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleSelect;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onAddToCart,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24.r,
        ), // Pill-shaped outer container
        border: Border.all(
          color: const Color(0xFFE8C84A).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: AppNetworkImage(
                  url: item.imageUrl,
                  width: 56.r,
                  height: 50.r,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 56.r,
                    height: 50.r,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.home_outlined,
                      size: 28.r,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Interior Leads", 
                      style: AppTextStyles.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.location,
                      style: AppTextStyles.roboto(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey137,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          
            ],
          ),
          SizedBox(height: 12.h),

          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1), 
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow
                            .ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    Text(
                      item.time,
                      style: AppTextStyles.roboto(
                        fontSize: 10.sp,
                        color:AppColors.grey94,
                        fontWeight: FontWeight.w500,
                        height: 0.148
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Address
                Text(
                  item.address,
                  style: AppTextStyles.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black37,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: 14.h),

                // Bottom Row: Lead Count and Action Buttons
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 18.r,
                      color: Colors.black45,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${item.sharingCount} Sharing Leads',
                      style: AppTextStyles.roboto(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                        height: 0.148
                      ),
                    ),

                    const Spacer(),

                    // Delete Button
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.red237,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: AppTextStyles.poppins(
                            color: AppColors.red237,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
