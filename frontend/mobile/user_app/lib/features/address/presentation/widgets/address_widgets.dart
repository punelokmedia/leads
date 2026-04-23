import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import '../../domain/address_model.dart';
import 'address_input_decoration.dart';

// ── Text Field ────────────────────────────────────────────────────────────────
class AddressTextField extends StatelessWidget {
  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const AddressTextField({
    super.key,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: cardShadow(),
        child: TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: _fieldStyle(),
          decoration: addressInputDeco(hint: hint),
        ),
      );
}

// ── City Dropdown ─────────────────────────────────────────────────────────────
class AddressCityDropdown extends StatelessWidget {
  final String selectedCity;
  final ValueChanged<String> onChanged;

  static const _cities = [
    'Select City', 'Nashik', 'Pune', 'Mumbai', 'Bangaluru',
    'Chennai', 'Hyderabad', 'Delhi', 'Kolkata', 'Nagpur', 'Coimbatore',
  ];

  const AddressCityDropdown({
    super.key,
    required this.selectedCity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = _cities.contains(selectedCity) ? selectedCity : _cities.first;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: cardShadow(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey180, size: 20.r),
          style: _fieldStyle(),
          items: _cities
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) {
            if (val != null && val != 'Select City') onChanged(val);
          },
        ),
      ),
    );
  }
}

// ── Address Type Picker ───────────────────────────────────────────────────────
class AddressTypePicker extends StatelessWidget {
  final AddressType selected;
  final ValueChanged<AddressType> onChanged;

  const AddressTypePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _TypeChip(
            icon: Icons.home_outlined,
            label: 'Home',
            isSelected: selected == AddressType.home,
            onTap: () => onChanged(AddressType.home),
          ),
          SizedBox(width: 12.w),
          _TypeChip(
            icon: Icons.business_center_outlined,
            label: 'Office',
            isSelected: selected == AddressType.office,
            onTap: () => onChanged(AddressType.office),
          ),
        ],
      );
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFF8B020);

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          decoration: BoxDecoration(
            color: isSelected ? _accent : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _accent, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26.r,
                  color: isSelected ? Colors.white : Colors.grey.shade600),
              SizedBox(width: 8.w),
              Text(label,
                  style: AppTextStyles.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  )),
            ],
          ),
        ),
      );
}

// ── Label ─────────────────────────────────────────────────────────────────────
class AddressLabel extends StatelessWidget {
  final String text;
  
  const AddressLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 6.h),
        child: Text(text,
            style: AppTextStyles.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
              color: const Color.fromRGBO(69, 90, 100, 1),
            )),
      );
}

// ── Save Button ───────────────────────────────────────────────────────────────
class SaveButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const SaveButton({super.key, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 52.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFECCC0D), Color(0xFFF8B020)]),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC107).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : Text('Save',
                    style: AppTextStyles.poppins(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    )),
          ),
        ),
      );
}

// ── Shared text style ─────────────────────────────────────────────────────────
TextStyle _fieldStyle() => AppTextStyles.poppins(
      fontSize: 16.sp,
      color: AppColors.grey137,
      height: 1,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.01,
    );