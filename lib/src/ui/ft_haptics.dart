import 'package:flutter/services.dart';

class FtHaptics {
  FtHaptics._();

  static Future<void> tap() => HapticFeedback.lightImpact();
  static Future<void> select() => HapticFeedback.selectionClick();
  static Future<void> success() => HapticFeedback.mediumImpact();
  static Future<void> warning() => HapticFeedback.heavyImpact();

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }
}
