import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm editorial palette. Supports both light and dark modes via a static
/// brightness toggle so existing widgets don't need to change.
class FtColors {
  static Brightness _brightness = Brightness.light;
  static void setBrightness(Brightness b) => _brightness = b;
  static bool get _dark => _brightness == Brightness.dark;

  /// Beta "Liquid Glass": saat ON, chrome (nav/sheet) dirender sebagai kaca
  /// buram dan background memakai blob gradient (FtLiquidBackground).
  /// Konsumsi statis mengikuti pola [_brightness]; flip via Settings memicu
  /// `ftRebuildAllWidgets()`.
  static bool _liquid = false;
  static void setLiquid(bool on) => _liquid = on;
  static bool get liquid => _liquid;

  // Backgrounds & surfaces
  static Color get bg => _dark ? const Color(0xFF0F0E0B) : const Color(0xFFF1EDE4);
  static Color get bgAlt => _dark ? const Color(0xFF14130F) : const Color(0xFFE9E4D7);
  static Color get surface => _dark ? const Color(0xFF191813) : const Color(0xFFFBF8F1);
  static Color get surfaceAlt => _dark ? const Color(0xFF1F1D17) : const Color(0xFFF6F2E8);

  // Text
  static Color get ink => _dark ? const Color(0xFFf1ede4) : const Color(0xFF1A1814);
  static Color get ink2 => _dark ? const Color(0xFFc8c0b0) : const Color(0xFF4B463D);
  static Color get ink3 => _dark ? const Color(0xFF8a8272) : const Color(0xFF807868);
  static Color get ink4 => _dark ? const Color(0xFF56514a) : const Color(0xFFB8B0A0);

  // Lines
  static Color get line => _dark ? const Color(0x14f1ede4) : const Color(0x141A1814);
  static Color get lineStrong => _dark ? const Color(0x29f1ede4) : const Color(0x291A1814);

  // Accents
  static Color get clay => _dark ? const Color(0xFFe08a4a) : const Color(0xFFC4612A);
  static Color get sage => _dark ? const Color(0xFF8aab92) : const Color(0xFF5E7A64);
  static Color get moss => _dark ? const Color(0xFF6ea088) : const Color(0xFF2D5040);
  static Color get plum => _dark ? const Color(0xFFb56f80) : const Color(0xFF7A3F4E);
  static Color get ochre => _dark ? const Color(0xFFd4ab55) : const Color(0xFFB89030);
  static Color get danger => _dark ? const Color(0xFFd56a6a) : const Color(0xFF9A2F2F);
  static Color get sky => _dark ? const Color(0xFF7aa3bd) : const Color(0xFF3A6075);
  static Color get blush => _dark ? const Color(0xFFE8A8B8) : const Color(0xFFE8B4C0);

  // Health
  static Color get healthOk => _dark ? const Color(0xFF8aab92) : const Color(0xFF5E7A64);
  static Color get healthWarn => _dark ? const Color(0xFFd4ab55) : const Color(0xFFB89030);
  static Color get healthBad => _dark ? const Color(0xFFd56a6a) : const Color(0xFF9A2F2F);

  // Category palette (used by donut + category chips). Light/dark pairs taken
  // from `claude-design/design/theme.jsx`.
  static Color get catFood => _dark ? const Color(0xFFe08a4a) : const Color(0xFFC4612A);
  static Color get catTransport => _dark ? const Color(0xFF8aab92) : const Color(0xFF5E7A64);
  static Color get catBills => _dark ? const Color(0xFFd4ab55) : const Color(0xFFB89030);
  static Color get catShopping => _dark ? const Color(0xFFb56f80) : const Color(0xFF7A3F4E);
  static Color get catEntertainment => _dark ? const Color(0xFF7aa3bd) : const Color(0xFF3A6075);
  static Color get catHealth => _dark ? const Color(0xFF6ea088) : const Color(0xFF2D5040);
  static Color get catOther => _dark ? const Color(0xFF807668) : const Color(0xFFA89880);
}

/// Marks every element dirty so the whole tree rebuilds on the next frame.
///
/// FtColors is read statically at build time all over the app, so flipping
/// the theme only repaints widgets that happen to depend on `Theme` — const
/// subtrees keep their stale colors until something else rebuilds them
/// (previously: a manual refresh). Elements are only marked dirty, never
/// remounted, so navigation/scroll/input state survives. Expensive, but only
/// runs on an explicit theme switch.
void ftRebuildAllWidgets() {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
}

