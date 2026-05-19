import 'package:cloud_firestore/cloud_firestore.dart';

/// One deposit toward a goal — manual ("Setor Sekarang").
/// Append-only by design: rules disallow update/delete so the bar chart
/// is a stable audit log.
enum GoalContributionSource { manual }

class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.amount,
    required this.at,
    required this.byUid,
    required this.source,
  });

  final String id;
  final int amount;
  final DateTime at;
  final String byUid;
  final GoalContributionSource source;

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'at': Timestamp.fromDate(at),
        'byUid': byUid,
        'source': source.name,
      };

  factory GoalContribution.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const {};
    return GoalContribution(
      id: snap.id,
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      at: (d['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      byUid: d['byUid'] as String? ?? '',
      source: _sourceFrom(d['source'] as String?),
    );
  }
}

GoalContributionSource _sourceFrom(String? s) => GoalContributionSource.manual;

/// Bucket [contribs] into the last [monthsBack] (oldest-first) months
/// ending at the calendar month of [now]. Empty months map to 0.
///
/// Returned list always has length [monthsBack]; indices walk forward in
/// time so `result.last` is `now`'s month.
List<int> contributionsByMonth({
  required Iterable<GoalContribution> contribs,
  required int monthsBack,
  DateTime? now,
}) {
  final ts = now ?? DateTime.now();
  final months = <DateTime>[];
  // Anchor on the first day of `now`'s month, walk back monthsBack-1.
  for (var i = monthsBack - 1; i >= 0; i--) {
    months.add(_addMonths(DateTime(ts.year, ts.month, 1), -i));
  }
  final out = List<int>.filled(monthsBack, 0);
  for (final c in contribs) {
    final firstOfMonth = DateTime(c.at.year, c.at.month, 1);
    final idx = months.indexOf(firstOfMonth);
    if (idx >= 0) out[idx] += c.amount;
  }
  return out;
}

/// Returns `base` shifted by `delta` calendar months. Handles negative
/// deltas (and year crossings) without relying on Dart's truncating `~/`,
/// which gives wrong sign for negative numerators.
DateTime _addMonths(DateTime base, int delta) {
  var y = base.year;
  var m = base.month + delta;
  while (m <= 0) {
    m += 12;
    y -= 1;
  }
  while (m > 12) {
    m -= 12;
    y += 1;
  }
  return DateTime(y, m, base.day);
}

/// Short Indonesian month label list aligned with [contributionsByMonth].
List<String> monthLabelsForBars({
  required int monthsBack,
  DateTime? now,
}) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final ts = now ?? DateTime.now();
  final out = <String>[];
  for (var i = monthsBack - 1; i >= 0; i--) {
    final shifted = _addMonths(DateTime(ts.year, ts.month, 1), -i);
    out.add(names[shifted.month - 1]);
  }
  return out;
}
