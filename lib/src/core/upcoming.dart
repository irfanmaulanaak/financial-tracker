/// Daftar "yang akan datang": jatuh tempo kartu + tagihan rutin, digabung
/// dan diurutkan. Dipakai Money Date (7 hari ke depan) dan layar Kalender.
/// Pure — input sudah di-resolve caller.
library;

import 'reminder_times.dart';

enum UpcomingKind { cardDue, bill }

class UpcomingItem {
  const UpcomingItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.kind,
  });

  final String title;
  final DateTime date;
  final int amount;
  final UpcomingKind kind;
}

/// Gabungkan kartu (hanya yang ada tagihan) dan tagihan rutin, saring
/// sampai [withinDays] ke depan, urut tanggal. Tanggal kartu =
/// [billingDay] (tagihan keluar) — momen uang perlu siap; dueDay hanya
/// deadline dan tetap dipakai banner/reminder.
List<UpcomingItem> upcomingItems({
  required List<({String label, int billingDay, int used})> cards,
  required List<({String title, DateTime nextDate, int amount})> bills,
  required DateTime now,
  int withinDays = 7,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final limit = today.add(Duration(days: withinDays + 1));
  final out = <UpcomingItem>[
    for (final c in cards)
      if (c.used > 0)
        UpcomingItem(
          title: c.label,
          date: nextCardDueDate(c.billingDay, now),
          amount: c.used,
          kind: UpcomingKind.cardDue,
        ),
    for (final b in bills)
      UpcomingItem(
        title: b.title,
        date: DateTime(b.nextDate.year, b.nextDate.month, b.nextDate.day),
        amount: b.amount,
        kind: UpcomingKind.bill,
      ),
  ];
  return [
    for (final i in out)
      if (!i.date.isBefore(today) && i.date.isBefore(limit)) i,
  ]..sort((a, b) => a.date.compareTo(b.date));
}
