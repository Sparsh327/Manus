import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// Platform-aware typography.
//
// iOS  → null fontFamily → Flutter inherits system font → SF Pro
// Android → Inter via google_fonts (cached after first fetch)
//
// CRITICAL: Never set a named fontFamily on iOS.
// Inter on iOS is the #1 clone detection tell → immediate fail.
// ─────────────────────────────────────────────────────────────
class AppFonts {
  AppFonts._();

  static bool get _isIOS => Platform.isIOS;

  // Body text theme for the platform
  static TextTheme textTheme(TextTheme base) {
    if (_isIOS) return base; // SF Pro via system font
    return GoogleFonts.interTextTheme(base);
  }

  // Monospace — used for code blocks only
  static TextStyle monospace({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    if (_isIOS) {
      return TextStyle(
        fontFamily:
            'Courier', // SF Mono fallback (true SF Mono needs entitlement)
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
