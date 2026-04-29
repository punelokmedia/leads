// auth/presentation/screens/register_screen.dart

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
import 'package:user_app/features/auth/presentation/widgets/auth_field_widgets.dart';
import 'package:user_app/features/auth/presentation/widgets/payment_bottom_sheet.dart';
import '../../shared/auth_providers.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    String? errorMsg;

    if (_firstNameCtrl.text.trim().isEmpty) {
      errorMsg = "First Name is required";
    } else if (_lastNameCtrl.text.trim().isEmpty) {
      errorMsg = "Last Name is required";
    } else if (_phoneCtrl.text.trim().isEmpty) {
      errorMsg = "Phone Number is required";
    } else if (_phoneCtrl.text.trim().length != 10) {
      errorMsg = "Please enter a valid 10-digit phone number";
    } else if (_emailCtrl.text.trim().isEmpty) {
      errorMsg = "Email ID is required";
    } else if (!_emailCtrl.text.contains('@')) {
      errorMsg = "Please enter a valid email address";
    } else if (_passwordCtrl.text.isEmpty) {
      errorMsg = "Password is required";
    } else if (_passwordCtrl.text.length < 6) {
      errorMsg = "Password must be at least 6 characters";
    } else if (_confirmPasswordCtrl.text != _passwordCtrl.text) {
      errorMsg = "Passwords do not match";
    }

    // 2. If there's an error, show Snackbar and trigger red borders
    if (errorMsg != null) {
      SnackbarHelper.showError(
        context,
        errorMsg,
      ); // Assuming your helper has a showError method
      _formKey.currentState!.validate(); // This makes the textfields turn red
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to resize with content
      backgroundColor: Colors.transparent, // Required to see the rounded corners
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: PaymentBottomSheet(
            userPhone: _phoneCtrl.text.trim(),
            userEmail: _emailCtrl.text.trim(),
            onPaymentSuccess: () async {
              // ✅ THIS ONLY RUNS IF PAYMENT SUCCEEDS
              await ref.read(authControllerProvider.notifier).register(
                    firstname: _firstNameCtrl.text.trim(),
                    lastname: _lastNameCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    phoneNumber: _phoneCtrl.text.trim(),
                    password: _passwordCtrl.text.trim(),
                    onSuccess: (message) {
                      ref.read(authControllerProvider.notifier).clearError();
                      SnackbarHelper.showSuccess(context, message);
                      context.push(AppRouter.login);
                    },
                  );
            },
          ),
        );
      }
    );
  
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F0F0),
              Color(0xFFF0F0F0),
              Color.fromARGB(255, 255, 198, 28),
            ],
            stops: [0.40, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Replace with Image.asset('assets/images/logo.png') if available
                        Container(
                          width: 169.w,
                          height: 56.h,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/Images/home/logo_leads.png',
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title
                  Center(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Center(
                    child: Text(
                      'Almost there , just sign up!',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Error banner
                  if (error != null) ...[
                    AuthErrorBanner(message: error),
                    SizedBox(height: 12.h),
                  ],

                  // First Name
                  AuthTextField(
                    label: 'First Name',
                    hint: 'Angad',
                    controller: _firstNameCtrl,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 14.h),

                  // Last Name
                  AuthTextField(
                    label: 'Last Name',
                    hint: 'Khanna',
                    controller: _lastNameCtrl,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 14.h),

                  // Phone Number
                  AuthTextField(
                    label: 'Phone Number',
                    hint: '7777777777',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    // Force only digits to be entered
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Required';
                      }
                      // Regex to ensure exactly 10 digits
                      final phoneRegExp = RegExp(r'^\d{10}$');
                      if (!phoneRegExp.hasMatch(v)) {
                        return 'Please enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Email
                  AuthTextField(
                    label: 'Email ID',
                    hint: 'johndoe@gmail.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Password
                  PasswordField(
                    controller: _passwordCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Confirm Password
                  PasswordField(
                    label: 'Confirm Password',
                    hint: '••••••••',
                    controller: _confirmPasswordCtrl,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != _passwordCtrl.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),

                  // Remember me
                  Row(
                    children: [
                      SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: const Color(0xFFFFC107),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Remember me',
                        style: AppTextStyles.poppins(
                          fontSize: 14.sp,
                          color: AppColors.grey77,
                          height: 20 / 14,
                          letterSpacing: 0.1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Sign Up button
                  AuthPrimaryButton(
                    label: 'Proceed to Pay',
                    isLoading: isLoading,
                    onTap: _onRegister,
                  ),
                  SizedBox(height: 20.h),

                  // Login link
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.poppins(
                            fontSize: 14.sp,
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                            height: 20 / 14,
                            letterSpacing: 0.1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(authControllerProvider.notifier)
                                .clearError();
                            context.pop();
                          },
                          child: Text(
                            'Login',
                            style: AppTextStyles.poppins(
                              fontSize: 14.sp,
                              color: AppColors.red237,
                              fontWeight: FontWeight.w500,
                              height: 20 / 14,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
