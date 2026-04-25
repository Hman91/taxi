import 'package:flutter/material.dart';

/// Visual language aligned with the Streamlit Taxi Pro prototype:
/// warm yellow gradient, red–brown text, dark primary buttons, soft cards.
abstract final class TaxiAppColors {
  TaxiAppColors._();

  /// --taxi-text
  static const Color text = Color(0xFFB91C1C);

  /// --taxi-text-strong
  static const Color textStrong = Color(0xFF991B1B);

  /// --taxi-text-soft
  static const Color textSoft = Color(0xFFC2410C);

  static const Color gradientStart = Color(0xFFFFFEF8);
  static const Color gradientMidA = Color(0xFFFFF3B8);
  static const Color gradientMidB = Color(0xFFFFE14D);
  static const Color gradientEnd = Color(0xFFFFD000);

  /// App bar / chrome (cream glass)
  static const Color appBarFill = Color(0xD9FFF8D2);

  /// Primary / FilledButton — Streamlit primary gradient feel (flat dark)
  static const Color buttonDark = Color(0xFF1A1A1A);
  static const Color buttonDarkTop = Color(0xFF2A2A2A);

  static const Color cardFill = Color(0xB8FFFFFF);
  static const Color cardBorder = Color(0x488B1428);

  /// Unread badge / highlights
  static const Color accentAmber = Color(0xFFD97706);

  /// Streamlit `.taxi-dark-panel` — dispatch / promo strip on dark background
  static const Color darkPanel = Color(0xFF1A1A1A);
}

/// Full-screen background (Streamlit `stApp` gradient).
class TaxiProBackground extends StatelessWidget {
  const TaxiProBackground({super.key, required this.child});

  final Widget child;

  static const BoxDecoration decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        TaxiAppColors.gradientStart,
        TaxiAppColors.gradientMidA,
        TaxiAppColors.gradientMidB,
        TaxiAppColors.gradientEnd,
      ],
      stops: [0.0, 0.28, 0.55, 1.0],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: decoration),
        child,
      ],
    );
  }
}

ThemeData buildTaxiProTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TaxiAppColors.gradientEnd,
    brightness: Brightness.light,
  ).copyWith(
    primary: TaxiAppColors.buttonDark,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE8E8E8),
    onPrimaryContainer: TaxiAppColors.buttonDark,
    secondary: TaxiAppColors.gradientEnd,
    onSecondary: const Color(0xFF2C2C2C),
    secondaryContainer: TaxiAppColors.gradientMidA,
    onSecondaryContainer: TaxiAppColors.textStrong,
    surface: TaxiAppColors.gradientStart,
    onSurface: TaxiAppColors.text,
    onSurfaceVariant: TaxiAppColors.textSoft,
    tertiary: TaxiAppColors.accentAmber,
    onTertiary: Colors.white,
    outline: const Color(0x38B48C00),
    shadow: const Color(0x2E000000),
  );

  final baseText = TextTheme(
    bodyLarge: TextStyle(color: scheme.onSurface, height: 1.35),
    bodyMedium: TextStyle(color: scheme.onSurface, height: 1.35),
    bodySmall: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
    titleLarge: TextStyle(
      color: TaxiAppColors.textStrong,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.02,
    ),
    titleMedium: TextStyle(
      color: TaxiAppColors.textStrong,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: TaxiAppColors.textStrong,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      color: TaxiAppColors.textStrong,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02,
    ),
    labelLarge: TextStyle(
      color: TaxiAppColors.textStrong,
      fontWeight: FontWeight.w600,
    ),
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: baseText,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: true,
      backgroundColor: TaxiAppColors.appBarFill,
      foregroundColor: TaxiAppColors.textStrong,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: TaxiAppColors.textStrong),
      titleTextStyle: baseText.titleLarge?.copyWith(fontSize: 19),
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      surfaceTintColor: Colors.transparent,
      color: TaxiAppColors.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: TaxiAppColors.cardBorder),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x38785A00),
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withOpacity(0.72),
      side: const BorderSide(color: Color(0x488B1428)),
      labelStyle: TextStyle(
        color: TaxiAppColors.textStrong,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TaxiAppColors.buttonDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade400,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: buttonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TaxiAppColors.buttonDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TaxiAppColors.textStrong,
        side: const BorderSide(color: Color(0x668B1428)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TaxiAppColors.textStrong,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x44B48C00)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x44B48C00)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TaxiAppColors.textStrong.withOpacity(0.85)),
      ),
      labelStyle: TextStyle(color: TaxiAppColors.textStrong.withOpacity(0.9)),
      floatingLabelStyle: const TextStyle(
        color: TaxiAppColors.textStrong,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TaxiAppColors.buttonDark,
      foregroundColor: Colors.white,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: TaxiAppColors.textStrong,
      textColor: TaxiAppColors.text,
      titleTextStyle: baseText.titleMedium,
    ),
    iconTheme: const IconThemeData(color: TaxiAppColors.textStrong),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white.withOpacity(0.97),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: baseText.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: TaxiAppColors.textStrong,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: TaxiAppColors.textStrong,
      unselectedLabelColor: TaxiAppColors.text.withOpacity(0.75),
      indicatorColor: TaxiAppColors.textStrong,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TaxiAppColors.textStrong,
    ),
  );
}
