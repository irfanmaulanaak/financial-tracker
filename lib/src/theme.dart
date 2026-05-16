import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm editorial palette from `claude-design/theme.jsx` (light variant).
/// Newsreader serif for display/numerals, Geist sans for body/buttons.
class FtColors {
  static const bg = Color(0xFFF1EDE4); // warm cream paper
  static const bgAlt = Color(0xFFE9E4D7); // deeper cream chips
  static const surface = Color(0xFFFBF8F1); // card surface
  static const surfaceAlt = Color(0xFFF6F2E8);
  static const ink = Color(0xFF1A1814); // near-black warm
  static const ink2 = Color(0xFF4B463D); // body
  static const ink3 = Color(0xFF807868); // secondary
  static const ink4 = Color(0xFFB8B0A0); // tertiary
  static const line = Color(0x141A1814); // 8% ink
  static const lineStrong = Color(0x291A1814); // 16% ink

  static const clay = Color(0xFFC4612A); // primary warm accent
  static const sage = Color(0xFF5E7A64); // positive
  static const moss = Color(0xFF2D5040); // deep positive
  static const plum = Color(0xFF7A3F4E); // accent
  static const ochre = Color(0xFFB89030); // warning
  static const danger = Color(0xFF9A2F2F);
  static const sky = Color(0xFF3A6075);
}

ThemeData buildTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: FtColors.clay,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE9D9C8),
    onPrimaryContainer: FtColors.ink,
    secondary: FtColors.sage,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFD9E2DC),
    onSecondaryContainer: FtColors.ink,
    tertiary: FtColors.sky,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFD6E2EA),
    onTertiaryContainer: FtColors.ink,
    error: FtColors.danger,
    onError: Colors.white,
    surface: FtColors.bg,
    onSurface: FtColors.ink,
    surfaceContainerHighest: FtColors.surfaceAlt,
    surfaceContainerHigh: FtColors.surface,
    surfaceContainer: FtColors.bgAlt,
    onSurfaceVariant: FtColors.ink3,
    outline: FtColors.lineStrong,
    outlineVariant: FtColors.line,
  );

  final sans = GoogleFonts.interTextTheme(); // close to Geist; bundled-friendly fallback below
  final serif = GoogleFonts.newsreaderTextTheme();

  final textTheme = sans.copyWith(
    displayLarge: serif.displayLarge?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -1.5),
    displayMedium: serif.displayMedium?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -1.0),
    displaySmall: serif.displaySmall?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.5),
    headlineLarge: serif.headlineLarge?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.5),
    headlineMedium: serif.headlineMedium?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.3),
    headlineSmall: serif.headlineSmall?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.3),
    titleLarge: serif.titleLarge?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500),
    titleMedium: sans.titleMedium?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500),
    bodyLarge: sans.bodyLarge?.copyWith(color: FtColors.ink2),
    bodyMedium: sans.bodyMedium?.copyWith(color: FtColors.ink2),
    bodySmall: sans.bodySmall?.copyWith(color: FtColors.ink3),
    labelLarge: sans.labelLarge?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500),
    labelMedium: sans.labelMedium?.copyWith(color: FtColors.ink2),
    labelSmall: sans.labelSmall?.copyWith(
        color: FtColors.ink3, letterSpacing: 1.4, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FtColors.bg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: FtColors.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: FtColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: serif.titleLarge?.copyWith(
        color: FtColors.ink,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: FtColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: FtColors.line, width: 0.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: FtColors.line,
      space: 1,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FtColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FtColors.line, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FtColors.line, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FtColors.ink, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FtColors.danger, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FtColors.danger, width: 1),
      ),
      labelStyle: sans.bodyMedium?.copyWith(color: FtColors.ink3),
      hintStyle: sans.bodyMedium?.copyWith(color: FtColors.ink4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FtColors.ink,
        foregroundColor: FtColors.bg,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: sans.labelLarge
            ?.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FtColors.ink,
        backgroundColor: FtColors.surface,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: FtColors.lineStrong, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: sans.labelLarge
            ?.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FtColors.ink2,
        textStyle: sans.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: FtColors.ink,
      foregroundColor: FtColors.bg,
    ),
  );
}

/// Small uppercase "eyebrow" label used above sections + form fields.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        letterSpacing: 1.4,
        color: color ?? FtColors.ink3,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
