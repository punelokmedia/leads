// features/auth/presentation/widgets/city_list_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class CityListItemWidget extends StatelessWidget {
  final String cityName;
  final bool isCurrentLocation;
  final bool isSelected;
  final VoidCallback onTap;

  const CityListItemWidget({
    super.key,
    required this.cityName,
    this.isCurrentLocation = false,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Makes the whole row clickable
      child: Row(
        children: [
          // ── Icon ──
          if (isCurrentLocation)
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: const Color(0xFF4522C2), // Deep purple background
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(Icons.my_location, color: Colors.white, size: 16.r),
            )
          else
            Icon(Icons.location_on_outlined, color: Colors.grey[400], size: 24.r),
          
          SizedBox(width: 16.w),

          // ── City Name ──
          Expanded(
            child: Text(
              cityName,
              style: AppTextStyles.poppins(
                fontSize: 15.sp,
                color: Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),

          // ── Custom Radio Button ──
          Container(
            width: 20.r,
            height: 20.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF4522C2) : Colors.grey[400]!,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purple73, // Inner purple dot
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}