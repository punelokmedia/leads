import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/home/shared/home_providers.dart';

class HomeSearchBar extends HookConsumerWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final controller = useTextEditingController(text: homeState.searchQuery);
    final hasText = useState(controller.text.isNotEmpty);
    final debounce = useRef<Timer?>(null);

    useEffect(() {
      return () {
        debounce.value?.cancel();
      };
    }, const []);

    useEffect(() {
      void listener() {
        if (hasText.value != controller.text.isNotEmpty) {
          hasText.value = controller.text.isNotEmpty;
        }
      }
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (homeState.selectedCity != null && homeState.selectedCity!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, bottom: 4.h),
            child: Chip(
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              label: Text(
                "City: ${homeState.selectedCity}",
                style: AppTextStyles.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              backgroundColor: const Color(0xFFF7E9A6),
              side: BorderSide(color: AppColors.color159.withValues(alpha: 0.35)),
              deleteIcon: Icon(Icons.close_rounded, size: 16.r),
              onDeleted: () {
                ref.read(homeControllerProvider.notifier).loadLeads(isReset: true);
              },
            ),
          ),

        Container(
          margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
          height: 54.h,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.grey223),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 14.w),
              Icon(Icons.search_rounded, color: AppColors.grey117, size: 22.r),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (value) {
                    debounce.value?.cancel();
                    debounce.value = Timer(const Duration(milliseconds: 450), () {
                      ref.read(homeControllerProvider.notifier).searchLeads(value);
                    });
                  },
                  style: AppTextStyles.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search leads, city, address...',
                    hintStyle: AppTextStyles.poppins(
                      fontSize: 13.sp,
                      color: AppColors.grey137,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (hasText.value)
                IconButton(
                  onPressed: () {
                    controller.clear();
                    ref.read(homeControllerProvider.notifier).searchLeads("");
                  },
                  icon: Icon(Icons.close_rounded, color: AppColors.grey117, size: 20.r),
                  splashRadius: 18.r,
                )
              else
                SizedBox(width: 10.w),
            ],
          ),
        ),
      ],
    );
  }
}