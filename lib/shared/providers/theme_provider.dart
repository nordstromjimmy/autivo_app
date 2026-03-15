import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Theme mode options
enum AppThemeMode { light, dark, system }

/// Extension to convert to ThemeMode
extension AppThemeModeExtension on AppThemeMode {
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Ljust';
      case AppThemeMode.dark:
        return 'Mörkt';
      case AppThemeMode.system:
        return 'Systemstandard';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// Theme notifier that persists theme preference
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _boxName = 'app_settings';
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(AppThemeMode.system) {
    _loadTheme();
  }

  /// Load theme from storage
  Future<void> _loadTheme() async {
    try {
      final box = await _getBox();
      final savedTheme = box.get(_themeKey, defaultValue: 'system') as String;

      state = _stringToThemeMode(savedTheme);
    } catch (e) {
      print('❌ Error loading theme: $e');
      state = AppThemeMode.system;
    }
  }

  /// Save theme to storage
  Future<void> _saveTheme(AppThemeMode mode) async {
    try {
      final box = await _getBox();
      await box.put(_themeKey, _themeModeToString(mode));
    } catch (e) {
      print('❌ Error saving theme: $e');
    }
  }

  /// Get or open Hive box
  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    } else {
      return await Hive.openBox(_boxName);
    }
  }

  /// Convert string to theme mode
  AppThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  /// Convert theme mode to string
  String _themeModeToString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await _saveTheme(mode);
  }
}

/// Provider for theme mode
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeMode>(
      (ref) => ThemeNotifier(),
    );

/// Provider for ThemeMode (what MaterialApp uses)
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appThemeMode = ref.watch(themeNotifierProvider);
  return appThemeMode.toThemeMode();
});
