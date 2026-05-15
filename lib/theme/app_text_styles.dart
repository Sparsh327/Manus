import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/theme/app_colors.dart';
import 'package:manus/theme/app_fonts.dart';




class AppTextStyles {
  AppTextStyles._();

  static TextStyle ns14w400 = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    fontFamily: AppFonts.openSans,
    color: AppColors.textPrimary,
  );
}
