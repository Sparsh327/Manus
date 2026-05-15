import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:manus/router/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFEBEBEB);
    final fg = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.waving_hand_rounded,
                size: 72.r,
                color: fg,
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .scaleXY(
                    begin: 0.8,
                    end: 1.0,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
            ),
            Positioned(
              bottom: 32.h,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'from',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: fg.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.all_inclusive, size: 16.r, color: fg),
                      SizedBox(width: 6.w),
                      Text(
                        'Meta',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}
