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
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import 'package:user_app/features/auth/presentation/widgets/profile_form_widgets.dart';
import '../../shared/auth_providers.dart';
import '../../shared/profile_draft_provider.dart'; 

class TellUsAboutYourselfScreen extends ConsumerStatefulWidget {
  const TellUsAboutYourselfScreen({super.key});

  @override
  ConsumerState<TellUsAboutYourselfScreen> createState() => _TellUsAboutYourselfScreenState();
}

class _TellUsAboutYourselfScreenState extends ConsumerState<TellUsAboutYourselfScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _bizCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _selectedCity;
  String? _selectedCityId; // ✅ Added to track the City ID
  String? _selectedWorkType;

  final List<String> _fallbackCities = ["Mumbai", "Delhi", "Bengaluru", "Pune"];
  final List<String> _fallbackWorkTypes = ["Carpenter", "Interior", "Plumber", "Electrician"];

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
          _selectedCityId = draft.cityId; // ✅ Pre-fill the ID if navigating back
        });
      }
      if (draft.workType.isNotEmpty) setState(() => _selectedWorkType = draft.workType);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bizCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_nameCtrl.text.trim().isEmpty || _bizCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _selectedCity == null || _selectedWorkType == null) {
      SnackbarHelper.showError(context, 'Please fill all details and select a City & Work Type.');
      return;
    }

    if (!_emailCtrl.text.contains('@')) {
      SnackbarHelper.showError(context, 'Please enter a valid email address.');
      return;
    }

    // ✅ Pass BOTH city name and cityId to the draft provider
    ref.read(profileDraftProvider.notifier).updateBasicDetails(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      businessName: _bizCtrl.text.trim(),
      city: _selectedCity!,
      cityId: _selectedCityId ?? '', // ✅ Save the ID here!
      workType: _selectedWorkType!,
    );

    context.push(AppRouter.chooseWorkCityPath);
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20.r), onPressed: () => context.pop()),
        title: Text('Tell us about yourself', style: AppTextStyles.poppins(fontSize: 24.sp, fontWeight: FontWeight.w600, color: AppColors.black)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                CustomProfileTextField(label: 'Full Name', hintText: 'Enter full name', controller: _nameCtrl),
                SizedBox(height: 20.h),
                CustomProfileTextField(label: 'Business / Company Name', hintText: 'Enter company name', controller: _bizCtrl),
                SizedBox(height: 20.h),
                CustomProfileTextField(label: 'Email', hintText: 'Enter email address', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 20.h),

                // ── Cities Dropdown ──
                citiesAsync.when(
                  data: (cities) {
                    final names = cities.map((c) => c.name).toList();
                    return CustomProfileDropdown(
                      label: 'City', 
                      hintText: 'Select city', 
                      value: _selectedCity, 
                      items: names.isNotEmpty ? names : _fallbackCities, 
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedCity = val;
                          // ✅ Find the matching city object and grab its ID
                          try {
                            final matchingCity = cities.firstWhere((c) => c.name == val);
                            _selectedCityId = matchingCity.id;
                          } catch (_) {
                            _selectedCityId = ''; // Fallback if somehow not found
                          }
                        });
                      }
                    );
                  },
                  loading: () => CustomProfileDropdown(label: 'City', hintText: 'Loading...', value: null, items: const [], onChanged: (v){}),
                  error: (e, s) => CustomProfileDropdown(
                    label: 'City (Offline)', 
                    hintText: 'Select city', 
                    value: _selectedCity, 
                    items: _fallbackCities, 
                    onChanged: (val) {
                      setState(() {
                        _selectedCity = val;
                        _selectedCityId = ''; // Offline fallback has no ID
                      });
                    }
                  ),
                ),
                SizedBox(height: 20.h),

                // ── Work Type Dropdown ──
                categoriesAsync.when(
                  data: (cats) {
                    final names = cats.map((c) => c.name).toList();
                    return CustomProfileDropdown(label: 'Select Work Type', hintText: 'Select Work Type', value: _selectedWorkType, items: names.isNotEmpty ? names : _fallbackWorkTypes, onChanged: (val) => setState(() => _selectedWorkType = val));
                  },
                  loading: () => CustomProfileDropdown(label: 'Select Work Type', hintText: 'Loading...', value: null, items: const [], onChanged: (v){}),
                  error: (e, s) => CustomProfileDropdown(label: 'Select Work Type', hintText: 'Select Work Type', value: _selectedWorkType, items: _fallbackWorkTypes, onChanged: (val) => setState(() => _selectedWorkType = val)),
                ),

                SizedBox(height: 40.h),
                AuthPrimaryButton(label: 'Continue', isLoading: false, onTap: _onContinue),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}