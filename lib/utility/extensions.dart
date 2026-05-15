import 'package:flutter/cupertino.dart';

extension MediaQueryProvider on BuildContext {
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  EdgeInsets get padding => MediaQuery.of(this).padding;

  double get statusBarHeight => padding.top;

  double get height => MediaQuery.of(this).size.height;

  double get width => MediaQuery.of(this).size.width;
}
