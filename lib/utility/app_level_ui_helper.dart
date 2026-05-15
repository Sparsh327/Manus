import 'package:flutter/cupertino.dart';

class AppLevelUiHelper {
  AppLevelUiHelper._();

  static void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
