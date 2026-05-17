/// Wires the pure [datesToMaterialise] / [latestPerKey] helpers in
/// `recurring.dart` to live Firestore data. Runs once per app session
/// (gated by [_lastRunPerHousehold]) on home-screen mount.
///
/// For each recurring expense/income template we find the most recent
/// recorded date, compute the calendar months that have lapsed since,
/// and write a fresh instance per month at the same day-of-month
/// (clamped on shorter months).
///
/// Trade-off: lag = up-to-one-month if nobody opens the app. Acceptable
/// for 2-5 internal users; avoids the Cloud-Functions detour.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/expenses/expense.dart';
import '../features/expenses/expense_repository.dart';
import '../features/incomes/income.dart';
import '../features/incomes/income_repository.dart';
import 'providers.dart';
import 'recurring.dart';

/// One-shot trigger per household per app session. Keyed by hid.
final _lastRunPerHousehold = <String, DateTime>{};

class RecurringRunner {
  RecurringRunner(this._db, this._expenses, this._incomes);
  final FirebaseFirestore _db;
  final ExpenseRepository _expenses;
  final IncomeRepository _incomes;

  /// Materialises missing recurring entries up to [now]. Idempotent in
  /// practice: relies on `latestPerKey` to skip what's already there.
  Future<({int expenses, int incomes})> run({
    required String householdId,
    DateTime? now,
  }) async {
    final n = now ?? DateTime.now();
    final last = _lastRunPerHousehold[householdId];
    // Guard against repeated runs within the same hour (e.g. hot reload).
    if (last != null && n.difference(last).inMinutes < 60) {
      return (expenses: 0, incomes: 0);
    }
    _lastRunPerHousehold[householdId] = n;

    final eCount = await _runExpenses(householdId: householdId, now: n);
    // Income is NOT auto-materialised — user explicitly records it on payday
    // to avoid inaccurate duplicates.  Recurring flag is kept as a reminder.
    final iCount = 0; // await _runIncomes(...)
    return (expenses: eCount, incomes: iCount);
  }

  Future<int> _runExpenses({
    required String householdId,
    required DateTime now,
  }) async {
    // Look at the last 12 months for recurring templates. Plenty of room
    // for a missed-month catch-up while keeping the read bounded.
    final since = DateTime(now.year - 1, now.month, now.day);
    final snap = await _db
        .collection('households')
        .doc(householdId)
        .collection('expenses')
        .where('recurring', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();
    final all = snap.docs.map(Expense.fromSnapshot).toList();
    final latest = latestPerKey<Expense>(
      all,
      keyOf: _expenseKey,
      dateOf: (e) => e.date,
      isRecurring: (e) => e.recurring,
    );
    final templates = {
      for (final e in all)
        if (latest[_expenseKey(e)] == e.date) _expenseKey(e): e,
    };

    var created = 0;
    for (final entry in templates.entries) {
      final key = entry.key;
      final template = entry.value;
      final dates = datesToMaterialise(lastSeen: template.date, now: now);
      for (final d in dates) {
        // Deterministic doc ID across devices. Two members opening the app
        // on the same day generate the same ID; the second `set` is a
        // no-op (skipped inside the repo's transaction). Prevents double
        // expenses + double balance debits / double card charges.
        final docId = recurringDocId(key, d);
        if (template.cardId != null) {
          await _expenses.addCardExpense(
            householdId: householdId,
            amount: template.amount,
            categoryId: template.categoryId,
            spentBy: template.spentBy,
            date: d,
            cardId: template.cardId!,
            note: template.note,
            recurring: true,
            docId: docId,
          );
        } else {
          await _expenses.add(
            householdId: householdId,
            amount: template.amount,
            categoryId: template.categoryId,
            sourceAccountId: template.sourceAccountId,
            spentBy: template.spentBy,
            date: d,
            note: template.note,
            recurring: true,
            docId: docId,
          );
        }
        created++;
      }
    }
    return created;
  }

  Future<int> _runIncomes({
    required String householdId,
    required DateTime now,
  }) async {
    final since = DateTime(now.year - 1, now.month, now.day);
    final snap = await _db
        .collection('households')
        .doc(householdId)
        .collection('incomes')
        .where('recurring', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();
    final all = snap.docs.map(Income.fromSnapshot).toList();
    final latest = latestPerKey<Income>(
      all,
      keyOf: _incomeKey,
      dateOf: (i) => i.date,
      isRecurring: (i) => i.recurring,
    );
    final templates = {
      for (final i in all)
        if (latest[_incomeKey(i)] == i.date) _incomeKey(i): i,
    };

    var created = 0;
    for (final entry in templates.entries) {
      final key = entry.key;
      final t = entry.value;
      final dates = datesToMaterialise(lastSeen: t.date, now: now);
      for (final d in dates) {
        await _incomes.add(
          householdId: householdId,
          amount: t.amount,
          source: t.source,
          destinationAccountId: t.destinationAccountId,
          receivedBy: t.receivedBy,
          date: d,
          note: t.note,
          recurring: true,
          docId: recurringDocId(key, d),
        );
        created++;
      }
    }
    return created;
  }

  static String _expenseKey(Expense e) =>
      '${e.categoryId}|${e.sourceAccountId ?? ''}|${e.amount}|${e.note ?? ''}|${e.cardId ?? ''}';
  static String _incomeKey(Income i) =>
      '${i.source.name}|${i.destinationAccountId}|${i.amount}|${i.note ?? ''}';
}

/// Stable per-(template, date) doc ID for recurring materialisation.
///
/// Format: `recur_<fnv1a-hex>_<yyyymmdd>`. FNV-1a is good enough for the
/// hundreds-of-recurring-rows scale of this app — collision probability
/// ~2^-32 per pair, way below any practical concern.
String recurringDocId(String templateKey, DateTime d) {
  // FNV-1a 32-bit.
  const fnvOffset = 0x811C9DC5;
  const fnvPrime = 0x01000193;
  var h = fnvOffset;
  for (final code in templateKey.codeUnits) {
    h ^= code;
    h = (h * fnvPrime) & 0xFFFFFFFF;
  }
  final ymd = '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';
  return 'recur_${h.toRadixString(16).padLeft(8, '0')}_$ymd';
}

final recurringRunnerProvider = Provider<RecurringRunner>((ref) {
  return RecurringRunner(
    ref.watch(firestoreProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(incomeRepositoryProvider),
  );
});

/// Test-only: reset the per-session gate. Not used in production.
void resetRecurringRunnerGateForTests() => _lastRunPerHousehold.clear();
