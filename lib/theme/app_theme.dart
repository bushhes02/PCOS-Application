import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ─────────────────────────────────────────────────────────
//  Ovarrior Colour Tokens
// ─────────────────────────────────────────────────────────
class OvColors {
  // Light
  static const bgLight      = Color(0xFFFFF7F2);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const inkLight     = Color(0xFF1E1610);

  // Dark
  static const bgDark      = Color(0xFF121214);
  static const surfaceDark = Color(0xFF2A2A2C);
  static const inkDark     = Color(0xFFF0EBE4);

  // Shared accent
  static const pink  = Color(0xFFF4826A);  // Femme Pink  — primary buttons, AppBar
  static const pinkD = Color(0xFFE06B55);  // dark variant
  static const green = Color(0xFF4CAF7D);  // Health Green — progress bars
  static const greenD= Color(0xFF3D9E6A);
  static const gold  = Color(0xFFFFCC00);  // XP / streaks / rewards
  static const goldD = Color(0xFFE6B800);
}

// ─────────────────────────────────────────────────────────
//  ThemeState — persisted dark-mode preference
// ─────────────────────────────────────────────────────────
class ThemeState extends ChangeNotifier {
  static final ThemeState instance = ThemeState._();
  ThemeState._() {
    _dark = Hive.box('userData').get('darkMode', defaultValue: false) as bool;
  }

  bool _dark = false;
  bool get isDark => _dark;

  void toggle() {
    _dark = !_dark;
    Hive.box('userData').put('darkMode', _dark);
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────
//  Light & Dark ThemeData
// ─────────────────────────────────────────────────────────
ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: OvColors.bgLight,
  colorScheme: const ColorScheme.light(
    primary:   Color(0xFFF4826A),
    secondary: Color(0xFF4CAF7D),
    surface:   Color(0xFFFFFFFF),
    onPrimary: Colors.white,
    onSurface: Color(0xFF1E1610),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF4826A),
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFF4826A),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  cardColor: Color(0xFFFFFFFF),
  dividerColor: const Color(0xFFEEEEEE),
  useMaterial3: false,
);

ThemeData darkTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: OvColors.bgDark,
  colorScheme: const ColorScheme.dark(
    primary:   Color(0xFFE06B55),
    secondary: Color(0xFF3D9E6A),
    surface:   Color(0xFF2A2A2C),
    onPrimary: Colors.white,
    onSurface: Color(0xFFF0EBE4),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E20),
    foregroundColor: Color(0xFFF0EBE4),
    elevation: 0,
    titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFFF0EBE4)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE06B55),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  cardColor: const Color(0xFF2A2A2C),
  dividerColor: const Color(0xFF333336),
  useMaterial3: false,
);
