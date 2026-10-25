import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// System, light, or dark. Persisted so the choice survives a restart.
class ThemeChoice extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  static const storageKey = 'bloom.theme';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(storageKey);
    final next = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (next == mode) return;
    mode = next;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    if (value == mode) return;
    mode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
