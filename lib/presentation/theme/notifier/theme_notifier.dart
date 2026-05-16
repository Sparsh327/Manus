import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:manus/data/data_sources/local/hive_service.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = Hive.box(HiveService.settingsBox).get(_key) as String?;
    return _fromString(stored);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    Hive.box(HiveService.settingsBox).put(_key, mode.name);
  }

  ThemeMode _fromString(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
