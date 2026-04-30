import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/home/domain/city_model.dart';
import 'package:user_app/features/home/shared/city_provider.dart';

Future<CityModel?> showCityPickerSheet(BuildContext context) {
  return showModalBottomSheet<CityModel?>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CityPickerSheet(),
  );
}

class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet();

  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(citySearchQueryProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectCity(CityModel? city) {
    ref.read(selectedCityProvider.notifier).state = city;

    Navigator.of(context).pop(city);
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredCityListProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Text(
                      'Select City',
                      style: AppTextStyles.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16.r,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      ref.read(citySearchQueryProvider.notifier).state = v,
                  style: AppTextStyles.poppins(
                    fontSize: 13.sp,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search city…',
                    hintStyle: AppTextStyles.poppins(
                      fontSize: 13.sp,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.purple72,
                      size: 20.r,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              ref.read(citySearchQueryProvider.notifier).state =
                                  '';
                            },
                            child: Icon(
                              Icons.clear_rounded,
                              size: 18.r,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.purple72,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              const Divider(height: 1),

              Expanded(
                child: filteredAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 40.r,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Could not load cities.\nCheck your connection.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.poppins(
                            fontSize: 13.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextButton(
                          onPressed: () => ref.invalidate(cityListProvider),
                          child: Text(
                            'Retry',
                            style: AppTextStyles.poppins(
                              fontSize: 13.sp,
                              color: AppColors.purple72,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (cities) {
                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(vertical: 4.h),

                      itemCount: cities.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          final isSelected = selectedCity == null;
                          return _CityTile(
                            icon: Icons.public_rounded,
                            iconColor: AppColors.purple72,
                            label: 'All Cities',
                            isSelected: isSelected,
                            onTap: () => _selectCity(null),
                          );
                        }

                        final city = cities[i - 1];
                        final isSelected = selectedCity?.id == city.id;

                        return _CityTile(
                          icon: Icons.location_on_rounded,
                          iconColor: _cityColor(i - 1),
                          label: city.displayName,
                          isSelected: isSelected,
                          onTap: () => _selectCity(city),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _cityColor(int index) {
    const palette = [
      Color(0xFF0099FF),
      Color(0xFF2DC653),
      Color(0xFFFF6B2C),
      Color(0xFFE63946),
      Color(0xFFFFB800),
      Color(0xFF7B2FBE),
      Color(0xFF00B8D9),
      Color(0xFF8B4513),
    ];
    return palette[index % palette.length];
  }
}

class _CityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? AppColors.purple72.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: iconColor, size: 18.r),
            ),
            SizedBox(width: 14.w),

            Expanded(
              child: Text(
                label,
                style: AppTextStyles.poppins(
                  fontSize: 13.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.purple72 : Colors.black87,
                ),
              ),
            ),

            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.purple72,
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }
}
