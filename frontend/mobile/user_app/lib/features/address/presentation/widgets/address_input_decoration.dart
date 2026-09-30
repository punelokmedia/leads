import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

InputDecoration addressInputDeco(
  BuildContext context, {
  required String hint,
  Widget? suffix,
}) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 14.sp,
  ),
  suffixIcon: suffix,
  filled: true,
  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
  border: _border(),
  enabledBorder: _border(),
  focusedBorder: _border(color: const Color(0xFFFFC107), width: 1.5),
);

OutlineInputBorder _border({Color? color, double width = 0}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: color != null
          ? BorderSide(color: color, width: width)
          : BorderSide.none,
    );

BoxDecoration cardShadow(BuildContext context, {double radius = 12}) =>
    BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius.r),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.25),
          blurRadius: 4,
          offset: Offset(0, 4),
        ),
      ],
    );
