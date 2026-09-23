import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm "Ceria keluarga" palette. Supports both light and dark modes via a static
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

  // Backgrounds & surfaces. "Ceria keluarga" palette (Sep 2026): cream
  // canvas + white cards in light, warm cocoa in dark.
  static Color get bg => _dark ? const Color(0xFF15110E) : const Color(0xFFFFF6EC);
  static Color get bgAlt => _dark ? const Color(0xFF1A1512) : const Color(0xFFF7EADB);
  static Color get surface => _dark ? const Color(0xFF211B17) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => _dark ? const Color(0xFF2A221D) : const Color(0xFFFBF1E6);

  // Text
  static Color get ink => _dark ? const Color(0xFFF6ECE4) : const Color(0xFF2A160C);
  static Color get ink2 => _dark ? const Color(0xFFD9C8BC) : const Color(0xFF5A4033);
  static Color get ink3 => _dark ? const Color(0xFFB39E90) : const Color(0xFF7A5A48);
  static Color get ink4 => _dark ? const Color(0xFF6E5E54) : const Color(0xFFB8A294);

  // Lines
  static Color get line => _dark ? const Color(0x14F6ECE4) : const Color(0x142A160C);
  static Color get lineStrong => _dark ? const Color(0x29F6ECE4) : const Color(0x292A160C);

  // Accents. `clay` stays the single action accent (links, selection).
  static Color get clay => _dark ? const Color(0xFFFFB38A) : const Color(0xFFB8431F);
  static Color get sage => _dark ? const Color(0xFF9FD8B5) : const Color(0xFF2E6B46);
  static Color get moss => _dark ? const Color(0xFF7FC4A0) : const Color(0xFF235A3E);
  static Color get plum => _dark ? const Color(0xFFF29AA5) : const Color(0xFFA02631);
  static Color get ochre => _dark ? const Color(0xFFE6D48E) : const Color(0xFF9A7A12);
  static Color get danger => _dark ? const Color(0xFFF29AA5) : const Color(0xFFA02631);
  static Color get sky => _dark ? const Color(0xFFB9C8FF) : const Color(0xFF3A5BA8);
  static Color get blush => _dark ? const Color(0xFFE8A8B8) : const Color(0xFFE8B4C0);

  /// Hero fill (safe-to-spend, debt total). Text on it is always [onPeach].
  static const Color peach = Color(0xFFFFB38A);
  static const Color onPeach = Color(0xFF2A160C);

  /// Floating pill nav: latte bar in light, cocoa bar in dark.
  static Color get navBar => _dark ? const Color(0xFF241D18) : const Color(0xFFE6CFBA);
  static Color get navActive => _dark ? const Color(0xFF3A2E25) : const Color(0xFFFFF6EC);
  static Color get navActiveInk => _dark ? const Color(0xFFFFB38A) : const Color(0xFF7A4A30);
  static Color get navIcon => _dark ? const Color(0xFFB39E90) : const Color(0xFF6B4A38);
  static Color get fab => _dark ? const Color(0xFFFFB38A) : const Color(0xFF7A4A30);
  static Color get onFab => _dark ? const Color(0xFF2A160C) : const Color(0xFFFFF6EC);

  // Health
  static Color get healthOk => sage;
  static Color get healthWarn => ochre;
  static Color get healthBad => danger;

  // Category palette (donut, dots, icons).
  static Color get catFood => _dark ? const Color(0xFFFFB38A) : const Color(0xFFD9692F);
  static Color get catTransport => _dark ? const Color(0xFF9FD8B5) : const Color(0xFF3F8A5C);
  static Color get catBills => _dark ? const Color(0xFFE6D48E) : const Color(0xFFB8900F);
  static Color get catShopping => _dark ? const Color(0xFFF29AA5) : const Color(0xFFC94A5E);
  static Color get catEntertainment => _dark ? const Color(0xFFB9C8FF) : const Color(0xFF5B7FD6);
  static Color get catHealth => _dark ? const Color(0xFF7FC4A0) : const Color(0xFF2F8A66);
  static Color get catOther => _dark ? const Color(0xFFB39E90) : const Color(0xFFA08878);

  /// Pastel tile behind a category (budget tiles, transaction icons).
  static Color tileFor(Color cat) => _dark
      ? Color.alphaBlend(cat.withValues(alpha: 0.18), surface)
      : Color.alphaBlend(cat.withValues(alpha: 0.20), const Color(0xFFFFFFFF));
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
    onPrimary: isDark ? FtColors.onPeach : Colors.white,
    primaryContainer: isDark ? const Color(0xFF3A2E25) : const Color(0xFFFFE1C7),
    onPrimaryContainer: FtColors.ink,
    secondary: FtColors.clay,
    onSecondary: isDark ? FtColors.onPeach : Colors.white,
    secondaryContainer: isDark ? const Color(0xFF3A2E25) : const Color(0xFFFFE1C7),
    onSecondaryContainer: FtColors.ink,
    tertiary: FtColors.clay,
    onTertiary: isDark ? FtColors.onPeach : Colors.white,
    tertiaryContainer: isDark ? const Color(0xFF3A2E25) : const Color(0xFFFFE1C7),
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

  final sans = GoogleFonts.plusJakartaSansTextTheme();
  TextStyle? tabular(TextStyle? style) => style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  final textTheme = sans.copyWith(
    displayLarge: tabular(sans.displayLarge)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w800, letterSpacing: -1.5),
    displayMedium: tabular(sans.displayMedium)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w800, letterSpacing: -1.0),
    displaySmall: tabular(sans.displaySmall)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineLarge: tabular(sans.headlineLarge)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    headlineMedium: tabular(sans.headlineMedium)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    headlineSmall: tabular(sans.headlineSmall)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleLarge: tabular(sans.titleLarge)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w700),
    titleMedium: tabular(sans.titleMedium)?.copyWith(
        color: FtColors.ink, fontWeight: FontWeight.w600),
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
        borderRadius: BorderRadius.circular(22),
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
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: FtColors.line, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: FtColors.line, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: FtColors.ink, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: FtColors.danger, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
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
        shape: const StadiumBorder(),
        textStyle: sans.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      backgroundColor: FtColors.fab,
      foregroundColor: FtColors.onFab,
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

/// Small "eyebrow" label used above sections + form fields.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: color ?? FtColors.ink3,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
