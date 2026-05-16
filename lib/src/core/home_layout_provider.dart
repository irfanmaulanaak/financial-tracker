import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final homeLayoutProvider = NotifierProvider<HomeLayoutNotifier, String>(
  HomeLayoutNotifier.new,
);

class HomeLayoutNotifier extends Notifier<String> {
  static const _key = 'home_layout';

  @override
  String build() {
    _load();
    return 'A';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v == 'B') state = 'B';
  }

  Future<void> setLayout(String layout) async {
    state = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, layout);
  }
}
