import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Futuristic + cute visual language.
/// Dark neon surfaces, cyan/violet accents, soft glows.
abstract final class TaxiAppColors {
  TaxiAppColors._();

  static const Color text = Color(0xFF111111);

  static const Color textStrong = Color(0xFF111111);

  static const Color textSoft = Color(0xFF4F4F4F);

  static const Color gradientStart = Color(0xFF070912);
  static const Color gradientMidA = Color(0xFF0C1122);
  static const Color gradientMidB = Color(0xFF11162C);
  static const Color gradientEnd = Color(0xFF0D1020);

  /// App bar / chrome (dark glass)
  static const Color appBarFill = Color(0xCC0F1428);

  /// Primary / FilledButton
  static const Color buttonDark = Color(0xFF00E5FF);
  static const Color buttonDarkTop = Color(0xFF9D4EDD);

  static const Color cardFill = Color(0xCC131A33);
  static const Color cardBorder = Color(0x553F4D7A);

  /// Unread badge / highlights
  static const Color accentAmber = Color(0xFFFFB703);

  static const Color darkPanel = Color(0xFF0F1326);
}

/// Full-screen neon background.
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
      stops: [0.0, 0.35, 0.68, 1.0],
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
    seedColor: TaxiAppColors.buttonDark,
    brightness: Brightness.light,
  ).copyWith(
    primary: TaxiAppColors.buttonDark,
    onPrimary: const Color(0xFF060910),
    primaryContainer: const Color(0xFF1A2342),
    onPrimaryContainer: TaxiAppColors.textStrong,
    secondary: TaxiAppColors.buttonDarkTop,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFF211739),
    onSecondaryContainer: TaxiAppColors.textStrong,
    surface: const Color(0xFFFFFFFF),
    onSurface: TaxiAppColors.text,
    onSurfaceVariant: TaxiAppColors.textSoft,
    tertiary: TaxiAppColors.accentAmber,
    onTertiary: const Color(0xFF111111),
    outline: const Color(0x4A4C5C88),
    shadow: const Color(0x50000000),
  );

  final baseText = TextTheme(
    bodyLarge: TextStyle(color: scheme.onSurface, height: 1.35),
    bodyMedium: TextStyle(color: scheme.onSurface, height: 1.35),
    bodySmall: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
    titleLarge: TextStyle(
      color: TaxiAppColors.textStrong,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.01,
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

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));

  final themedText = GoogleFonts.notoSansTextTheme(baseText);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: themedText,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
      backgroundColor: TaxiAppColors.appBarFill,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: baseText.titleLarge?.copyWith(fontSize: 19, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.22),
      surfaceTintColor: Colors.transparent,
      color: TaxiAppColors.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: TaxiAppColors.cardBorder),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
        foregroundColor: const Color(0xFF050910),
        disabledBackgroundColor: Colors.grey.shade400,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: buttonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.35),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TaxiAppColors.buttonDark,
        foregroundColor: const Color(0xFF050910),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TaxiAppColors.buttonDark,
        side: const BorderSide(color: Color(0x6600E5FF), width: 1.3),
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
      fillColor: const Color(0xFF1A2340),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x66485A89)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x66485A89)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: TaxiAppColors.buttonDark.withOpacity(0.9), width: 1.6),
      ),
      labelStyle: TextStyle(color: TaxiAppColors.textSoft.withOpacity(0.95)),
      floatingLabelStyle: const TextStyle(
        color: TaxiAppColors.buttonDark,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TaxiAppColors.buttonDark,
      foregroundColor: Colors.white,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: TaxiAppColors.text,
      textColor: TaxiAppColors.text,
      titleTextStyle: baseText.titleMedium,
    ),
    iconTheme: const IconThemeData(color: TaxiAppColors.text),
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
      labelColor: TaxiAppColors.text,
      unselectedLabelColor: TaxiAppColors.textSoft,
      indicatorColor: TaxiAppColors.text,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TaxiAppColors.textStrong,
    ),
  );
}
