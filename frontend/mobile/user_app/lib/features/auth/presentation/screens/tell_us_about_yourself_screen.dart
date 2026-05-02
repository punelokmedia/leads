// features/auth/presentation/screens/tell_us_about_yourself_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/infra/category_repository.dart';
import 'package:user_app/features/auth/infra/city_repository.dart';
import '../../shared/profile_draft_provider.dart';

class TellUsAboutYourselfScreen extends ConsumerStatefulWidget {
  const TellUsAboutYourselfScreen({super.key});

  @override
  ConsumerState<TellUsAboutYourselfScreen> createState() =>
      _TellUsAboutYourselfScreenState();
}

class _TellUsAboutYourselfScreenState
    extends ConsumerState<TellUsAboutYourselfScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _bizCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _selectedCity;
  String? _selectedCityId;
  String? _selectedWorkType;

  final List<String> _fallbackCities = ["Mumbai", "Delhi", "Bengaluru", "Pune"];
  final List<String> _fallbackWorkTypes = [
    "Carpenter",
    "Interior",
    "Plumber",
    "Electrician",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(profileDraftProvider);
      if (draft.fullName.isNotEmpty) _nameCtrl.text = draft.fullName;
      if (draft.email.isNotEmpty) _emailCtrl.text = draft.email;
      if (draft.businessName.isNotEmpty) _bizCtrl.text = draft.businessName;
      if (draft.city.isNotEmpty) {
        setState(() {
          _selectedCity = draft.city;
          _selectedCityId = draft.cityId;
        });
      }
      if (draft.workType.isNotEmpty) {
        setState(() => _selectedWorkType = draft.workType);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bizCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_nameCtrl.text.trim().isEmpty ||
        _bizCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _selectedCity == null ||
        _selectedWorkType == null) {
      SnackbarHelper.showError(
        context,
        'Please fill all details and select a City & Work Type.',
      );
      return;
    }

    if (!_emailCtrl.text.contains('@')) {
      SnackbarHelper.showError(context, 'Please enter a valid email address.');
      return;
    }

    ref
        .read(profileDraftProvider.notifier)
        .updateBasicDetails(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          businessName: _bizCtrl.text.trim(),
          city: _selectedCity!,
          cityId: _selectedCityId ?? '',
          workType: _selectedWorkType!,
        );

    context.push(AppRouter.chooseWorkCityPath);
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F0FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tell us about yourself',
          style: AppTextStyles.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16.h),

                // ── Avatar Upload ──
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 90.r,
                      height: 90.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6CCFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50.r,
                        color: const Color(0xFF9B8FCC),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple73,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Upload',
                              style: AppTextStyles.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 14.r,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // ── Full Name ──
                _buildLabel('Full Name'),
                SizedBox(height: 6.h),
                _buildTextField(controller: _nameCtrl, hint: 'Rohit Sharma'),

                SizedBox(height: 16.h),

                // ── Business Name ──
                _buildLabel('Business / Company Name'),
                SizedBox(height: 6.h),
                _buildTextField(controller: _bizCtrl, hint: 'Leads Company'),

                SizedBox(height: 16.h),

                // ── Email ──
                _buildLabel('Email'),
                SizedBox(height: 6.h),
                _buildTextField(
                  controller: _emailCtrl,
                  hint: 'Leadscompany@mail.com',
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 16.h),

                // ── Address ──
                _buildLabel('Address'),
                SizedBox(height: 6.h),
                _buildTextField(controller: _addressCtrl, hint: 'Add Address'),

                SizedBox(height: 16.h),

                // ── City Dropdown ──
                _buildLabel('City'),
                SizedBox(height: 6.h),
                citiesAsync.when(
                  data: (cities) {
                    final names = cities.map((c) => c.name).toList();
                    return _buildDropdown(
                      hint: 'Pune City',
                      value: _selectedCity,
                      items: names.isNotEmpty ? names : _fallbackCities,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedCity = val;
                          try {
                            final match = cities.firstWhere(
                              (c) => c.name == val,
                            );
                            _selectedCityId = match.id;
                          } catch (_) {
                            _selectedCityId = '';
                          }
                        });
                      },
                    );
                  },
                  loading: () => _buildDropdown(
                    hint: 'Loading...',
                    value: null,
                    items: const [],
                    onChanged: (_) {},
                  ),
                  error: (e, s) => _buildDropdown(
                    hint: 'Select City',
                    value: _selectedCity,
                    items: _fallbackCities,
                    onChanged: (val) => setState(() {
                      _selectedCity = val;
                      _selectedCityId = '';
                    }),
                  ),
                ),

                SizedBox(height: 16.h),

                // ── Work Type Dropdown ──
                _buildLabel('Select Work Type'),
                SizedBox(height: 6.h),
                categoriesAsync.when(
                  data: (cats) {
                    final names = cats.map((c) => c.name).toList();
                    return _buildDropdown(
                      hint: 'Select Work Type',
                      value: _selectedWorkType,
                      items: names.isNotEmpty ? names : _fallbackWorkTypes,
                      onChanged: (val) =>
                          setState(() => _selectedWorkType = val),
                    );
                  },
                  loading: () => _buildDropdown(
                    hint: 'Loading...',
                    value: null,
                    items: const [],
                    onChanged: (_) {},
                  ),
                  error: (e, s) => _buildDropdown(
                    hint: 'Select Work Type',
                    value: _selectedWorkType,
                    items: _fallbackWorkTypes,
                    onChanged: (val) => setState(() => _selectedWorkType = val),
                  ),
                ),

                SizedBox(height: 36.h),

                // ── Continue Button ──
                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple73,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyles.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

  // ── Label ──
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF888888),
        ),
      ),
    );
  }

  // ── Text Field ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTextStyles.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFAAAAAA),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.purple73, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Dropdown ──
  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFAAAAAA),
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
            size: 22.r,
          ),
          style: AppTextStyles.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
