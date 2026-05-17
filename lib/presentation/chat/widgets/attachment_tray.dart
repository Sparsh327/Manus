import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/theme/app_colors.dart';

enum AttachSourceType { camera, photos, files, screen }

extension AttachSourceTypeX on AttachSourceType {
  String get label => switch (this) {
        AttachSourceType.camera => 'Camera',
        AttachSourceType.photos => 'Photos',
        AttachSourceType.files => 'Files',
        AttachSourceType.screen => 'Screen',
      };

  IconData get icon => switch (this) {
        AttachSourceType.camera => Icons.camera_alt_outlined,
        AttachSourceType.photos => Icons.photo_library_outlined,
        AttachSourceType.files => Icons.folder_outlined,
        AttachSourceType.screen => Icons.screenshot_monitor_outlined,
      };
}

class MockAttachmentItem {
  final String id;
  final AttachSourceType source;
  final String name;

  const MockAttachmentItem({
    required this.id,
    required this.source,
    required this.name,
  });
}

class AttachmentOptionsTray extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  final void Function(AttachSourceType source) onSourceTap;

  const AttachmentOptionsTray({
    super.key,
    required this.isDark,
    required this.cs,
    required this.onSourceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: AttachSourceType.values
            .map(
              (src) => _AttachOptionButton(
                source: src,
                isDark: isDark,
                cs: cs,
                onTap: () => onSourceTap(src),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AttachOptionButton extends StatelessWidget {
  final AttachSourceType source;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _AttachOptionButton({
    required this.source,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Icon(source.icon, size: 24.r, color: cs.onSurface),
          ),
          SizedBox(height: 6.h),
          Text(
            source.label,
            style: TextStyle(fontSize: 11.sp, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class AttachmentThumbnailRow extends StatelessWidget {
  final List<MockAttachmentItem> attachments;
  final void Function(String id) onRemove;

  const AttachmentThumbnailRow({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 80.r,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) => _AttachThumb(
          key: ValueKey(attachments[i].id),
          item: attachments[i],
          onRemove: () => onRemove(attachments[i].id),
        ),
      ),
    );
  }
}

class _AttachThumb extends StatefulWidget {
  final MockAttachmentItem item;
  final VoidCallback onRemove;

  const _AttachThumb({super.key, required this.item, required this.onRemove});

  @override
  State<_AttachThumb> createState() => _AttachThumbState();
}

class _AttachThumbState extends State<_AttachThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 64.r,
        height: 64.r,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.item.source.icon, size: 22.r, color: cs.onSurface),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      widget.item.name,
                      style: TextStyle(fontSize: 9.sp, color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -6.r,
              right: -6.r,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 18.r,
                  height: 18.r,
                  decoration: BoxDecoration(
                    color: cs.onSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 11.r, color: cs.surface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
