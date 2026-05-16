import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final homeLayoutProvider = StateNotifierProvider<HomeLayoutNotifier, String>(
  (ref) => HomeLayoutNotifier(),
);

class HomeLayoutNotifier extends StateNotifier<String> {
  HomeLayoutNotifier() : super('A') {
    _load();
  }

  static const _key = 'home_layout';

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
