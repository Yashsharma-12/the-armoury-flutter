import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Global Notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class ThemeService {
  static const String _themeKey = "theme_mode";

  // Load theme from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    
    if (savedTheme == "dark") {
      themeNotifier.value = ThemeMode.dark;
    } else if (savedTheme == "light") {
      themeNotifier.value = ThemeMode.light;
    } else {
      themeNotifier.value = ThemeMode.system;
    }
  }

  // Toggle and Save
  static Future<void> toggleTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_themeKey, "dark");
    } else if (mode == ThemeMode.light) {
      await prefs.setString(_themeKey, "light");
    } else {
      await prefs.remove(_themeKey);
    }
  }
}