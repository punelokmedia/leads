// features/auth/presentation/screens/tell_us_about_yourself_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';

import 'package:user_app/app/app_router.dart';

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
  final _referralCtrl = TextEditingController();

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
      if (!mounted) return;
      final draft = ref.read(profileDraftProvider);
      _referralCtrl.text = draft.referralCode;
      if (draft.fullName.isNotEmpty) _nameCtrl.text = draft.fullName;
      if (draft.email.isNotEmpty) _emailCtrl.text = draft.email;
      if (draft.businessName.isNotEmpty) _bizCtrl.text = draft.businessName;
      if (draft.address.isNotEmpty) _addressCtrl.text = draft.address;
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
    _referralCtrl.dispose();
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
          address: _addressCtrl.text.trim(),
          referralCode: _referralCtrl.text.trim(),
        );

    context.push(AppRouter.chooseWorkCityPath);
  }

  static const _navy = Color(0xFF061139);
  static const _muted = Color(0xFF53678F);
  static const _blue = Color(0xFF0047FF);

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: -20,
              bottom: -165,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.055,
                  child: Image.asset(
                    'assets/Nextlead Mobile  App Asetes/NextLead Arrow only.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 65.h,
                        child: Stack(
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/branding/nextlead_wordmark.webp',
                                width: 160.w,
                                height: 58.h,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                tooltip: 'Back',
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRouter.login);
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: _navy,
                                  size: 24.r,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Complete your profile',
                          style: AppTextStyles.inter(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                            letterSpacing: -1.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        'Tell us about yourself and your business.',
                        style: AppTextStyles.inter(
                          fontSize: 15.sp,
                          color: _muted,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildLabel('Full name'),
                      _buildTextField(
                        controller: _nameCtrl,
                        hint: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                      ),
                      SizedBox(height: 15.h),
                      _buildLabel('Business/Company Name'),
                      _buildTextField(
                        controller: _bizCtrl,
                        hint: 'Enter your business name',
                        icon: Icons.business_outlined,
                      ),
                      SizedBox(height: 15.h),
                      _buildLabel('Email address'),
                      _buildTextField(
                        controller: _emailCtrl,
                        hint: 'you@company.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 15.h),
                      _buildLabel('City'),
                      citiesAsync.when(
                        data: (cities) {
                          final names = cities.map((c) => c.name).toList();
                          return _buildDropdown(
                            hint: 'Enter your city',
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

                      SizedBox(height: 15.h),
                      _buildLabel('Work type'),
                      categoriesAsync.when(
                        data: (cats) {
                          final names = cats.map((c) => c.name).toList();
                          return _buildDropdown(
                            hint: 'Select your service category',
                            value: _selectedWorkType,
                            items: names.isNotEmpty
                                ? names
                                : _fallbackWorkTypes,
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
                          hint: 'Select your service category',
                          value: _selectedWorkType,
                          items: _fallbackWorkTypes,
                          onChanged: (val) =>
                              setState(() => _selectedWorkType = val),
                        ),
                      ),

                      SizedBox(height: 15.h),
                      _buildLabel('Referral code', optional: true),
                      _buildTextField(
                        controller: _referralCtrl,
                        hint: 'Enter referral code if you have one',
                        icon: Icons.card_giftcard_outlined,
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: FilledButton(
                          onPressed: _onContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: AppTextStyles.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Icon(Icons.arrow_forward_rounded, size: 22.r),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Center(
                        child: Text(
                          'Your information is safe with us. We respect your privacy.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.inter(
                            fontSize: 10.sp,
                            color: _muted,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool optional = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        children: [
          Text(
            text,
            style: AppTextStyles.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: _navy,
            ),
          ),
          if (!optional)
            Text(
              ' *',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          if (optional) ...[
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Optional',
                style: AppTextStyles.inter(fontSize: 10.sp, color: _blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.inter(fontSize: 14.sp, color: _muted),
    filled: true,
    fillColor: Colors.white,
    prefixIcon: Icon(icon, color: _muted, size: 21.r),
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: Color(0xFFD3DCEC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: Color(0xFFD3DCEC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.inter(fontSize: 14.sp, color: _navy),
      decoration: _decoration(hint, icon),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final values = items.toSet().toList();
    final selected = values.where(
      (item) => item.toLowerCase() == value?.toLowerCase(),
    );
    return DropdownButtonFormField<String>(
      initialValue: selected.isEmpty ? null : selected.first,
      isExpanded: true,
      decoration: _decoration(
        hint,
        hint.contains('category') || hint.contains('Work')
            ? Icons.category_outlined
            : Icons.location_on_outlined,
      ),
      hint: Text(
        hint,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.inter(fontSize: 14.sp, color: _muted),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
      style: AppTextStyles.inter(fontSize: 14.sp, color: _navy),
      dropdownColor: Colors.white,
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: values.isEmpty ? null : onChanged,
    );
  }
}
