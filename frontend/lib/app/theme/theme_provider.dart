import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists theme mode in Hive and provides it via Riverpod.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.dark) {
    _loadSavedTheme();
  }

  void _loadSavedTheme() {
    final box = Hive.box(_boxName);
    final savedMode = box.get(_themeKey, defaultValue: 'dark');
    state = savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final box = Hive.box(_boxName);
    await box.put(_themeKey, newMode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(_boxName);
    await box.put(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
