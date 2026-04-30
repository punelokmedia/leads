import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart'; // Make sure AuthPrimaryButton is accessible here
import '../../shared/auth_providers.dart';

class VerifyNumberScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const VerifyNumberScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<VerifyNumberScreen> createState() => _VerifyNumberScreenState();
}

class _VerifyNumberScreenState extends ConsumerState<VerifyNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    // ✅ Pre-fill the controller with the passed phone number
    _phoneCtrl = TextEditingController(text: widget.phoneNumber);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showError(context, 'Please enter a valid mobile number');
      return;
    }

    //Riverpod logic to send OTP
    /*
    await ref.read(authControllerProvider.notifier).sendOtp(
      phoneNumber: _phoneCtrl.text.trim(),
      onSuccess: () => context.push(AppRouter.otpVerificationPath),
    );
    */

    print("Sending OTP to: ${_phoneCtrl.text}");
    final fullPhoneNumber = '+91 ${_phoneCtrl.text.trim()}';
    // Simulate moving to the OTP input screen
    context.push(AppRouter.otpVerificationPath, extra: fullPhoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    // final isLoading = ref.watch(authIsLoadingProvider); // Uncomment when wired up
    final isLoading = false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 25.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verify Your Number',
          style: AppTextStyles.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            height: 20 / 24,
            letterSpacing: 0.01,
          ),
        ),
        titleSpacing: 0, // Aligns title closer to the back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 62.h),

                // ── Subtitle ──
                Text(
                  'We will send you an OTP on\nthis number',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins(
                    fontSize: 20.sp,
                    color: AppColors.grey137,
                    fontWeight: FontWeight.w400,
                    height: 20 / 20,
                    letterSpacing: 0.01,
                  ),
                ),
                SizedBox(height: 42.h),

                // ── Custom Mobile Number Field (Pre-filled) ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: AppTextStyles.poppins(
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '9845 372784',
                      hintStyle: AppTextStyles.poppins(
                        fontSize: 16.sp,
                        color: Colors.grey[400],
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 18.h),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF4522C2),
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+91',
                              style: AppTextStyles.poppins(
                                fontSize: 16.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              width: 1.w,
                              height: 24.h,
                              color: Colors.grey[300],
                            ),
                            SizedBox(width: 8.w),
                          ],
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (v.length < 10) return 'Enter a valid 10-digit number';
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 40.h),

                // ── Send OTP Button ──
                AuthPrimaryButton(
                  label: 'Send OTP',
                  isLoading: isLoading,
                  onTap: _onSendOtp,
                ),

                SizedBox(height: 125.h),

                Image.asset(
                  'assets/Images/login/verify_security.png',
                  height: 145.h,
                ),

                SizedBox(height: 78.h),

                // ── Footer Text ──
                Text(
                  'Your number is safe and\nsecure with us',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins(
                    fontSize: 16.sp,
                    color: AppColors.grey137,
                    fontWeight: FontWeight.w500,
                    height: 20 / 16,
                    letterSpacing: 0.01,
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
