// features/auth/presentation/screens/choose_work_city_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/auth/domain/city_model.dart';
import 'package:user_app/features/auth/infra/city_repository.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';
import 'package:user_app/features/auth/presentation/widgets/city_list_item_widget.dart';
import 'package:user_app/features/auth/shared/profile_draft_provider.dart';
import '../../shared/auth_providers.dart';



class ChooseWorkCityScreen extends ConsumerStatefulWidget {
  const ChooseWorkCityScreen({super.key});

  @override
  ConsumerState<ChooseWorkCityScreen> createState() =>
      _ChooseWorkCityScreenState();
}

class _ChooseWorkCityScreenState extends ConsumerState<ChooseWorkCityScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // ✅ Track both Name and ID
  String? _selectedCityName;
  String? _selectedCityId;

  final List<String> _fallbackCities = [
    "Mumbai, Maharashtra",
    "Delhi, Delhi",
    "Bangalore, Karnataka",
    "Hyderabad, Telangana",
    "Chennai, Tamil Nadu",
    "Kolkata, West Bengal",
    "Pune, Maharashtra",
    "Ahmedabad, Gujarat",
    "Gurgaon, Haryana",
    "Noida, Uttar Pradesh",
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {});
    });

    // ✅ Read both name and ID from draft
    final draft = ref.read(profileDraftProvider);
    if (draft.city.isNotEmpty) {
      _selectedCityName = draft.city;
      _selectedCityId = draft.cityId;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_selectedCityName == null) return;
    print("Selected City: $_selectedCityName, ID: $_selectedCityId");
    
    // ✅ Save both to the draft provider
    ref.read(profileDraftProvider.notifier).updateCity(
      cityName: _selectedCityName!, 
      cityId: _selectedCityId ?? ''
    );
    
    context.push(AppRouter.chooseCategoryPath);
  }

  // ✅ Change parameter to List<City> instead of List<String>
  Widget _buildCityList(List<City> allCities) {
    final query = _searchCtrl.text.toLowerCase();
    
    final filteredCities = query.isEmpty 
        ? allCities 
        : allCities.where((city) => city.name.toLowerCase().contains(query)).toList();

    if (filteredCities.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 20.h),
        child: Center(
          child: Text(
            "No cities found matching '${_searchCtrl.text}'",
            style: AppTextStyles.poppins(
              fontSize: 14.sp,
              color: Colors.grey[400],
            ),
          ),
        ),
      );
    }

    return Column(
      children: filteredCities.map((city) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: CityListItemWidget(
            cityName: city.name,
            isSelected: _selectedCityName?.toLowerCase() == city.name.toLowerCase(),
            onTap: () => setState(() {
              // ✅ Capture both Name and ID when tapped
              _selectedCityName = city.name;
              _selectedCityId = city.id;
            }),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authIsLoadingProvider);
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.grey102,
            size: 25.r,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Select your City',
          style: AppTextStyles.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              height: 20 / 24,
              letterSpacing: 0.01),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Center(
                      child: Text(
                        'Choose the city\nwhere you want to work',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.poppins(
                            fontSize: 16.sp,
                            color: AppColors.purple75,
                            fontWeight: FontWeight.w400,
                            height: 20 / 16,
                            letterSpacing: 0.01),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.grey198),
                      ),
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color.fromRGBO(0, 0, 0, 1),
                              Color.fromRGBO(102, 102, 102, 1),
                            ],
                          ).createShader(bounds);
                        },
                        child: TextField(
                          controller: _searchCtrl,
                          style: AppTextStyles.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search City',
                            hintStyle: AppTextStyles.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(Icons.search, size: 24.r),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),

                    Text(
                      'Popular Cities',
                      style: AppTextStyles.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    citiesAsync.when(
                      data: (cities) {
                        // ✅ Pass the whole 'City' objects, not just strings
                        return _buildCityList(cities);
                      },
                      loading: () => Padding(
                        padding: EdgeInsets.only(top: 20.h),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.purple75,
                          ),
                        ),
                      ),
                      error: (err, stack) {
                        // ✅ Convert the fallback strings into mock City objects if offline
                        final fallbackCityObjects = _fallbackCities
                            .map((name) => City(id: '', name: name))
                            .toList();
                        return _buildCityList(fallbackCityObjects);
                      },
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 30.h),
              color: Colors.white,
              child: AuthPrimaryButton(
                label: 'Continue',
                isLoading: isLoading,
                onTap: _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}