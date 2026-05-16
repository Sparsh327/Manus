import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_text_styles.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _monthly = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle dot pattern
            CustomPaint(
              painter: _SubtleDotPainter(isDark: isDark),
              size: Size.infinite,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(12.r),
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18.r,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to\nManus Pro',
                          style: TextStyle(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Features card
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            children: _features
                                .map(
                                  (f) => Padding(
                                    padding: EdgeInsets.only(bottom: 16.h),
                                    child: _FeatureRow(
                                      icon: f.$1,
                                      label: f.$2,
                                      cs: cs,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Plan selection
                        _PlanOption(
                          label: 'Monthly',
                          price: '₹4,200.00',
                          selected: _monthly,
                          badge: 'Popular',
                          isDark: isDark,
                          cs: cs,
                          onTap: () => setState(() => _monthly = true),
                        ),
                        SizedBox(height: 10.h),
                        _PlanOption(
                          label: 'Annually',
                          price: '₹42,100.00',
                          selected: !_monthly,
                          isDark: isDark,
                          cs: cs,
                          onTap: () => setState(() => _monthly = false),
                        ),
                        SizedBox(height: 12.h),
                        Center(
                          child: Text(
                            'Auto renews ${_monthly ? 'monthly' : 'annually'}. Cancel anytime.',
                            style: AppTextStyles.bodySmall(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
                // CTA button
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      height: 54.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Upgrade now',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Footer
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FooterLink('Terms', cs: cs),
                      _Dot(cs: cs),
                      _FooterLink('Privacy', cs: cs),
                      _Dot(cs: cs),
                      _FooterLink('Restore', cs: cs),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _features = [
    (Icons.auto_awesome_outlined, '8,000 credits per month'),
    (Icons.manage_search_outlined, 'Advanced research for any topic'),
    (Icons.web_outlined, 'Professional website deployment'),
    (Icons.slideshow_outlined, 'Insightful slides with strong structure'),
    (Icons.speed_outlined, 'Best performance for demanding tasks'),
    (Icons.checklist_outlined, '20 concurrent tasks'),
  ];
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.r, color: cs.onSurface),
        SizedBox(width: 14.w),
        Expanded(child: Text.rich(_boldFirst(label, cs))),
      ],
    );
  }

  TextSpan _boldFirst(String text, ColorScheme cs) {
    final match = RegExp(r'^([\d,]+)(.*)').firstMatch(text);
    if (match != null) {
      return TextSpan(
        text: match.group(1),
        style: AppTextStyles.body(
          color: cs.onSurface,
        ).copyWith(fontWeight: FontWeight.w700),
        children: [
          TextSpan(
            text: match.group(2),
            style: AppTextStyles.body(
              color: cs.onSurface,
            ).copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      );
    }
    return TextSpan(
      text: text,
      style: AppTextStyles.body(color: cs.onSurface),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String label;
  final String price;
  final bool selected;
  final String? badge;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _PlanOption({
    required this.label,
    required this.price,
    required this.selected,
    required this.isDark,
    required this.cs,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? (isDark ? Colors.white : Colors.black)
                      : cs.onSurfaceVariant,
                  width: selected ? 6 : 2,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              price,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _FooterLink(this.label, {required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.sp,
        color: cs.onSurfaceVariant,
        decoration: TextDecoration.underline,
        decorationColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final ColorScheme cs;
  const _Dot({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Text(
        '·',
        style: TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _SubtleDotPainter extends CustomPainter {
  final bool isDark;
  const _SubtleDotPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);
    for (double y = 0; y < size.height * 0.4; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SubtleDotPainter old) => old.isDark != isDark;
}