ThemeData buildTheme(Brightness brightness, {bool liquid = false}) {
  FtColors.setBrightness(brightness);
  FtColors.setLiquid(liquid);
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: FtColors.clay,
    onPrimary: Colors.white,
    primaryContainer: isDark ? const Color(0xFF3a2818) : const Color(0xFFE9D9C8),
    onPrimaryContainer: FtColors.ink,
    secondary: FtColors.clay,
    onSecondary: Colors.white,
    secondaryContainer: isDark ? const Color(0xFF3a2818) : const Color(0xFFE9D9C8),
    onSecondaryContainer: FtColors.ink,
    tertiary: FtColors.clay,
    onTertiary: Colors.white,
    tertiaryContainer: isDark ? const Color(0xFF3a2818) : const Color(0xFFE9D9C8),
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

  final sans = GoogleFonts.geistTextTheme();
  TextStyle? tabular(TextStyle? style) => style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  final textTheme = sans.copyWith(
    displayLarge: tabular(sans.displayLarge)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w600, letterSpacing: -1.5),
    displayMedium: tabular(sans.displayMedium)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w600, letterSpacing: -1.0),
    displaySmall: tabular(sans.displaySmall)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w600, letterSpacing: -0.5),
    headlineLarge: tabular(sans.headlineLarge)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.5),
    headlineMedium: tabular(sans.headlineMedium)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.3),
    headlineSmall: tabular(sans.headlineSmall)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500, letterSpacing: -0.3),
    titleLarge: tabular(sans.titleLarge)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500),
    titleMedium: tabular(sans.titleMedium)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500),
    titleSmall: tabular(sans.titleSmall),
    bodyLarge: tabular(sans.bodyLarge)?.copyWith(color: FtColors.ink2),
    bodyMedium: tabular(sans.bodyMedium)?.copyWith(color: FtColors.ink2),
    bodySmall: tabular(sans.bodySmall)?.copyWith(color: FtColors.ink3),
    labelLarge: tabular(sans.labelLarge)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w500),
    labelMedium: tabular(sans.labelMedium)?.copyWith(color: FtColors.ink2),
    labelSmall: tabular(sans.labelSmall)?.copyWith(
        color: FtColors.ink3, letterSpacing: 1.4, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // Liquid: scaffold tembus pandang supaya FtLiquidBackground (dipasang
    // global di app.dart) kelihatan di belakang semua layar.
    scaffoldBackgroundColor: liquid ? Colors.transparent : FtColors.bg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    // Defer to FtTapScale for pressed feedback; bare InkWell instances opt in
    // to ripple locally if they need it.
    splashFactory: NoSplash.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FtFadeUpTransitionsBuilder(),
        TargetPlatform.iOS: _FtFadeUpTransitionsBuilder(),
        TargetPlatform.macOS: _FtFadeUpTransitionsBuilder(),
        TargetPlatform.linux: _FtFadeUpTransitionsBuilder(),
        TargetPlatform.windows: _FtFadeUpTransitionsBuilder(),
        TargetPlatform.fuchsia: _FtFadeUpTransitionsBuilder(),
      },
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered),
      ),
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.dragged)) {
          return FtColors.ink.withValues(alpha: 0.45);
        }
        return FtColors.ink.withValues(alpha: 0.25);
      }),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(6),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FtColors.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: FtColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
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
        side: BorderSide(color: FtColors.line, width: 0.5),
      ),
    ),
    dividerTheme: DividerThemeData(
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
        borderSide: BorderSide(color: FtColors.line, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: FtColors.line, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: FtColors.ink, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: FtColors.danger, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: FtColors.danger, width: 1),
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
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed)) {
            return FtColors.bg.withValues(alpha: 0.12);
          }
          if (s.contains(WidgetState.hovered) ||
              s.contains(WidgetState.focused)) {
            return FtColors.bg.withValues(alpha: 0.08);
          }
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FtColors.ink,
        backgroundColor: FtColors.surface,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: FtColors.lineStrong, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: sans.labelLarge
            ?.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed)) {
            return FtColors.ink.withValues(alpha: 0.06);
          }
          if (s.contains(WidgetState.hovered) ||
              s.contains(WidgetState.focused)) {
            return FtColors.ink.withValues(alpha: 0.04);
          }
          return null;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FtColors.ink2,
        textStyle: sans.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: FtColors.ink,
      foregroundColor: FtColors.bg,
    ),
  );
}

/// Default page transitions builder used by `PageTransitionsTheme`. Covers
/// any imperative `Navigator.push` path that bypasses go_router (e.g.,
/// `showAboutDialog`, plugin-driven flows) so the editorial fade-up stays
/// consistent across the app instead of falling back to platform defaults.
class _FtFadeUpTransitionsBuilder extends PageTransitionsBuilder {
  const _FtFadeUpTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
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
