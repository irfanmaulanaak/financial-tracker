import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Menu bawah" — bottom nav style (Settings → Tampilan). [fixed] (a
/// full-width docked bar) is the default; [floating] is the opt-in pill nav.
enum FtNavStyle { floating, fixed }

/// "Beranda" — home screen density (Settings → Tampilan). [lengkap] is
/// today's home, unchanged; [ringkas] hides the extras and only answers
/// "how much is still safe to spend" and "what needs my attention".
enum FtHomeLayout { lengkap, ringkas }

final bottomNavStyleProvider =
    NotifierProvider<BottomNavStyleNotifier, FtNavStyle>(
  BottomNavStyleNotifier.new,
);

class BottomNavStyleNotifier extends Notifier<FtNavStyle> {
  static const _key = 'nav_style';

  @override
  FtNavStyle build() {
    _load();
    return FtNavStyle.fixed;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    state = v == 'floating' ? FtNavStyle.floating : FtNavStyle.fixed;
  }

  Future<void> setStyle(FtNavStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, switch (style) {
      FtNavStyle.fixed => 'fixed',
      FtNavStyle.floating => 'floating',
    });
  }
}

final homeLayoutProvider =
    NotifierProvider<HomeLayoutNotifier, FtHomeLayout>(
  HomeLayoutNotifier.new,
);

class HomeLayoutNotifier extends Notifier<FtHomeLayout> {
  static const _key = 'home_layout';

  @override
  FtHomeLayout build() {
    _load();
    return FtHomeLayout.lengkap;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    state = v == 'ringkas' ? FtHomeLayout.ringkas : FtHomeLayout.lengkap;
  }

  Future<void> setLayout(FtHomeLayout layout) async {
    state = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, switch (layout) {
      FtHomeLayout.ringkas => 'ringkas',
      FtHomeLayout.lengkap => 'lengkap',
    });
  }
}
