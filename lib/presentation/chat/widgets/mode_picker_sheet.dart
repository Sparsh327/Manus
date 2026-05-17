import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/theme/app_colors.dart';

enum ChatMode { chat, agent, browse, image }

extension ChatModeX on ChatMode {
  String get label => switch (this) {
        ChatMode.chat => 'Chat',
        ChatMode.agent => 'Agent',
        ChatMode.browse => 'Browse',
        ChatMode.image => 'Image',
      };

  IconData get icon => switch (this) {
        ChatMode.chat => Icons.chat_bubble_outline_rounded,
        ChatMode.agent => Icons.smart_toy_outlined,
        ChatMode.browse => Icons.travel_explore_rounded,
        ChatMode.image => Icons.image_outlined,
      };

  String get description => switch (this) {
        ChatMode.chat => 'Standard conversation mode',
        ChatMode.agent => 'Let Manus autonomously complete tasks',
        ChatMode.browse => 'Search the web in real time',
        ChatMode.image => 'Generate or analyze images',
      };
}

Future<ChatMode?> showModePickerSheet(BuildContext context, ChatMode current) {
  return showModalBottomSheet<ChatMode>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _ModePickerSheet(current: current),
  );
}

class _ModePickerSheet extends StatelessWidget {
  final ChatMode current;
  const _ModePickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Mode',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            ...ChatMode.values.map(
              (mode) => _ModeRow(
                mode: mode,
                isSelected: mode == current,
                isDark: isDark,
                cs: cs,
                onTap: () => Navigator.of(context).pop(mode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final ChatMode mode;
  final bool isSelected;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _ModeRow({
    required this.mode,
    required this.isSelected,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              mode.icon,
              size: 22.r,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    mode.description,
                    style: TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_rounded, size: 18.r, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
