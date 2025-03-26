import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardTheme(clipBehavior: Clip.antiAlias),
  );

  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardTheme(clipBehavior: Clip.antiAlias),
  );

  final Map<String, ThemeData> _colorThemes = {
    'blue': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    ),
    'green': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    ),
    'purple': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    ),
    'orange': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    ),
    'red': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardTheme(clipBehavior: Clip.antiAlias),
    ),
    'teal': ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardTheme(clipBehavior: Clip.antiAlias),
    ),
  };

  bool _isDarkMode = false;
  String _colorKey = 'blue';

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _colorKey = prefs.getString('themeColor') ?? 'blue';
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setString('themeColor', _colorKey);
  }

  bool get isDarkMode => _isDarkMode;
  String get colorKey => _colorKey;
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _getThemeByColor();

  List<String> get availableColors => _colorThemes.keys.toList();

  ThemeData _getThemeByColor() {
    if (_colorThemes.containsKey(_colorKey)) {
      return _colorThemes[_colorKey]!;
    }
    return _lightTheme;
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }

  void setColorTheme(String colorKey) {
    if (_colorThemes.containsKey(colorKey)) {
      _colorKey = colorKey;
      _saveSettings();
      notifyListeners();
    }
  }
}
