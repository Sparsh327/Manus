import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_fonts.dart';

class CodeBlockWidget extends StatelessWidget {
  final String code;
  final String? language;

  const CodeBlockWidget({super.key, required this.code, this.language});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F0);
    final fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFDDDDDD),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(language: language, code: code, fg: fg),
          Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
              child: SelectableText(
                code,
                style: AppFonts.monospace(fontSize: 13.sp, color: fg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatefulWidget {
  final String? language;
  final String code;
  final Color fg;

  const _Header({this.language, required this.code, required this.fg});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
      child: Row(
        children: [
          if (widget.language != null)
            Text(
              widget.language!,
              style: TextStyle(
                fontSize: 11.sp,
                color: widget.fg.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: _copy,
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _copied ? Icons.check : Icons.copy_outlined,
                    size: 14.r,
                    color: widget.fg.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _copied ? 'Copied' : 'Copy',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: widget.fg.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
