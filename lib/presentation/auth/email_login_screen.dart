import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manus/router/app_routes.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Subtle dot grid
          CustomPaint(painter: _SubtleDotPainter(), size: Size.infinite),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 48.w),
                    ],
                  ),
                ),
                // Manus brand
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.waving_hand_rounded,
                        size: 20.r,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'manus',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 48.h),
                        Icon(
                          Icons.waving_hand_rounded,
                          size: 64.r,
                          color: Colors.white,
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Sign in or sign up',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Start creating with Manus',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32.h),
                        // Email field
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 15.sp,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // Cloudflare CAPTCHA mock
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28.r,
                                height: 28.r,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Success!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.cloud_outlined,
                                    color: const Color(0xFFF38020),
                                    size: 20.r,
                                  ),
                                  Text(
                                    'CLOUDFLARE',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: Colors.white.withValues(alpha: 0.5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Privacy',
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: Colors.white
                                                .withValues(alpha: 0.5),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' · ',
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: Colors.white
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Help',
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: Colors.white
                                                .withValues(alpha: 0.5),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Continue button
                        GestureDetector(
                          onTap: _hasText
                              ? () => context.go(AppRoutes.conversations)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: _hasText
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: _hasText
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 350.ms),
                  ),
                ),
                // Footer
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.all_inclusive,
                            size: 14.r,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'from',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'Meta',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FooterLink('Terms of service'),
                          _FooterDot(),
                          _FooterLink('Privacy policy'),
                          _FooterDot(),
                          Text(
                            '©2026 Meta',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.sp,
        color: Colors.white.withValues(alpha: 0.4),
        decoration: TextDecoration.underline,
        decorationColor: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _SubtleDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 22.0;
    const dotRadius = 1.2;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.055);
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SubtleDotPainter old) => false;
}
