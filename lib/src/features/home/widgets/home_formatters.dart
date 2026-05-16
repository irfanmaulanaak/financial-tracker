import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';

String compactMoney(num value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  if (abs >= 1000000000) {
    return '${sign}Rp${_trim(abs / 1000000000)} M';
  }
  if (abs >= 1000000) {
    return '${sign}Rp${_trim(abs / 1000000)} jt';
  }
  if (abs >= 1000) return '${sign}Rp${(abs / 1000).round()} rb';
  return '$sign${Money.format(abs)}';
}

String moneyNoSymbol(num value) => Money.format(value).replaceFirst('Rp', '');

String _trim(num n) {
  final s = n.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final text = parts.take(2).map((p) => p[0]).join();
  return text.isEmpty ? 'FT' : text.toUpperCase();
}

Color parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

Color healthColor(int s) {
  if (s >= 65) return FtColors.sage;
  if (s >= 50) return FtColors.ochre;
  return FtColors.danger;
}

IconData iconFor(String name) => switch (name) {
      'restaurant' => Icons.restaurant,
      'receipt_long' => Icons.receipt_long,
      'shopping_bag' => Icons.shopping_bag,
      'directions_car' => Icons.directions_car,
      'movie' => Icons.movie,
      'favorite' => Icons.favorite,
      'school' => Icons.school,
      'sports_esports' => Icons.sports_esports,
      _ => Icons.category,
    };

IconData goalIconFor(String name) => switch (name) {
      'savings' => Icons.savings,
      'flight' => Icons.flight_takeoff,
      'home' => Icons.home,
      'school' => Icons.school,
      'directions_car' => Icons.directions_car,
      'celebration' => Icons.celebration,
      _ => Icons.flag,
    };
