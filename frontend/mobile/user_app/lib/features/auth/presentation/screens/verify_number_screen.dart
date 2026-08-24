// features/auth/presentation/screens/verify_number_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import '../../shared/auth_providers.dart';

class VerifyNumberScreen extends ConsumerStatefulWidget {
  
  final bool isGoogleAuth;
  final String phoneNumber;
  final String googleToken;

  const VerifyNumberScreen({
    super.key,
    required this.isGoogleAuth,
    required this.phoneNumber,
    required this.googleToken,
  });

  @override
  ConsumerState<VerifyNumberScreen> createState() => _VerifyNumberScreenState();
}

class _VerifyNumberScreenState extends ConsumerState<VerifyNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    
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

    final phone = _phoneCtrl.text.trim();
    print("Sending OTP to: $phone");

    // ── Call the API via Riverpod Controller based on Auth Type ──
    if (widget.isGoogleAuth) {
      
      await ref.read(authControllerProvider.notifier).requestOtpSession(
        phoneNumber: phone,
        token: widget.googleToken,
        onSuccess: (String otpCode) {
          print("Google OTP Sent successfully! Code is: $otpCode");
          
         
          context.push(
            AppRouter.otpVerificationPath,
            extra: {
              'isGoogle': true,
              'phone': phone,
              'token': widget.googleToken,
            },
          );
        },
      );
    } else {
      
      await ref.read(authControllerProvider.notifier).sendOtp(
        phoneNumber: phone,
        onSuccess: (String otpCode) {
          print("Standard OTP Sent successfully! Code is: $otpCode");
          
          context.push(
            AppRouter.otpVerificationPath,
            extra: {
              'isGoogle': false,
              'phone': phone,
              'token': '', 
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final isLoading = ref.watch(authIsLoadingProvider);

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
        titleSpacing: 0,
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

                // ── Custom Mobile Number Field ──
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
                      if (v == null || v.isEmpty) return 'Mobile number is required';
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
                  errorBuilder: (_, _, _) => Icon(
                    Icons.verified_user_outlined,
                    size: 80.r,
                    color: AppColors.purple73,
                  ),
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