import 'package:cloud_firestore/cloud_firestore.dart';

/// Daily roll-up of household net worth, persisted to Firestore so the
/// home sparkline / Editorial trend can render real history instead of a
/// synthetic curve.
///
/// Doc ID convention: `YYYY-MM-DD` (local midnight). One snapshot per day
/// — same-day re-writes overwrite if the total moved. See [snapshotDocId].
class NetWorthSnapshot {
  const NetWorthSnapshot({
    required this.date,
    required this.cash,
    required this.savings,
    required this.investments,
    required this.debt,
    required this.total,
    required this.capturedBy,
  });

  /// Local-midnight DateTime corresponding to the doc id.
  final DateTime date;
  final int cash;
  final int savings;
  final int investments;
  final int debt;
  final int total;
  final String capturedBy;

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'cash': cash,
        'savings': savings,
        'investments': investments,
        'debt': debt,
        'total': total,
        'capturedBy': capturedBy,
      };

  factory NetWorthSnapshot.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const {};
    return NetWorthSnapshot(
      date: (d['date'] as Timestamp).toDate(),
      cash: (d['cash'] as num?)?.toInt() ?? 0,
      savings: (d['savings'] as num?)?.toInt() ?? 0,
      investments: (d['investments'] as num?)?.toInt() ?? 0,
      debt: (d['debt'] as num?)?.toInt() ?? 0,
      total: (d['total'] as num?)?.toInt() ?? 0,
      capturedBy: d['capturedBy'] as String? ?? '',
    );
  }
}

/// Stable per-day document ID. `YYYY-MM-DD` (local).
String snapshotDocId(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Local-midnight (00:00) for the given date — used as the canonical
/// `date` field on the snapshot doc.
DateTime localMidnight(DateTime t) => DateTime(t.year, t.month, t.day);

/// One chart point per calendar day.
typedef DailyNetWorthPoint = ({DateTime date, int total});

/// Expands sparse snapshots into one point per calendar day over the last
/// [days] days ending today. Snapshots only exist for days the app was
/// opened, so missing days carry the last known total forward — that keeps
/// the sparkline's time axis honest (a 3-day gap is 3 equal steps, not 1).
/// Days before the very first snapshot are omitted. Oldest first.
List<DailyNetWorthPoint> fillDailyNetWorthSeries(
  List<NetWorthSnapshot> snapshots, {
  int days = 14,
  DateTime? now,
}) {
  if (snapshots.isEmpty) return const [];
  final byDay = <DateTime, int>{
    for (final s in snapshots) localMidnight(s.date): s.total,
  };
  final today = localMidnight(now ?? DateTime.now());
  final windowStart = DateTime(today.year, today.month, today.day - (days - 1));

  // Prime the carry-forward with the latest snapshot before the window.
  int? last;
  final sortedDays = byDay.keys.toList()..sort();
  for (final d in sortedDays) {
    if (d.isBefore(windowStart)) {
      last = byDay[d];
    } else {
      break;
    }
  }

  final out = <DailyNetWorthPoint>[];
  for (var i = days - 1; i >= 0; i--) {
    final day = DateTime(today.year, today.month, today.day - i);
    last = byDay[day] ?? last;
    if (last == null) continue; // before the first snapshot ever
    out.add((date: day, total: last));
  }
  return out;
}
