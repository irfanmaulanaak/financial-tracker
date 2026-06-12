import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/money_date.dart';
import 'package:financial_tracker/src/core/upcoming.dart';

void main() {
  group('categoryDeltas', () {
    test('gabungkan kedua sisi, sisi hilang = 0', () {
      final d = categoryDeltas({'a': 100, 'b': 50}, {'b': 80, 'c': 30});
      final byId = {for (final x in d) x.id: x};
      expect(byId['a']!.delta, 100);
      expect(byId['b']!.delta, -30);
      expect(byId['c']!.delta, -30);
      expect(byId['c']!.spend, 0);
    });
  });

  group('topSavers', () {
    test('hanya delta negatif dengan baseline > 0, terbesar dulu', () {
      final d = categoryDeltas(
        {'a': 10, 'b': 100, 'c': 0},
        {'a': 100, 'b': 120, 'c': 0},
      );
      final savers = topSavers(d);
      expect(savers.map((s) => s.id), ['a', 'b']);
    });

    test('kosong bila tidak ada yang turun', () {
      final d = categoryDeltas({'a': 100}, {'a': 50});
      expect(topSavers(d), isEmpty);
    });
  });

  group('topRisers', () {
    test('delta positif terbesar dulu, maks n', () {
      final d = categoryDeltas(
        {'a': 200, 'b': 150, 'c': 120},
        {'a': 100, 'b': 100, 'c': 100},
      );
      final risers = topRisers(d, n: 2);
      expect(risers.map((r) => r.id), ['a', 'b']);
    });
  });

  group('upcomingItems', () {
    test('gabung kartu + tagihan, saring 7 hari, urut tanggal', () {
      final now = DateTime(2026, 6, 11);
      final items = upcomingItems(
        cards: [
          (label: 'BCA', dueDay: 15, used: 500000), // 15 Jun → masuk
          (label: 'Mandiri', dueDay: 25, used: 100000), // 25 Jun → keluar
          (label: 'Kosong', dueDay: 12, used: 0), // tanpa tagihan → skip
        ],
        bills: [
          (title: 'Listrik', nextDate: DateTime(2026, 6, 13), amount: 300000),
          (title: 'Netflix', nextDate: DateTime(2026, 6, 30), amount: 65000),
        ],
        now: now,
      );
      expect(items.map((i) => i.title), ['Listrik', 'BCA']);
      expect(items.first.kind, UpcomingKind.bill);
    });

    test('hari ini ikut, kemarin tidak', () {
      final now = DateTime(2026, 6, 11, 14);
      final items = upcomingItems(
        cards: const [],
        bills: [
          (title: 'Hari ini', nextDate: DateTime(2026, 6, 11), amount: 1),
          (title: 'Kemarin', nextDate: DateTime(2026, 6, 10), amount: 1),
        ],
        now: now,
      );
      expect(items.map((i) => i.title), ['Hari ini']);
    });
  });
}
