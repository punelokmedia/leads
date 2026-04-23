import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/profile/presentation/widgets/profile_form_fields.dart';
import '../../shared/edit_profile_providers.dart';
import '../widgets/edit_profile_form_fields.dart' hide FormLabel;
import '../widgets/edit_profile_widgets.dart' hide EditProfileAvatar, UpdateButton;

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(editProfileControllerProvider.notifier).loadProfile());
  }

  void _snack(String msg, {bool isError = false}) {
    if (isError) {
      SnackbarHelper.showError(context, msg);
    } else {
      SnackbarHelper.showSuccess(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(editProfileIsLoadingProvider);
    final isUpdating = ref.watch(editProfileIsUpdatingProvider);
    final profile = ref.watch(editProfileDataProvider);
    final obscure = ref.watch(editProfileObscurePasswordProvider);
    final notifier = ref.read(editProfileControllerProvider.notifier);

    ref.listen(editProfileSuccessProvider, (_, msg) { if (msg != null) _snack(msg); });
    ref.listen(editProfileErrorProvider, (_, err) { if (err != null) _snack(err); });

    if (isLoading || profile == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))));
    }

    

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.grey241,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r, color: AppColors.grey77),
        ),
        title: Text('My Account',
            style: AppTextStyles.poppins(fontSize: 24.sp,
                fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F0F0), Color(0xFFF0F0F0), Color.fromARGB(255, 255, 198, 28)],
            stops: [0.50, 0.40, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.h,
            left: 20.w, right: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditProfileAvatar(avatarUrl: null, onEditTap: () {}),
              SizedBox(height: 24.h),
              Row(children: [
                Expanded(child: _labeled('First Name',
                    ProfileTextField(hint: 'First name', initialValue: profile.firstName,
                        onChanged: (v) => notifier.updateField(profile.copyWith(firstName: v))))),
                SizedBox(width: 12.w),
                Expanded(child: _labeled('Last Name',
                    ProfileTextField(hint: 'Last name', initialValue: profile.lastName,
                        onChanged: (v) => notifier.updateField(profile.copyWith(lastName: v))))),
              ]),
              SizedBox(height: 16.h),
              _labeled('Mobile Number', MobileNumberField(
                countryCode: profile.countryCode, phone: profile.phone,
                onPhoneChanged: (v) => notifier.updateField(profile.copyWith(phone: v)),
                onCodeChanged: (v) => notifier.updateField(profile.copyWith(countryCode: v)),
              )),
              SizedBox(height: 16.h),
              _labeled('Email ID', ProfileTextField(
                hint: 'Email', initialValue: profile.email,
                keyboardType: TextInputType.emailAddress, readOnly: true)),
              SizedBox(height: 16.h),
              _labeled('Password', PasswordWithChangeButton(
                obscure: obscure,
                onChangeTap: () => context.push(AppRouter.changePasswordPath),
              )),
              SizedBox(height: 41.h),
              AddAddressRow(onTap: () => context.push(AppRouter.addAddressPath)),
              SizedBox(height: 32.h),
              UpdateButton(isLoading: isUpdating,
                  onTap: () => notifier.submitUpdate(() => context.pop())),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  //Inline label helper 
  Widget _labeled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [FormLabel(text: label), SizedBox(height: 6.h), field],
      );
}