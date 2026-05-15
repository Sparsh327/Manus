import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (AppColors.accent, Colors.white, Colors.transparent),
      AppButtonVariant.secondary => (cs.surface, cs.onSurface, cs.outline),
      AppButtonVariant.ghost => (Colors.transparent, cs.onSurface, Colors.transparent),
      AppButtonVariant.danger => (AppColors.error, Colors.white, Colors.transparent),
    };

    return SizedBox(
      width: width,
      height: 48.h,
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withAlpha(100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: border == Colors.transparent
                ? BorderSide.none
                : BorderSide(color: border),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
        ),
        child: isLoading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
