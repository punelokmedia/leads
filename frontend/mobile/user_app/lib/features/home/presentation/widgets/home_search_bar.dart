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
        // ── CITY FILTER CHIP ──
        if (homeState.selectedCity != null && homeState.selectedCity!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
            child: Chip(
              label: Text(
                "City: ${homeState.selectedCity}",
                style: AppTextStyles.poppins(fontSize: 13.sp),
              ),
              backgroundColor: const Color(0xFFFBE48B),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                ref.read(homeControllerProvider.notifier).loadLeads(isReset: true);
              },
            ),
          ),

        // ── SEARCH BAR ──
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          height: 57.h,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.grey163, width: 1),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              TextField(
                controller: controller,
                onChanged: (value) {
                  if (debounce.value?.isActive ?? false) {
                    debounce.value?.cancel();
                  }
                  debounce.value = Timer(const Duration(milliseconds: 500), () {
                    ref.read(homeControllerProvider.notifier).searchLeads(value);
                  });
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: 25.w,
                    top: 18.h, 
                    bottom: 18.h,
                  ),
                  suffixIcon: hasText.value
                      ? GestureDetector(
                          onTap: () {
                            controller.clear(); 
                            ref.read(homeControllerProvider.notifier).searchLeads(""); // Clears Backend
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 15.w),
                            child: Icon(Icons.close, color: Colors.grey, size: 20.r),
                          ),
                        )
                      : null,
                ),
              ),

              // ── Gradient Hint 
              if (!hasText.value)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.w),
                  child: IgnorePointer( 
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.grey102, AppColors.black],
                      ).createShader(bounds),
                      child: Text(
                        'Search...',
                        style: AppTextStyles.poppins(
                          color: Colors.white,
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}