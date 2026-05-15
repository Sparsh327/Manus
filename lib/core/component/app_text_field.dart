import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? errorText;

  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onEditingComplete,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      autofocus: autofocus,
      style: TextStyle(fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: prefix,
        suffixIcon: suffix,
        errorText: errorText,
      ),
    );
  }
}
