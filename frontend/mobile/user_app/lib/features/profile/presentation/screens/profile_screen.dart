import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/profile/infra/profile_repository.dart';
import 'package:user_app/features/profile/presentation/widgets/profile_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F8),
      body: SafeArea(
        child: Column(
          children: [
            const ProfileAppBar(),

            Expanded(
              child: state.isLoading
                  // ✅ Shimmer is added here
                  ? const ProfileShimmerLoading()
                  : state.errorMessage != null
                  ? Center(child: Text(state.errorMessage!))
                  : profile == null
                  ? const SizedBox()
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: AvatarHeader(profile: profile),
                          ),
                          SizedBox(height: 24.h),
                          Divider(
                            height: 2.h,
                            thickness: 2.h,
                            color: const Color.fromRGBO(224, 224, 224, 1),
                          ),
                          SizedBox(height: 24.h),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Business Details',
                                      style: AppTextStyles.roboto(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey77,
                                        height: 1,
                                        letterSpacing: 0.01,
                                      ),
                                    ),
                                    const EditButton(),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                LabeledCard(
                                  label: 'Business Name',
                                  value: profile.businessName,
                                ),
                                SizedBox(height: 16.h),
                                LabeledCard(
                                  label: 'Address',
                                  value: profile.cityName.isNotEmpty
                                      ? profile.cityName
                                      : profile.address,
                                ),
                                SizedBox(height: 16.h),
                                LabeledCard(
                                  label: 'GST Number',
                                  value: profile.gstNumber,
                                ),
                                SizedBox(height: 30.h),
                                LogoutTile(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (context) =>
                                          const LogoutConfirmationDialog(),
                                    );
                                  },
                                ),
                                SizedBox(height: 40.h),
                                const ProfileIllustration(),
                                SizedBox(height: 40.h),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
