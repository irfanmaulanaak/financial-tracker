import '../../../core/formatters.dart';
import '../../expenses/expense.dart';

/// Day header for the activity list (DESIGN.md section 8): "Hari ini",
/// "Kemarin, 15 Okt", otherwise "Selasa, 14 Okt". Pure for testability.
String activityDayLabel(DateTime day, DateTime now) {
  final d = Dates.dayKey(day);
  final today = Dates.dayKey(now);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin, ${Dates.dayMonth(d)}';
  return '${Dates.weekday(d)}, ${Dates.dayMonth(d)}';
}

typedef ActivityDay = ({String label, List<Expense> items});

/// Groups [expenses] (newest first) into day buckets, preserving order.
List<ActivityDay> groupActivityByDay(List<Expense> expenses, DateTime now) {
  final byDay = <DateTime, List<Expense>>{};
  final order = <DateTime>[];
  for (final e in expenses) {
    final key = Dates.dayKey(e.date);
    final bucket = byDay[key];
    if (bucket == null) {
      byDay[key] = [e];
      order.add(key);
    } else {
      bucket.add(e);
    }
  }
  return [
    for (final key in order)
      (label: activityDayLabel(key, now), items: byDay[key]!),
  ];
}
