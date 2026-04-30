import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/profile/presentation/widgets/profile_form_fields.dart';

// ── Shared field style ────────────────────────────────────────────────────────
TextStyle _fieldStyle() => AppTextStyles.poppins(
  fontSize: 15.sp,
  color: AppColors.grey137,
  fontWeight: FontWeight.w400,
);

InputDecoration _fieldDeco({required String hint, bool readOnly = false}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: _fieldStyle(),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
      ),
    );

// ── Generic profile text field ────────────────────────────────────────────────
class ProfileTextField extends StatelessWidget {
  final String hint;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  const ProfileTextField({
    super.key,
    required this.hint,
    required this.initialValue,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: cardDeco(radius: 12),
    child: TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      style: _fieldStyle(),
      decoration: _fieldDeco(hint: hint, readOnly: readOnly),
    ),
  );
}

// ── Mobile number field with country code ─────────────────────────────────────
class MobileNumberField extends StatelessWidget {
  final String countryCode;
  final String phone;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onCodeChanged;

  const MobileNumberField({
    super.key,
    required this.countryCode,
    required this.phone,
    required this.onPhoneChanged,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: cardDeco(radius: 12),
    child: Row(
      children: [
        // Country code picker
        GestureDetector(
          onTap: () {}, // hook up picker if needed
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Text(
              countryCode,
              style: _fieldStyle().copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Phone input
        Expanded(
          child: TextFormField(
            initialValue: phone,
            onChanged: onPhoneChanged,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: _fieldStyle(),
            decoration: _fieldDeco(hint: 'Phone number').copyWith(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}
