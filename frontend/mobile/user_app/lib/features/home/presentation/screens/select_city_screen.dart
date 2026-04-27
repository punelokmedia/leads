import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; 
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/home/domain/lead_category.dart';
import 'package:user_app/features/home/infra/city_controller.dart';
import 'package:user_app/features/home/shared/home_providers.dart';

class SelectCityScreen extends HookConsumerWidget { 
  const SelectCityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final cities = ref.watch(cityListProvider);
    final searchQuery = ref.watch(citySearchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "Select City",
          style: AppTextStyles.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            fontSize: 24.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            height: 57.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.grey163, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.25),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    ref.read(citySearchProvider.notifier).state = value;
                  },
                  style: AppTextStyles.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: '', 
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 25.w),
                    suffixIcon: Padding(
                      padding: EdgeInsets.only(right: 20.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.close, size: 20.r, color: Colors.grey),
                              onPressed: () {
                                searchController.clear();
                                ref.read(citySearchProvider.notifier).state = "";
                              },
                            ),
                          SvgPicture.asset(
                            "assets/Icons/svg/home/search_icon.svg",
                            width: 19.w,
                            height: 19.h,
                            colorFilter: const ColorFilter.mode(
                              AppColors.grey102,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (searchQuery.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.w),
                    child: IgnorePointer(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppColors.grey102,
                            AppColors.black,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Search...',
                          style: AppTextStyles.poppins(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: cities.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(top: 50.h),
                    child: Center(child: Text("No cities found for '$searchQuery'")),
                  )
                : (() {
                    // Flatten list for ListView.builder
                    final List<dynamic> items = [];
                    final popular = cities.where((e) => e.isPopular).toList();
                    final others = cities.where((e) => !e.isPopular).toList();

                    if (popular.isNotEmpty) {
                      items.add("Popular");
                      items.addAll(popular);
                    }
                    if (others.isNotEmpty) {
                      items.add("City Leads");
                      items.addAll(others);
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        bottom: MediaQuery.paddingOf(context).bottom + 90.h,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is String) {
                          return _buildHeader(item);
                        }
                        return _CityTile(item: item as LeadCategory);
                      },
                    );
                  })(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text(
        title,
        style: AppTextStyles.poppins(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF555555),
        ),
      ),
    );
  }
}

class _CityTile extends ConsumerWidget {
  final LeadCategory item;
  const _CityTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final cityName = item.title.split(' ').first;
        ref.read(homeControllerProvider.notifier).loadLeads(city: cityName, categoryId: ""); 
        context.go(AppRouter.homePath);
      },

      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.iconColor.withOpacity(0.1),
                border: Border.all(color: item.iconColor, width: 1.5),
              ),
              child: Icon(
                item.iconPath == 'reels_icon'
                    ? Icons.play_circle_fill
                    : Icons.location_on,
                color: item.iconColor,
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: AppTextStyles.poppins(
                        fontSize: 13.sp,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),

            if (item.newCount != null)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE48B),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Row(
                  children: [
                    Text(
                      "${item.newCount} New",
                      style: AppTextStyles.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B7315),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 14.r,
                      color: const Color(0xFF8B7315),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
