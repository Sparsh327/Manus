import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickui/quickui.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String buttonText;
  final String illustrationPath;
  final VoidCallback onPressed;

  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.buttonText,
    required this.illustrationPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container_(
        allPadding: 16.w,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image_(
              localSvgAsset: illustrationPath,
              height: 150.h,
              width: 150.h,
            ),
            32.verticalSpace,
            Text(message, textAlign: TextAlign.center),
            24.verticalSpace,
            /*AppPrimaryButton(
              width: double.infinity,
              buttonText: buttonText,
              onClick: onPressed,
            ),
            16.verticalSpace,
            AppSecondaryButton(
              borderColor: AppColors.primary,
              buttonText: ErrorMessages.goBackErrorStateWidget,
              onClick: () {},
            ),*/
          ],
        ),
      ),
    );
  }
}
