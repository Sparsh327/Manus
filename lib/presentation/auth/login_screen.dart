import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manus/router/app_routes.dart';
import 'package:manus/theme/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          _DotPatternBackground(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                            Icons.waving_hand_rounded,
                            size: 64.r,
                            color: cs.onSurface,
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scaleXY(
                            begin: 0.85,
                            end: 1.0,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          ),
                      SizedBox(height: 24.h),
                      Text(
                        'Welcome to Manus',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
                  child: Column(
                    children: [
                      _AuthButton(
                        onTap: () => context.go(AppRoutes.conversations),
                        leading: const CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=3',
                          ),
                        ),
                        badge: const _FbBadge(),
                        label: 'Continue with Facebook',
                        subtitle: 'Sparsh Jaiswal',
                      ),
                      SizedBox(height: 16.h),
                      _OrDivider(),
                      SizedBox(height: 16.h),
                      _AuthButton(
                        onTap: () => context.go(AppRoutes.conversations),
                        leading: Image.asset(
                          'assets/logo/google-logo.png',
                          width: 26.r,
                          height: 26.r,
                        ),
                        label: 'Continue with Google',
                      ),
                      SizedBox(height: 10.h),
                      _AuthButton(
                        onTap: () => context.go(AppRoutes.conversations),
                        leading: _SocialIcon(
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFF00A1F1),
                        ),
                        label: 'Continue with Microsoft',
                      ),
                      SizedBox(height: 10.h),
                      _AuthButton(
                        onTap: () => context.go(AppRoutes.conversations),
                        leading: Image.asset(
                          'assets/logo/apple-logo.png',
                          width: 26.r,
                          height: 26.r,
                          color: cs.onSurface,
                        ),
                        label: 'Continue with Apple',
                      ),
                      SizedBox(height: 10.h),
                      _AuthButton(
                        onTap: () => context.push(AppRoutes.emailLogin),
                        leading: _SocialIcon(
                          icon: Icons.email_outlined,
                          color: cs.onSurface,
                        ),
                        label: 'Continue with Email',
                      ),
                      SizedBox(height: 20.h),
                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: cs.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: cs.onSurface,
                              ),
                            ),
                            const TextSpan(text: ' and have read our '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: cs.onSurface,
                              ),
                            ),
                            const TextSpan(text: '. © 2026 Meta'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth button ──────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget leading;
  final String label;
  final String? subtitle;
  final Widget? badge;

  const _AuthButton({
    required this.onTap,
    required this.leading,
    required this.label,
    this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36.r,
              height: 36.r,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  leading,
                  if (badge != null)
                    Positioned(right: -4, bottom: -4, child: badge!),
                ],
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (subtitle != null)
              Icon(
                Icons.chevron_right,
                color: cs.onSurfaceVariant,
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }
}

class _FbBadge extends StatelessWidget {
  const _FbBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.r,
      height: 18.r,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.facebook, size: 13.r, color: Colors.white),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SocialIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 26.r, color: color);
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Divider(color: cs.outline.withValues(alpha: 0.6), height: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12.sp,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: cs.outline.withValues(alpha: 0.6), height: 1),
        ),
      ],
    );
  }
}

// ── Dot pattern background ───────────────────────────────────

class _DotPatternBackground extends StatelessWidget {
  final bool isDark;
  const _DotPatternBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotPainter(isDark: isDark),
      size: Size.infinite,
    );
  }
}

class _DotPainter extends CustomPainter {
  final bool isDark;
  _DotPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 22.0;
    const dotRadius = 1.5;
    final rng = math.Random(42);

    for (double y = 0; y < size.height * 0.65; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final dist = math.sqrt(x * x + y * y);
        final maxDist = size.width * 0.9;
        if (dist > maxDist) continue;

        Color dotColor;
        final r = rng.nextDouble();
        if (r < 0.08) {
          dotColor = const Color(0xFF4A7FD4).withValues(alpha: 0.7);
        } else if (r < 0.13 && x > size.width * 0.5) {
          dotColor = const Color(0xFFD44A4A).withValues(alpha: 0.5);
        } else {
          dotColor = isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06);
        }

        canvas.drawCircle(Offset(x, y), dotRadius, Paint()..color = dotColor);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.isDark != isDark;
}
