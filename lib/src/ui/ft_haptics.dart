import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Project-wide haptics facade. Uses the `haptic_feedback` plugin instead of
/// Flutter's built-in `HapticFeedback` because the latter is broken on iOS in
/// current stable Flutter — only `vibrate()` produces feedback while
/// `lightImpact/mediumImpact/heavyImpact/selectionClick` are silent.
///
/// On iOS this hits `UIImpactFeedbackGenerator` /
/// `UINotificationFeedbackGenerator` / `UISelectionFeedbackGenerator`.
/// On Android it emulates the same patterns with `VibrationEffect`.
class FtHaptics {
  FtHaptics._();

  static Future<void> tap() => _safe(HapticsType.light);
  static Future<void> select() => _safe(HapticsType.selection);
  static Future<void> success() => _safe(HapticsType.success);
  static Future<void> warning() => _safe(HapticsType.warning);
  static Future<void> error() => _safe(HapticsType.error);

  static Future<void> _safe(HapticsType t) async {
    try {
      await Haptics.vibrate(t);
    } on PlatformException {
      // Device without haptics / capabilities query failed — silently ignore
      // so callers don't need try/catch around UI side-effects.
    }
  }
}
