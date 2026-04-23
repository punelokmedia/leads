import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

// ── Shared styles ─────────────────────────────────────────────────────────────
TextStyle _fieldStyle() => AppTextStyles.poppins(
      fontSize: 16.sp, color: AppColors.grey77,
      fontWeight: FontWeight.w500, height: 20 / 16, letterSpacing: 0.1);

OutlineInputBorder _border({Color? color, double width = 1.5}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: color != null
          ? BorderSide(color: color, width: width)
          : BorderSide.none,
    );

// ── Auth text field ───────────────────────────────────────────────────────────
class AuthTextField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.poppins(
                  fontSize: 18.sp, fontWeight: FontWeight.w500,
                  color: AppColors.grey77, height: 20 / 18, letterSpacing: 0.1)),
          SizedBox(height: 6.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              style: _fieldStyle(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: _fieldStyle(),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: Colors.transparent,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 14.h),
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(color: const Color(0xFFFFC107)),
                errorBorder: _border(color: Colors.red, width: 1),
                focusedErrorBorder: _border(color: Colors.red),
              ),
            ),
          ),
        ],
      );
}

// ── Password field ────────────────────────────────────────────────────────────
class PasswordField extends StatefulWidget {
  final String label, hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const PasswordField({
    super.key,
    this.label = 'Password',
    this.hint = '••••••••',
    required this.controller,
    this.validator,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => AuthTextField(
        label: widget.label,
        hint: widget.hint,
        controller: widget.controller,
        obscureText: _obscure,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20.r, color: Colors.grey[400],
          ),
        ),
      );
}