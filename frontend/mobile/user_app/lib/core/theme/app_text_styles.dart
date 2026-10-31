// Font helpers – Montserrat is the primary brand font (new color scheme).
// Poppins, Roboto, InstrumentSans, Inter are preserved for backward compat.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  /// 🔹 Montserrat – PRIMARY brand font (new design system)
  static TextStyle montserrat({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    FontStyle? fontStyle,
  }) {
    final safeFontSize = (fontSize != null && fontSize > 0) ? fontSize : null;
    return GoogleFonts.montserrat(
      fontSize: safeFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }

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

  /// 🔹 Poppins (legacy – prefer montserrat() for new screens)
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    FontStyle? fontStyle,
  }) {
    final safeFontSize = (fontSize != null && fontSize > 0) ? fontSize : null;
    return GoogleFonts.montserrat(    // ← Switched to Montserrat brand font
      fontSize: safeFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }

  /// 🔹 Roboto
  static TextStyle roboto({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) {
    final safeFontSize = (fontSize != null && fontSize > 0) ? fontSize : null;
    return GoogleFonts.roboto(
      fontSize: safeFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
  }
}
