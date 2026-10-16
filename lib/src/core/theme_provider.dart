import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    state = v == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, switch (mode) {
      ThemeMode.dark => 'dark',
      _ => 'light',
    });
  }
}

/// Beta "Liquid Glass" — lapisan tampilan opsional di atas tema terang/gelap.
/// OFF (default) = tampilan klasik persis seperti sebelumnya.
final liquidThemeProvider = NotifierProvider<LiquidThemeNotifier, bool>(
  LiquidThemeNotifier.new,
);

class LiquidThemeNotifier extends Notifier<bool> {
  static const _key = 'liquid_theme';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setLiquid(bool on) async {
    state = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, on);
  }
}

/// "Warna" — color palette choice (Settings → Tampilan). Default
/// [FtPalette.daun] is the current look (DESIGN.md); an unknown or missing
/// stored value falls back to it. Users who saved a palette keep theirs.
final paletteProvider = NotifierProvider<PaletteNotifier, FtPalette>(
  PaletteNotifier.new,
);

class PaletteNotifier extends Notifier<FtPalette> {
  static const _key = 'ft_palette';

  @override
  FtPalette build() {
    _load();
    return FtPalette.daun;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    state = FtPalette.values.firstWhere(
      (p) => p.name == v,
      orElse: () => FtPalette.daun,
    );
  }

  Future<void> setPalette(FtPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, palette.name);
  }
}
