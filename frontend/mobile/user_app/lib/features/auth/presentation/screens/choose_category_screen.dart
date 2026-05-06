// features/auth/presentation/screens/choose_category_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ✅ Import flutter_svg
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/infra/category_repository.dart';
import 'package:user_app/features/auth/presentation/widgets/auth_common_widgets.dart';

import '../../shared/auth_providers.dart';
import '../../shared/profile_draft_provider.dart';


class ChooseCategoryScreen extends ConsumerStatefulWidget {
  const ChooseCategoryScreen({super.key});

  @override
  ConsumerState<ChooseCategoryScreen> createState() => _ChooseCategoryScreenState();
}

class _ChooseCategoryScreenState extends ConsumerState<ChooseCategoryScreen> {
  final Set<String> _selectedCategoryIds = {};
  bool _hasPreselected = false;

  final List<Color> _uiColors = [
    const Color(0xFF4522C2), const Color(0xFFE65100), const Color(0xFFE91E63),
    const Color(0xFF1976D2), const Color(0xFFFBC02D), const Color(0xFF795548),
    const Color(0xFF8D6E63), const Color(0xFFE040FB), const Color(0xFFC2185B),
    const Color(0xFF388E3C), const Color(0xFF03A9F4),
  ];

  Future<void> _onContinue() async {
    if (_selectedCategoryIds.isEmpty) {
      SnackbarHelper.showWarning(context, 'Please select at least one category');
      return;
    }

    final draft = ref.read(profileDraftProvider);

    await ref.read(authControllerProvider.notifier).completeProfile(
      fullName: draft.fullName,
      email: draft.email,
      businessName: draft.businessName,
      workType: draft.workType,
      city: draft.cityId,
      categories: _selectedCategoryIds.toList(),
      address: draft.address, 
      profilePicPath: draft.profilePicPath,
      onSuccess: () {
        ref.read(authControllerProvider.notifier).clearError();
        ref.read(profileDraftProvider.notifier).clearDraft(); 
        
        print("Profile Complete! Selected IDs: ${_selectedCategoryIds.toList()}");
        
        context.push(AppRouter.completePaymentPath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final categoriesAsync = ref.watch(categoriesProvider);

    if (categoriesAsync.hasValue && !_hasPreselected) {
      final draftWorkType = ref.read(profileDraftProvider).workType;
      for (var category in categoriesAsync.value!) {
        if (category.name == draftWorkType) {
          _selectedCategoryIds.add(category.id); 
          break;
        }
      }
      _hasPreselected = true; 
    }

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
          'Select Categories',
          style: AppTextStyles.poppins(fontSize: 22.sp, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    Center(
                      child: Text(
                        'Choose categories you want\nto receive leads for',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.poppins(
                          fontSize: 14.sp, color: Colors.grey[500], fontWeight: FontWeight.w400, height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: categoriesAsync.when(
                        data: (categories) {
                          if (categories.isEmpty) {
                            return const Center(child: Text("No categories found."));
                          }
                          return Column(
                            children: List.generate(categories.length, (index) {
                              final category = categories[index];
                              final color = _uiColors[index % _uiColors.length];
                              
                              // ✅ Pass the icon URL to the builder
                              return _buildCategoryItem(
                                id: category.id,
                                name: category.name,
                                iconUrl: category.icon, 
                                iconColor: color,
                              );
                            }),
                          );
                        },
                        loading: () => Padding(
                          padding: EdgeInsets.only(top: 40.h),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => Center(child: Text('Error loading categories: $err')),
                      ),
                    ),
                    
                    SizedBox(height: 100.h), 
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 30.h),
                color: Colors.white,
                child: AuthPrimaryButton(
                  label: 'Continue',
                  isLoading: isLoading,
                  onTap: _onContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom List Item ──
  Widget _buildCategoryItem({
    required String id,
    required String name,
    required String iconUrl, // ✅ Added iconUrl
    required Color iconColor,
  }) {
    final isSelected = _selectedCategoryIds.contains(id);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategoryIds.remove(id);
              } else {
                _selectedCategoryIds.add(id);
              }
            });
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              children: [
                // ✅ Render Network SVG and colorize it
                iconUrl.isNotEmpty && iconUrl.endsWith('.svg')
                    ? SvgPicture.network(
                        iconUrl,
                        width: 24.r,
                        height: 24.r,
                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                        placeholderBuilder: (context) => Icon(Icons.category_rounded, color: Colors.grey[300], size: 24.r),
                      )
                    : Icon(Icons.category_rounded, color: iconColor, size: 24.r), // Fallback if no valid URL

                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.poppins(
                      fontSize: 15.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purple73 : Colors.transparent,
                    borderRadius: BorderRadius.circular(4.r), 
                    border: Border.all(
                      color: isSelected ? AppColors.purple73 : Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected ? Icon(Icons.check, color: Colors.white, size: 16.r) : null,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey[200]),
      ],
    );
  }
}