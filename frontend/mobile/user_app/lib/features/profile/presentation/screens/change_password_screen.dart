import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import '../widgets/edit_profile_widgets.dart';
import '../../shared/edit_profile_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _existingPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _existingPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(editProfileControllerProvider.notifier)
        .changePassword(
          current: _existingPasswordCtrl.text.trim(),
          newPass: _newPasswordCtrl.text.trim(),
          onSuccess: () {
            SnackbarHelper.showSuccess(
              context,
              "Password updated successfully",
            );
            context.pop();
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileControllerProvider);

    ref.listen(editProfileErrorProvider, (_, err) {
      if (err != null) {
        SnackbarHelper.showError(context, err);

        Future.microtask(
          () =>
              ref.read(editProfileControllerProvider.notifier).clearMessages(),
        );
      }
    });

    ref.listen<String?>(editProfileSuccessProvider, (_, msg) {
      if (msg != null) {
        SnackbarHelper.showSuccess(context, msg);

        Future.microtask(
          () =>
              ref.read(editProfileControllerProvider.notifier).clearMessages(),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 18.r,
          ),
        ),
        title: Text(
          'Change Password',
          style: AppTextStyles.poppins(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Existing Password
                    _FieldLabel(text: 'Existing Password'),
                    SizedBox(height: 6.h),
                    ChangePasswordField(
                      controller: _existingPasswordCtrl,
                      hintText: 'Enter existing password',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: 20.h),

                    // New Password
                    _FieldLabel(text: 'New Password'),
                    SizedBox(height: 6.h),
                    ChangePasswordField(
                      controller: _newPasswordCtrl,
                      hintText: 'Enter new password',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Confirm Password
                    _FieldLabel(text: 'Confirm Password'),
                    SizedBox(height: 6.h),
                    ChangePasswordField(
                      controller: _confirmPasswordCtrl,
                      hintText: 'Confirm your password',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != _newPasswordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 36.h),

                    // Illustration
                    Center(
                      child: Image.asset(
                        'assets/images/change_password_illustration.png',
                        height: 200.h,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => SizedBox(height: 200.h),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            Center(
              child: Image.asset(
                'assets/Images/profile/change_password_illustration.png',
                height: 180.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20.h),

            // ── Update button at bottom ───────────────────────────
            Container(
              color: const Color(0xFFF7F7F7),
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                bottom: MediaQuery.of(context).padding.bottom + 16.h,
                top: 8.h,
              ),
              child: UpdateButton(
                isLoading: state.isChangingPassword,
                onTap: state.isChangingPassword ? null : _onUpdate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Private label widget for this screen
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
        letterSpacing: 0.1,
        height: 20 / 18,
      ),
    );
  }
}
