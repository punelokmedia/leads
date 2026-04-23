// address/presentation/screens/add_address_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';

import '../../shared/address_providers.dart';
import '../widgets/address_widgets.dart';

class AddAddressScreen extends ConsumerWidget {
  const AddAddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(addressDataProvider);
    final isLoading = ref.watch(addressIsLoadingProvider);
    final notifier = ref.read(addressControllerProvider.notifier);

    ref.listen(addressErrorProvider, (_, err) {
      if (err != null) {
        SnackbarHelper.showError(context, err);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.r,
            color: Colors.black87,
          ),
        ),
        title: Text(
          'Add Address',
          style: AppTextStyles.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Scrollable form ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flat no. / Street Name
                  const AddressLabel(
                    text: 'Flat no. / Street Name',
                    
                  ),
                  AddressTextField(
                    hint: 'Flat 203, Sai Residency',
                    initialValue: address.flatStreet,
                    onChanged: (v) =>
                        notifier.updateField(address.copyWith(flatStreet: v)),
                  ),
                  SizedBox(height: 16.h),

                  // Landmark
                  const AddressLabel(text: 'Landmark'),
                  AddressTextField(
                    hint: 'Near Padmavati Hospital',
                    initialValue: address.landmark,
                    onChanged: (v) =>
                        notifier.updateField(address.copyWith(landmark: v)),
                  ),
                  SizedBox(height: 16.h),

                  // City
                  const AddressLabel(text: 'City'),
                  AddressCityDropdown(
                    selectedCity: address.city.isEmpty
                        ? 'Select City'
                        : address.city,
                    onChanged: (v) =>
                        notifier.updateField(address.copyWith(city: v)),
                  ),
                  SizedBox(height: 16.h),

                  // State
                  const AddressLabel(text: 'State'),
                  AddressTextField(
                    hint: 'Maharashtra, India',
                    initialValue: address.state,
                    onChanged: (v) =>
                        notifier.updateField(address.copyWith(state: v)),
                  ),
                  SizedBox(height: 16.h),

                  // Zipcode
                  const AddressLabel(text: 'Zipcode'),
                  AddressTextField(
                    hint: '411853',
                    initialValue: address.zipcode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) =>
                        notifier.updateField(address.copyWith(zipcode: v)),
                  ),
                  SizedBox(height: 24.h),

                  // Save address as
                  Text(
                    'Save address as',
                    style: AppTextStyles.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey137,
                      height: 20 / 18,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 19.h),
                  AddressTypePicker(
                    selected: address.type,
                    onChanged: (type) {
                      notifier.setType(type);
                    },
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),

          // ── Save button pinned at bottom ──────────────────────────────────
          Container(
            color: const Color(0xFFF7F7F7),
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              bottom: MediaQuery.of(context).padding.bottom + 16.h,
              top: 8.h,
            ),
            child: SaveButton(
              isLoading: isLoading,
              onTap: () {
                notifier.save(
                  onSuccess: () {
                    SnackbarHelper.showSuccess(context, "Address saved successfully");
                   
                    context.pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
