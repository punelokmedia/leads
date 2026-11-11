import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const mode = ThemeMode.system;
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue, // was 0xFF5722CE (purple)
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF9ABCFF) : AppColors.primaryBlue,
          onPrimary: dark ? const Color(0xFF00265F) : Colors.white,
          secondary: dark ? const Color(0xFF58DED0) : AppColors.accentTeal,
          onSecondary: dark ? const Color(0xFF003732) : Colors.white,
          tertiary: dark ? const Color(0xFFFFD584) : const Color(0xFF925500),
          surface: dark ? const Color(0xFF132238) : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF192D47)
              : const Color(0xFFF0F6FF),
          surfaceContainerHigh: dark
              ? const Color(0xFF233B59)
              : const Color(0xFFE5EFFF),
          onSurface: dark ? const Color(0xFFF2F6FF) : AppColors.primaryNavy,
          onSurfaceVariant: dark
              ? const Color(0xFFC3D2E9)
              : const Color(0xFF415574),
          outline: dark ? const Color(0xFF7186A3) : const Color(0xFF8299BE),
          outlineVariant: dark
              ? const Color(0xFF354D6D)
              : const Color(0xFFD5E3FA),
        );
    final textTheme = ThemeData(brightness: brightness).textTheme
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          headlineMedium: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          titleLarge: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          titleMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
          bodyLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          bodyMedium: const TextStyle(fontSize: 16, height: 1.45),
          bodySmall: const TextStyle(fontSize: 14, height: 1.4),
          labelLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: colors.onSurface, displayColor: colors.onSurface);
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      textStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      textTheme: textTheme,
      iconTheme: IconThemeData(size: 26, color: colors.primary),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 16,
        iconColor: colors.primary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0E1822) // dark navy bg
          : AppColors.backgroundBase, // was 0xFFFAF9FD
      appBarTheme: AppBarTheme(
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleLarge,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.primary.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLow,
        modalBackgroundColor: colors.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
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
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
    );
  }
}
