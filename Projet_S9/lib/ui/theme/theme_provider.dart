import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mama_palette.dart';
import 'mama_theme.dart';

class MamaThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'mama_theme_color';
  MamaThemeColor _current = MamaThemeColor.purple;

  MamaThemeProvider() {
    _loadSavedTheme();
  }

  MamaThemeColor get current => _current;
  MamaThemeColor get currentColor => _current;

  ThemeData get theme {
    final colorPair = mamaThemeColors[_current]!;
    return buildMamaTheme(colorPair.primary, colorPair.secondary);
  }

  void setTheme(MamaThemeColor color) {
    _current = color;
    notifyListeners();
    _persistTheme(color);
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        final found = MamaThemeColor.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => _current,
        );
        if (found != _current) {
          _current = found;
          notifyListeners();
        }
      }
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<void> _persistTheme(MamaThemeColor color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, color.name);
    } catch (_) {
      // ignore persistence errors
    }
  }
}
