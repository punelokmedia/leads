// features/auth/presentation/screens/tell_us_about_yourself_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import 'package:user_app/features/auth/presentation/widgets/profile_form_widgets.dart'; // Import reusable widgets
import '../../shared/auth_providers.dart'; // Update path if needed

// ✅ Converted to ConsumerStatefulWidget for Riverpod
class TellUsAboutYourselfScreen extends ConsumerStatefulWidget {
  const TellUsAboutYourselfScreen({super.key});

  @override
  ConsumerState<TellUsAboutYourselfScreen> createState() => _TellUsAboutYourselfScreenState();
}

class _TellUsAboutYourselfScreenState extends ConsumerState<TellUsAboutYourselfScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Pre-filled controllers as requested
  final _nameCtrl = TextEditingController(); 
  final _bizCtrl = TextEditingController(); 
  final _emailCtrl = TextEditingController(); 
  final _cityCtrl = TextEditingController(); 
  
  String? _selectedWorkType;
  final List<String> _workTypeOptions = ["Carpenter", "Interior"];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bizCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate() || _selectedWorkType == null) {
      SnackbarHelper.showError(context, 'Please fill all details and select a Work Type.');
      return;
    }

    // Access Riverpod Provider here to save data to backend
    /*
    await ref.read(authControllerProvider.notifier).updateProfile(
      name: _nameCtrl.text,
      company: _bizCtrl.text,
      email: _emailCtrl.text,
      city: _cityCtrl.text,
      workType: _selectedWorkType!,
    );
    */
    
    print("Profile Updated! Routing to Home...");
    context.go(AppRouter.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider); // Listen to loading state

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tell us about yourself',
          style: AppTextStyles.poppins(fontSize: 24.sp, fontWeight: FontWeight.w600, color: AppColors.black,height: 20/24,letterSpacing: 0.01),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10.h),
                
                // ── Subtitle ──
                Text(
                  'We need a few details to\nset up your account',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.poppins(fontSize: 14.sp, color: AppColors.grey77),
                ),
                SizedBox(height: 35.h),

                // ── Reusable Form Fields ──
                CustomProfileTextField(
                  label: 'Full Name',
                  hintText: 'Enter full name',
                  controller: _nameCtrl,
                  floatingLabelColor: const Color(0xFF4FA8FF), // Light blue label from design
                ),
                SizedBox(height: 20.h),

                CustomProfileTextField(
                  label: 'Business / Company Name',
                  hintText: 'Enter company name',
                  controller: _bizCtrl,
                ),
                SizedBox(height: 20.h),

                CustomProfileTextField(
                  label: 'Email',
                  hintText: 'Enter email address',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20.h),

                CustomProfileTextField(
                  label: 'City',
                  hintText: 'Enter city name',
                  controller: _cityCtrl,
                ),
                SizedBox(height: 20.h),

                // ── Real Native Dropdown ──
                CustomProfileDropdown(
                  label: 'Select Work Type',
                  hintText: 'Select Work Type',
                  value: _selectedWorkType,
                  items: _workTypeOptions,
                  onChanged: (String? newValue) {
                    setState(() => _selectedWorkType = newValue);
                  },
                ),
                SizedBox(height: 60.h), 

                // ── Continue Button ──
                AuthPrimaryButton(
                  label: 'Continue',
                  isLoading: isLoading,
                  onTap: _onContinue,
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