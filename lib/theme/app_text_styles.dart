import 'package:flutter/material.dart';
import 'package:manus/theme/app_fonts.dart';

// Named semantic text styles for reuse across screens.
// All font sizes are raw doubles — flutter_screenutil (.sp) is
// applied at the call site so these remain unit-testable.
class AppTextStyles {
  AppTextStyles._();

  // ── Display ─────────────────────────────────────────────────
  static TextStyle display({Color? color}) =>
      AppFonts.textTheme(const TextTheme()).displaySmall?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: color,
          ) ??
      TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: color);

  // ── Headings ────────────────────────────────────────────────
  static TextStyle h1({Color? color}) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle h2({Color? color}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle h3({Color? color}) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Body ────────────────────────────────────────────────────
  static TextStyle bodyLarge({Color? color}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle body({Color? color}) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  // ── Labels ──────────────────────────────────────────────────
  static TextStyle label({Color? color}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color,
      );

  // ── Monospace (code blocks) ──────────────────────────────────
  static TextStyle code({double fontSize = 13, Color? color}) =>
      AppFonts.monospace(fontSize: fontSize, color: color);
}
