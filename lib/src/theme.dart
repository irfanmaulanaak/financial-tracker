import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FinSist palette: neutral financial canvas, one blue action color, and
/// semantic colors reserved for meaning. Supports light and dark modes via a
/// static brightness toggle so existing widgets don't need to change.
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
  static Color get bg =>
      _dark ? const Color(0xFF0A0B0D) : const Color(0xFFF6F7F9);
  static Color get bgAlt =>
      _dark ? const Color(0xFF111419) : const Color(0xFFF0F2F5);
  static Color get surface =>
      _dark ? const Color(0xFF16181D) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      _dark ? const Color(0xFF20242B) : const Color(0xFFF2F4F7);

  // Text
  static Color get ink =>
      _dark ? const Color(0xFFF7F9FC) : const Color(0xFF0A0B0D);
  static Color get ink2 =>
      _dark ? const Color(0xFFC7CDD6) : const Color(0xFF3F4652);
  static Color get ink3 =>
      _dark ? const Color(0xFF9098A5) : const Color(0xFF68707D);
  static Color get ink4 =>
      _dark ? const Color(0xFF5E6672) : const Color(0xFFA7ADB7);

  // Lines
  static Color get line =>
      _dark ? const Color(0xFF2A3038) : const Color(0xFFE2E6EC);
  static Color get lineStrong =>
      _dark ? const Color(0xFF3B434F) : const Color(0xFFCDD2DB);

  // Accents
  static Color get clay =>
      _dark ? const Color(0xFF5C86FF) : const Color(0xFF0052FF);
  static Color get sage =>
      _dark ? const Color(0xFF45C783) : const Color(0xFF138A52);
  static Color get moss =>
      _dark ? const Color(0xFF43C982) : const Color(0xFF087A46);
  static Color get plum =>
      _dark ? const Color(0xFFA38BFF) : const Color(0xFF6E55D9);
  static Color get ochre =>
      _dark ? const Color(0xFFF3B340) : const Color(0xFFB76E00);
  static Color get danger =>
      _dark ? const Color(0xFFFF6B73) : const Color(0xFFC9363E);
  static Color get sky =>
      _dark ? const Color(0xFF70A0FF) : const Color(0xFF2E6BFF);
  static Color get blush =>
      _dark ? const Color(0xFFF0AFC0) : const Color(0xFFD989A0);

  // Health
  static Color get healthOk =>
      _dark ? const Color(0xFF45C783) : const Color(0xFF138A52);
  static Color get healthWarn =>
      _dark ? const Color(0xFFF3B340) : const Color(0xFFB76E00);
  static Color get healthBad =>
      _dark ? const Color(0xFFFF6B73) : const Color(0xFFC9363E);

  // Category palette (used by donut + category chips).
  static Color get catFood =>
      _dark ? const Color(0xFFFF9B73) : const Color(0xFFD85C2F);
  static Color get catTransport =>
      _dark ? const Color(0xFF45C783) : const Color(0xFF138A52);
  static Color get catBills =>
      _dark ? const Color(0xFFF3B340) : const Color(0xFFB76E00);
  static Color get catShopping =>
      _dark ? const Color(0xFFA38BFF) : const Color(0xFF6E55D9);
  static Color get catEntertainment =>
      _dark ? const Color(0xFF70A0FF) : const Color(0xFF2E6BFF);
  static Color get catHealth =>
      _dark ? const Color(0xFF36C2B4) : const Color(0xFF078478);
  static Color get catOther =>
      _dark ? const Color(0xFF8E96A3) : const Color(0xFF747C88);
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
    primaryContainer: isDark
        ? const Color(0xFF18264A)
        : const Color(0xFFE8EFFF),
    onPrimaryContainer: FtColors.ink,
    secondary: FtColors.sage,
    onSecondary: Colors.white,
    secondaryContainer: isDark
        ? const Color(0xFF123526)
        : const Color(0xFFDDF4E8),
    onSecondaryContainer: FtColors.ink,
    tertiary: FtColors.sky,
    onTertiary: Colors.white,
    tertiaryContainer: isDark
        ? const Color(0xFF182A4D)
        : const Color(0xFFE5EDFF),
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

  // Inter is neutral and highly legible across Android, iOS, and web. Tabular
  // figures keep rupiah columns and changing balances visually stable.
  final sans = GoogleFonts.interTextTheme().apply(
    bodyColor: FtColors.ink2,
    displayColor: FtColors.ink,
  );
  const numbers = [FontFeature.tabularFigures()];

  final textTheme = sans.copyWith(
    displayLarge: sans.displayLarge?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.4,
      fontFeatures: numbers,
    ),
    displayMedium: sans.displayMedium?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.0,
      fontFeatures: numbers,
    ),
    displaySmall: sans.displaySmall?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.7,
      fontFeatures: numbers,
    ),
    headlineLarge: sans.headlineLarge?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.7,
    ),
    headlineMedium: sans.headlineMedium?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineSmall: sans.headlineSmall?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    titleLarge: sans.titleLarge?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: sans.titleMedium?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: sans.bodyLarge?.copyWith(color: FtColors.ink2, height: 1.45),
    bodyMedium: sans.bodyMedium?.copyWith(color: FtColors.ink2, height: 1.45),
    bodySmall: sans.bodySmall?.copyWith(color: FtColors.ink3, height: 1.4),
    labelLarge: sans.labelLarge?.copyWith(
      color: FtColors.ink,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: sans.labelMedium?.copyWith(color: FtColors.ink2),
    labelSmall: sans.labelSmall?.copyWith(
      color: FtColors.ink3,
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
    ),
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
      backgroundColor: liquid ? Colors.transparent : FtColors.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: FtColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: sans.titleLarge?.copyWith(
        color: FtColors.ink,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: FtColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: FtColors.line, width: 1),
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
        borderSide: BorderSide(color: FtColors.clay, width: 1.5),
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
      style:
          FilledButton.styleFrom(
            backgroundColor: FtColors.clay,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: sans.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((s) {
              if (s.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.16);
              }
              if (s.contains(WidgetState.hovered) ||
                  s.contains(WidgetState.focused)) {
                return Colors.white.withValues(alpha: 0.10);
              }
              return null;
            }),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: FtColors.ink,
            backgroundColor: FtColors.surface,
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: FtColors.lineStrong, width: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: sans.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
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
        foregroundColor: FtColors.clay,
        textStyle: sans.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: FtColors.clay,
      foregroundColor: Colors.white,
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

/// Compact section label used above grouped content and form fields.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 0,
        color: color ?? FtColors.ink3,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
