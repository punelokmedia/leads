// s

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  /// 🔹 Instrument Sans
  static TextStyle instrumentsans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final safeFontSize = (fontSize != null && fontSize > 0) ? fontSize : null;
    return GoogleFonts.instrumentSans(
      fontSize: safeFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// 🔹 Inter
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final safeFontSize = (fontSize != null && fontSize > 0) ? fontSize : null;
    return GoogleFonts.inter(
      fontSize: safeFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  //Poppins
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration, //  ADD THIS
    Color? decorationColor, //  OPTIONAL (good practice)
    TextDecorationStyle? decorationStyle, //  OPTIONAL
    FontStyle? fontStyle
  }) {
    // Safety check for fontSize to prevent StrutStyle assertion failures
    final safeFontSize = (fontSize != null && fontSize > 0) ? fontSize : null;

    return GoogleFonts.poppins(
      fontSize: safeFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      decoration: decoration, //  APPLY
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }

  //Roboto
  static TextStyle roboto({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration, //  ADD THIS
    Color? decorationColor, //  OPTIONAL (good practice)
    TextDecorationStyle? decorationStyle, //  OPTIONAL
  }) {
    final safeFontSize = (fontSize != null && fontSize > 0) ? fontSize : null;
    return GoogleFonts.roboto(
      fontSize: safeFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration, //  APPLY
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }
}
