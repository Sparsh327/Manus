import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_fonts.dart';

// ─────────────────────────────────────────────────────────────
// All color tokens live in AppColors.
// All font logic lives in AppFonts.
// This file assembles them into ThemeData objects.
//
// MaterialApp uses:
//   theme: AppTheme.light()
//   darkTheme: AppTheme.dark()
//   themeMode: ref.watch(themeProvider)   ← from Riverpod
//
// Flutter's built-in AnimatedTheme (inside MaterialApp) handles
// the 200ms cross-fade automatically when themeMode changes.
// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark() => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceElevated =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentSubtle,
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.accentSubtle,
      onSecondary: AppColors.accent,
      secondaryContainer: surfaceElevated,
      onSecondaryContainer: textPrimary,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: surfaceElevated,
      onTertiaryContainer: textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorSubtle,
      onErrorContainer: AppColors.error,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
      shadow: Colors.black,
      scrim: AppColors.overlay,
      inverseSurface: isDark ? AppColors.lightSurface : AppColors.darkSurface,
      onInverseSurface:
          isDark ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
      inversePrimary: AppColors.accent,
    );

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme.apply(
              bodyColor: textPrimary,
              displayColor: textPrimary,
            )
        : ThemeData.light().textTheme.apply(
              bodyColor: textPrimary,
              displayColor: textPrimary,
            );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: AppFonts.textTheme(baseTextTheme),
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textSecondary, fontSize: 15),
      ),
      // Divider
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      // Card
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      // Icon
      iconTheme: IconThemeData(color: textSecondary, size: 22),
      // Page transitions: Cupertino on iOS, shared-axis on Android
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
