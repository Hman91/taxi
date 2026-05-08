// ═══════════════════════════════════════════════════════════════
// TAXI TUNISIA — Yellow Theme Design System
// Tunisian taxi yellow · charcoal dark buttons · warm & bold
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ── Palette ───────────────────────────────────────────────────
class TaxiColors {
  TaxiColors._();

  // Core brand
  static const yellow       = Color(0xFFFFC200);  // Tunisian taxi yellow
  static const yellowLight  = Color(0xFFFFD84D);  // highlight
  static const yellowDeep   = Color(0xFFE6A800);  // pressed / border
  static const yellowSoft   = Color(0xFFFFF3CC);  // tint backgrounds

  // Dark UI (buttons, headers, nav)
  static const charcoal     = Color(0xFF1A1A1A);  // near-black primary
  static const charcoalMid  = Color(0xFF2C2C2C);  // elevated surface dark
  static const charcoalSoft = Color(0xFF3D3D3D);  // border / divider dark

  // Backgrounds
  static const bgWarm       = Color(0xFFFAF8F2);  // warm off-white page bg
  static const surface      = Color(0xFFFFFFFF);  // card surface
  static const surfaceAlt   = Color(0xFFF5F1E8);  // secondary surface

  // Semantic
  static const success      = Color(0xFF1A7A4A);  // dark green
  static const successBg    = Color(0xFFD4EDDA);
  static const danger       = Color(0xFFB91C1C);
  static const dangerBg     = Color(0xFFFFE4E4);
  static const info         = Color(0xFF1E3A8A);
  static const infoBg       = Color(0xFFDEEBFF);
  static const warning      = Color(0xFFB45309);
  static const warningBg    = Color(0xFFFEF3C7);

  // Text
  static const textStrong   = Color(0xFF111111);
  static const textMid      = Color(0xFF3F3F3F);
  static const textSoft     = Color(0xFF5C5C5C);
  static const textOnYellow = Color(0xFF111111);  // text on yellow bg
  static const textOnDark   = Color(0xFFF5F5F5);  // text on charcoal bg
}

// ── Shadows ───────────────────────────────────────────────────
List<BoxShadow> taxiShadow({Color? color, double blur = 12, double spread = 0, Offset offset = const Offset(0, 4)}) => [
  BoxShadow(
    color: (color ?? TaxiColors.charcoal).withOpacity(0.10),
    blurRadius: blur,
    spreadRadius: spread,
    offset: offset,
  ),
];

List<BoxShadow> yellowGlow({double blur = 16}) => [
  BoxShadow(color: TaxiColors.yellow.withOpacity(0.35), blurRadius: blur, offset: const Offset(0, 4)),
];

// ── Theme ─────────────────────────────────────────────────────
ThemeData taxiTunisiaTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: TaxiColors.bgWarm,
    colorScheme: const ColorScheme.light(
      primary: TaxiColors.yellow,
      onPrimary: TaxiColors.textOnYellow,
      secondary: TaxiColors.charcoal,
      onSecondary: TaxiColors.textOnDark,
      tertiary: TaxiColors.success,
      error: TaxiColors.danger,
      surface: TaxiColors.surface,
      onSurface: TaxiColors.textStrong,
    ),
    cardTheme: CardThemeData(
      color: TaxiColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shadowColor: TaxiColors.charcoal,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TaxiColors.charcoal,
      foregroundColor: TaxiColors.textOnDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: TaxiColors.yellow),
      actionsIconTheme: IconThemeData(color: TaxiColors.yellow),
      titleTextStyle: TextStyle(
        color: TaxiColors.textOnDark,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: TaxiColors.yellow,
      unselectedLabelColor: TaxiColors.textSoft,
      indicatorColor: TaxiColors.yellow,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TaxiColors.surfaceAlt,
      labelStyle: const TextStyle(color: TaxiColors.textMid, fontSize: 13),
      hintStyle: const TextStyle(color: TaxiColors.textSoft),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDD8C8), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TaxiColors.yellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TaxiColors.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TaxiColors.charcoal,
        foregroundColor: TaxiColors.textOnDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TaxiColors.charcoal,
        side: const BorderSide(color: TaxiColors.charcoalSoft, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: TaxiColors.charcoal),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TaxiColors.surfaceAlt,
      labelStyle: const TextStyle(color: TaxiColors.textMid, fontSize: 12, fontWeight: FontWeight.w600),
      side: const BorderSide(color: Color(0xFFDDD8C8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFEEE9D8), thickness: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? TaxiColors.yellow : Colors.grey.shade400),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? TaxiColors.yellowDeep.withOpacity(0.4) : Colors.grey.shade200),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: TaxiColors.yellow,
      thumbColor: TaxiColors.yellow,
      inactiveTrackColor: Color(0xFFDDD8C8),
    ),
    iconTheme: const IconThemeData(color: TaxiColors.charcoal),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: TaxiColors.textStrong, fontWeight: FontWeight.w900, fontSize: 30),
      headlineMedium: TextStyle(color: TaxiColors.textStrong, fontWeight: FontWeight.w800, fontSize: 24),
      titleLarge: TextStyle(color: TaxiColors.textStrong, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium: TextStyle(color: TaxiColors.textStrong, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge: TextStyle(color: TaxiColors.textStrong, fontSize: 15),
      bodyMedium: TextStyle(color: TaxiColors.textMid, fontSize: 13),
      bodySmall: TextStyle(color: TaxiColors.textSoft, fontSize: 11, letterSpacing: 0.2),
      labelLarge: TextStyle(color: TaxiColors.textStrong, fontWeight: FontWeight.w700, fontSize: 14),
    ),
  );
}