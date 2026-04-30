import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class UserProfile {
  final String name;
  final String role;
  final String location;
  final String businessName;
  final String phone;
  final String gst;
  final String? avatarUrl;
  final String email;

  const UserProfile({
    required this.name,
    required this.role,
    required this.location,
    required this.businessName,
    required this.phone,
    required this.gst,
    this.avatarUrl,
    required this.email,
  });
}

final profileProvider = FutureProvider<UserProfile>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return const UserProfile(
    name: 'Rohit Sharma',
    role: 'Interior Designer',
    location: 'Mumbai, Maharashtra',
    businessName: 'Sharma Interior Works',
    phone: '+91 98765 43210',
    gst: '27AABCS1429B1Z6',
    email: 'rohitsharma@info.com',
  );
});

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238), // lavender bg
      body: SafeArea(
        child: Column(
          children: [
            _ProfileAppBar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (profile) => _ProfileBody(profile: profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfileAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: Center(
        child: Text(
          'My Profile',
          style: AppTextStyles.poppins(
            fontSize: 22.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          _AvatarHeader(profile: profile),

          SizedBox(height: 28.h),
          Divider(
            height: 0.5.h,
            color: const Color.fromARGB(255, 137, 133, 133),
          ),
          SizedBox(height: 28.h),

          Row(
            children: [
              Text(
                'Business Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(width: 28.h),
              _EditButton(),
            ],
          ),

          SizedBox(height: 16.h),

          _LabeledCard(label: 'Business Name', value: profile.businessName),
          SizedBox(height: 14.h),
          _LabeledCard(label: 'Address', value: profile.location),
          SizedBox(height: 14.h),
          _LabeledCard(label: 'GST Number', value: profile.gst),

          SizedBox(height: 28.h),

          _LogoutTile(),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FCF),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(width: 6.w),
          Icon(Icons.edit_outlined, size: 14.r, color: Colors.white),
        ],
      ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final UserProfile profile;
  const _AvatarHeader({required this.profile});

  String get _initials {
    final parts = profile.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5B4FCF), width: 2.5),
          ),
          child: CircleAvatar(
            radius: 36.r,
            backgroundColor: const Color(0xFFEEEDFE),
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    _initials,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF534AB7),
                      fontFamily: 'Poppins',
                    ),
                  )
                : null,
          ),
        ),

        SizedBox(width: 16.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Color.fromRGBO(28, 8, 99, 1),
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                profile.phone,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B5ECD),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                profile.location,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                profile.email,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledCard extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: const Color(0xFFE24B4A),
              size: 22.r,
            ),
            SizedBox(width: 12.w),
            Text(
              'Logout',
              style: TextStyle(
                color: const Color(0xFFE24B4A),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
