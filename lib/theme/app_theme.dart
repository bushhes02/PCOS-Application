import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  OVARRIOR COLOR SYSTEM
//  Based on brand identity: Coral (warmth), Sage (health), Honey (achievement)
// ═════════════════════════════════════════════════════════════════════════════
class OvColors {
  // ───────────────────────────────────────────────────────────────────────────
  //  LIGHT MODE COLORS
  // ───────────────────────────────────────────────────────────────────────────
  
  // Backgrounds
  static const bgLight      = Color(0xFFFFF7F2);  // Warm cream
  static const surfaceLight = Color(0xFFFFFFFF);  // White cards
  
  // Text
  static const inkLight     = Color(0xFF1E1610);  // Dark brown (high contrast)
  static const inkMuted     = Color(0xFF6B5D54);  // Muted brown (secondary text)
  
  // ───────────────────────────────────────────────────────────────────────────
  //  BRAND COLORS - PRIMARY PALETTE
  // ───────────────────────────────────────────────────────────────────────────
  
  // Coral/Pink - MAIN BRAND COLOR (from Polly)
  static const coral        = Color(0xFFF4826A);  // Primary actions, AppBar
  static const coralDark    = Color(0xFFE06B55);  // Pressed states
  static const coralLight   = Color(0xFFFFF3F0);  // Light backgrounds
  
  // Sage/Green - HEALTH & SUCCESS (from Polly)
  static const sage         = Color(0xFF4CAF7D);  // Success, healthy choices
  static const sageDark     = Color(0xFF3D9E6A);  // Pressed states
  static const sageLight    = Color(0xFFE8F5ED);  // Light backgrounds
  
  // Honey/Gold - REWARDS & ACHIEVEMENTS (from Polly)
  static const honey        = Color(0xFFFFCC00);  // Streaks, points, XP
  static const honeyDark    = Color(0xFFE6B800);  // Pressed states
  static const honeyLight   = Color(0xFFFFF9E6);  // Light backgrounds
  
  // ───────────────────────────────────────────────────────────────────────────
  //  FUNCTIONAL COLORS - SECONDARY PALETTE
  // ───────────────────────────────────────────────────────────────────────────
  
  // Sky Blue - UTILITY (water tracking, info)
  static const sky          = Color(0xFF4A9FE8);  // Softer than Material blue
  static const skyLight     = Color(0xFFEBF5FC);  // Light tint
  
  // Lavender - SECONDARY ACTIONS (replaces deepPurple)
  static const lavender     = Color(0xFF9B7EDE);  // Softer, warmer purple
  static const lavenderLight= Color(0xFFF3EFFC);  // Light tint
  
  // ───────────────────────────────────────────────────────────────────────────
  //  NEUTRALS (Light Mode)
  // ───────────────────────────────────────────────────────────────────────────
  
  static const grey50       = Color(0xFFFAFAFA);
  static const grey100      = Color(0xFFF5F5F5);
  static const grey200      = Color(0xFFEEEEEE);
  static const grey400      = Color(0xFFBDBDBD);
  static const grey600      = Color(0xFF757575);
  
  // ───────────────────────────────────────────────────────────────────────────
  //  DARK MODE COLORS
  // ───────────────────────────────────────────────────────────────────────────
  
  // Backgrounds (warmer, more layered)
  static const bgDark       = Color(0xFF1A1614);  // Warm dark brown (not grey)
  static const surfaceDark  = Color(0xFF2D2825);  // Card surface (distinct from bg)
  static const surfaceRaised= Color(0xFF3A3532);  // Elevated cards, AppBar
  
  // Text
  static const inkDark      = Color(0xFFF5EDE4);  // Warm white (not pure white)
  static const inkMutedDark = Color(0xFFB8ADA4);  // Muted text
  
  // Brand Colors (vibrant for dark mode)
  static const coralDM      = Color(0xFFFF9B85);  // Lighter, more vibrant
  static const sageDM       = Color(0xFF5FD99B);  // Lighter, more vibrant
  static const honeyDM      = Color(0xFFFFD633);  // Lighter, more vibrant
  
  // Functional (adjusted for dark)
  static const skyDM        = Color(0xFF6BB5F5);  // Lighter blue
  static const lavenderDM   = Color(0xFFB39DEB);  // Lighter purple
  
  // Neutrals (dark)
  static const grey800      = Color(0xFF424242);
  static const grey700      = Color(0xFF616161);
  static const grey500      = Color(0xFF9E9E9E);
}

// ═════════════════════════════════════════════════════════════════════════════
//  THEME STATE — In-memory dark mode preference
// ═════════════════════════════════════════════════════════════════════════════
class ThemeState extends ChangeNotifier {
  static final ThemeState instance = ThemeState._();
  ThemeState._();

  bool _dark = false;
  bool get isDark => _dark;

  void toggle() {
    _dark = !_dark;
    notifyListeners();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  LIGHT THEME
// ═════════════════════════════════════════════════════════════════════════════
ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: OvColors.bgLight,
  
  colorScheme: const ColorScheme.light(
    primary:   OvColors.coral,      // Main brand color
    secondary: OvColors.sage,       // Success/health
    tertiary:  OvColors.honey,      // Rewards/achievements
    surface:   OvColors.surfaceLight,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: OvColors.inkLight,
  ),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: OvColors.coral,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: Colors.white,
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: OvColors.coral,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  
  cardColor: OvColors.surfaceLight,
  dividerColor: OvColors.grey200,
  useMaterial3: false,
);

// ═════════════════════════════════════════════════════════════════════════════
//  DARK THEME
// ═════════════════════════════════════════════════════════════════════════════
ThemeData darkTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: OvColors.bgDark,
  
  colorScheme: const ColorScheme.dark(
    primary:   OvColors.coralDM,
    secondary: OvColors.sageDM,
    tertiary:  OvColors.honeyDM,
    surface:   OvColors.surfaceDark,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: OvColors.inkDark,
  ),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: OvColors.surfaceRaised,  // Distinct from background
    foregroundColor: OvColors.inkDark,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: OvColors.inkDark,
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: OvColors.coralDM,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  
  cardColor: OvColors.surfaceDark,
  dividerColor: OvColors.grey700,
  useMaterial3: false,
);
