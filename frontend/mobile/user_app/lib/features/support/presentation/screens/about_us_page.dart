import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/features/support/shared/about_us_provider.dart';

class AboutUsPage extends HookConsumerWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appInfoProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VersionSection(),
                    SizedBox(height: 24.h),
                    const PublisherSection(),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              const IllustrationSection(),

              SizedBox(height: 40.h),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.chevron_left,
          color: const Color.fromARGB(255, 135, 136, 134),
          size: 30.sp,
        ),
      ),
      title: Text(
        'About Us',
        style: TextStyle(
          color: AppColors.purple75,
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class VersionSection extends HookConsumerWidget {
  const VersionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider);

    return appInfo.when(
      data: (info) {
        final version = info.version;
        final build = info.buildNumber;
        debugPrint('App Version: $version ($build)');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Version for Android',
              style: TextStyle(
                color: const Color.fromRGBO(45, 45, 45, 1),
                fontSize: 24.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6.h),

            Text(
              'V $version+$build',
              style: TextStyle(
                color: AppColors.purple75,
                fontSize: 22.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      },

      /// 🔄 Loading state
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Version for Android',
            style: TextStyle(
              color: const Color.fromRGBO(45, 45, 45, 1),
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          const Text('Loading...'),
        ],
      ),

      error: (e, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Version for Android',
            style: TextStyle(
              color: const Color.fromRGBO(45, 45, 45, 1),
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Failed to load version',
            style: TextStyle(color: Colors.red, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }
}

class PublisherSection extends HookConsumerWidget {
  const PublisherSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Published by',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16.sp,
            fontWeight: .w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Dash Technologies India Pvt Ltd.',
          style: TextStyle(
            color: AppColors.purple73,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Service provided by',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Dash Technologies Pvt Ltd.',
          style: TextStyle(
            color: AppColors.purple75,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class IllustrationSection extends HookConsumerWidget {
  const IllustrationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Image.asset(
        'assets/Images/profile/bro.png',
        width: 363.w,
        height: 307.h,
        fit: BoxFit.contain,
      ),
    );
  }
}
