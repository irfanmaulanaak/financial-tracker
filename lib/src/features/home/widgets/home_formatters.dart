import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../household/name_format.dart';

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

/// Masked placeholder for asset/balance amounts when the user has toggled
/// "hide assets" on (BCA-style privacy). Keep style consistent across
/// hero/breakdown displays.
const String _maskedMoney = 'Rp ••••';
String maskMoney() => _maskedMoney;

String _trim(num n) {
  final s = n.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String initialsOf(String name) {
  final pretty = prettyName(name);
  final parts = pretty.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final text = parts.take(2).map((p) => p[0]).join();
  return text.isEmpty ? 'FT' : text.toUpperCase();
}

/// Parses a stored `#RRGGBB` string. Known palette values — current editorial
/// seeds and the legacy Tailwind seeds still stored in older households — are
/// mapped onto theme-aware `FtColors` pairs so they adapt to dark mode
/// without a data migration. Unknown values render as-is.
Color parseColor(String hex) {
  final h = hex.replaceFirst('#', '').toUpperCase();
  switch (h) {
    case 'C4612A' || 'F59E0B':
      return FtColors.catFood;
    case 'B89030' || '3B82F6':
      return FtColors.catBills;
    case '7A3F4E' || 'EC4899':
      return FtColors.catShopping;
    case '5E7A64' || '10B981':
      return FtColors.catTransport;
    case '3A6075' || '8B5CF6' || '0EA5E9':
      return FtColors.catEntertainment;
    case '2D5040' || 'EF4444':
      return FtColors.catHealth;
    case 'A89880' || '64748B':
      return FtColors.catOther;
    case 'E8B4C0':
      return FtColors.blush;
  }
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
      'pets' => Icons.pets,
      'trending_up' => Icons.trending_up,
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
