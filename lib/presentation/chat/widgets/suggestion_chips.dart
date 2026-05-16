import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_text_styles.dart';

// ── Suggestion data ──────────────────────────────────────────

const _suggestions = [
  'Create a comprehensive research report',
  'Build and deploy a website',
  'Automatße a workflow with code',
  'Generate slides for a presentation',
];

// ── Empty state view ─────────────────────────────────────────

/// Shown when a new conversation has no messages yet.
/// [onChipTap] receives the chip's BuildContext (for position) + text.
class SuggestionChipsEmptyState extends StatelessWidget {
  final void Function(BuildContext chipCtx, String text) onChipTap;

  const SuggestionChipsEmptyState({super.key, required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waving_hand_rounded, size: 44.r, color: cs.onSurface)
                .animate()
                .fadeIn(duration: 500.ms)
                .scaleXY(
                  begin: 0.8,
                  end: 1.0,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),
            SizedBox(height: 18.h),
            Text(
              'What can Manus help\nyou accomplish?',
              style: AppTextStyles.h2(color: cs.onSurface),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
            SizedBox(height: 8.h),
            Text(
              'Research, code, write, and execute — end to end.',
              style: AppTextStyles.body(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 220.ms),
            SizedBox(height: 36.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: _suggestions.asMap().entries.map((e) {
                return _SuggestionChipItem(
                  text: e.value,
                  delayMs: 300 + e.key * 80,
                  onTap: onChipTap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual chip ──────────────────────────────────────────

class _SuggestionChipItem extends StatelessWidget {
  final String text;
  final int delayMs;
  final void Function(BuildContext, String) onTap;

  const _SuggestionChipItem({
    required this.text,
    required this.delayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(context, text);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(text, style: AppTextStyles.body(color: cs.onSurface)),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: delayMs.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.35,
          end: 0,
          duration: 350.ms,
          delay: delayMs.ms,
          curve: Curves.easeOutCubic,
        )
        .scaleXY(
          begin: 0.92,
          end: 1.0,
          duration: 350.ms,
          delay: delayMs.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ── CE-6: Chip → Input Overlay animation ─────────────────────
//
// When a chip is tapped, we capture its global Rect and the input bar's
// global Rect, then animate a copy of the chip flying from one to the other
// in an Overlay entry — morphing pill shape → rounded rectangle.
// On completion the Overlay is removed and the text controller is filled.

class ChipFlyAnimation extends StatefulWidget {
  final Rect startRect;
  final Rect endRect;
  final String text;
  final bool isDark;
  final VoidCallback onComplete;

  const ChipFlyAnimation({
    super.key,
    required this.startRect,
    required this.endRect,
    required this.text,
    required this.isDark,
    required this.onComplete,
  });

  @override
  State<ChipFlyAnimation> createState() => _ChipFlyAnimationState();
}

class _ChipFlyAnimationState extends State<ChipFlyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 370),
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _ctrl.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, _) {
        final t = _curve.value;
        final left = ui.lerpDouble(
          widget.startRect.left,
          widget.endRect.left,
          t,
        )!;
        final top = ui.lerpDouble(widget.startRect.top, widget.endRect.top, t)!;
        final width = ui.lerpDouble(
          widget.startRect.width,
          widget.endRect.width,
          t,
        )!;
        final height = ui.lerpDouble(
          widget.startRect.height,
          widget.endRect.height,
          t,
        )!;
        // Morph: pill radius → input bar radius
        final radius = ui.lerpDouble(20.0, 24.0, t)!;
        // Fade out in the last 25% of the animation
        final opacity = (t > 0.75 ? (1.0 - t) / 0.25 : 1.0).clamp(0.0, 1.0);

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Opacity(
            opacity: opacity,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: widget.isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.text,
                  style: AppTextStyles.body(
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
