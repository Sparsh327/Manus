import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Color tokens — update these once screenshots are analysed.
// Do NOT use these directly in widgets; go through AppTheme
// so light/dark switching works automatically.
// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Dark theme ──────────────────────────────────────────────
  static const darkBg = Color(0xFF0A0A0A);
  static const darkSurface = Color(0xFF141414);
  static const darkSurfaceElevated = Color(0xFF1E1E1E);
  static const darkBorder = Color(0xFF2A2A2A);
  static const darkBorderSubtle = Color(0xFF1F1F1F);
  static const darkTextPrimary = Color(0xFFF2F2F2);
  static const darkTextSecondary = Color(0xFF8A8A8A);
  static const darkTextTertiary = Color(0xFF555555);
  static const darkInputFill = Color(0xFF1A1A1A);
  static const darkUserBubble = Color(0xFF1E1E1E);
  static const darkCodeBlock = Color(0xFF111111);

  // ── Light theme ─────────────────────────────────────────────
  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF7F7F7);
  static const lightSurfaceElevated = Color(0xFFEFEFEF);
  static const lightBorder = Color(0xFFE5E5E5);
  static const lightBorderSubtle = Color(0xFFF0F0F0);
  static const lightTextPrimary = Color(0xFF0A0A0A);
  static const lightTextSecondary = Color(0xFF6B6B6B);
  static const lightTextTertiary = Color(0xFFAAAAAA);
  static const lightInputFill = Color(0xFFF5F5F5);
  static const lightUserBubble = Color(0xFFF0F0F0);
  static const lightCodeBlock = Color(0xFFF4F4F4);

  // ── Accent (same across themes) ─────────────────────────────
  static const accent = Color(0xFF5B5FE8);
  static const accentHover = Color(0xFF4A4ED6);
  static const accentSubtle = Color(0xFF1E1F4A);

  // ── Semantic (same across themes) ───────────────────────────
  static const error = Color(0xFFEF4444);
  static const errorSubtle = Color(0xFF3B1515);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const successSubtle = Color(0xFF0F2A1A);

  // ── Overlay ─────────────────────────────────────────────────
  static const overlay = Color(0x80000000);
  static const overlayLight = Color(0x40000000);
}
