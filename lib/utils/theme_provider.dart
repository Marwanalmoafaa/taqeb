
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مزود لإدارة الثيم وحفظ تفضيلات المستخدم
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;
  bool get useSystemTheme => _useSystemTheme;

  // الحصول على الوضع الحالي (داكن أم فاتح)
  bool get isDarkMode {
    if (_useSystemTheme) {
      // استخدام وضع النظام
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    // استخدام الوضع المحدد من قبل المستخدم
    return _themeMode == ThemeMode.dark;
  }

  // تبديل بين الوضع الداكن والفاتح
  void toggleThemeMode() {
    _useSystemTheme = false;
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }

  // ضبط الوضع على الداكن
  void setDarkMode() {
    _useSystemTheme = false;
    _themeMode = ThemeMode.dark;
    _saveThemePreference();
    notifyListeners();
  }

  // ضبط الوضع على الفاتح
  void setLightMode() {
    _useSystemTheme = false;
    _themeMode = ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }

  // ضبط الوضع على وضع النظام
  void setSystemTheme() {
    _useSystemTheme = true;
    _themeMode = ThemeMode.system;
    _saveThemePreference();
    notifyListeners();
  }

  // حفظ تفضيلات الثيم
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', _useSystemTheme);
    await prefs.setString('themeMode', _themeMode.toString());
  }

  // تحميل تفضيلات الثيم
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;

    final themeModeStr = prefs.getString('themeMode');
    if (themeModeStr != null) {
      if (themeModeStr.contains('dark')) {
        _themeMode = ThemeMode.dark;
      } else if (themeModeStr.contains('light')) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    notifyListeners();
  }
}
