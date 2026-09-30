import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static const mode = ThemeMode.system;
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5722CE),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF121016)
          : const Color(0xFFFAF9FD),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(color: colors.surfaceContainerLow),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLow,
        modalBackgroundColor: colors.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
      ),
    );
  }
}
