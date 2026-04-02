import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    if (isDark) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
