import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manus/router/app_routes.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.chevron_left, size: 28.r, color: cs.onSurface),
        ),
        title: Text(
          'manus',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 24.r,
                  color: cs.onSurface,
                ),
              ),
              Positioned(
                top: 8.r,
                right: 8.r,
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          SizedBox(height: 24.h),
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44.r,
              backgroundColor: const Color(0xFFE8541A),
              child: Text(
                'S',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Center(
            child: Text(
              'sparsh jaiswal',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Center(
            child: Text(
              'sparsh.jas07@gmail.com',
              style: AppTextStyles.body(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(height: 24.h),
          // Plan card
          _Card(
            isDark: isDark,
            cs: cs,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                child: Row(
                  children: [
                    Text(
                      'Free',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.subscription),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Upgrade',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _SettingsRow(
                icon: Icons.auto_awesome_outlined,
                label: 'Credits',
                trailing: '278',
                cs: cs,
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Account
          _Card(
            isDark: isDark,
            cs: cs,
            children: [
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                label: 'Account',
                cs: cs,
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Feature settings
          _Card(
            isDark: isDark,
            cs: cs,
            children: [
              _SettingsRow(
                icon: Icons.schedule_outlined,
                label: 'Scheduled tasks',
                cs: cs,
                onTap: () {},
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _SettingsRow(
                icon: Icons.menu_book_outlined,
                label: 'Knowledge',
                cs: cs,
                onTap: () {},
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _SettingsRow(
                icon: Icons.forward_to_inbox_outlined,
                label: 'Mail Manus',
                cs: cs,
                onTap: () {},
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _SettingsRow(
                icon: Icons.storage_outlined,
                label: 'Data controls',
                cs: cs,
                onTap: () {},
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _SettingsRow(
                icon: Icons.web_outlined,
                label: 'Cloud Browser',
                cs: cs,
                onTap: () {},
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _SettingsRow(
                icon: Icons.extension_outlined,
                label: 'Skills',
                cs: cs,
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  final List<Widget> children;

  const _Card({required this.isDark, required this.cs, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.cs,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: cs.onSurface),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(color: cs.onSurface),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTextStyles.body(color: cs.onSurfaceVariant),
              ),
            SizedBox(width: 6.w),
            Icon(Icons.chevron_right, size: 18.r, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
