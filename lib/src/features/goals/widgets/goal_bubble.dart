import '../../home/widgets/home_formatters.dart';

/// Pure speech-bubble copy for the goal-detail hero scene (DESIGN.md section
/// 6, "Tujuan"). Two lines: the progress line, and — only below 100% with a
/// monthly contribution set — an estimate of months left.
class GoalBubbleCopy {
  const GoalBubbleCopy(this.line1, this.line2);
  final String line1;
  final String? line2;

  /// Both lines joined for a single `Text`, or just [line1].
  String get text => line2 == null ? line1 : '$line1\n$line2';
}

GoalBubbleCopy goalBubbleCopy({
  required int current,
  required int target,
  required int monthlyContrib,
}) {
  if (current <= 0) {
    return const GoalBubbleCopy('Yuk mulai setor pertama.', null);
  }
  if (target <= 0 || current >= target) {
    return const GoalBubbleCopy('Tercapai! Selamat ya.', null);
  }
  final pct = (current / target * 100).round();
  final remaining = target - current;
  final line1 = 'Sudah $pct%! Kurang ${compactMoney(remaining)} lagi.';
  if (monthlyContrib <= 0) return GoalBubbleCopy(line1, null);
  final months = (remaining / monthlyContrib).ceil();
  return GoalBubbleCopy(line1, 'Sekitar $months bulan lagi sampai.');
}
