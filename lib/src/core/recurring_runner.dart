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
    final iCount = await _runIncomes(householdId: householdId, now: n);
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
      final template = entry.value;
      final dates = datesToMaterialise(lastSeen: template.date, now: now);
      for (final d in dates) {
        if (template.cardId != null) {
          // Recurring CC charges keep the same card; bumps card.used as well.
          await _expenses.addCardExpense(
            householdId: householdId,
            amount: template.amount,
            categoryId: template.categoryId,
            paymentMethodId: template.paymentMethodId,
            spentBy: template.spentBy,
            date: d,
            cardId: template.cardId!,
            note: template.note,
            recurring: true,
          );
        } else {
          await _expenses.add(
            householdId: householdId,
            amount: template.amount,
            categoryId: template.categoryId,
            paymentMethodId: template.paymentMethodId,
            spentBy: template.spentBy,
            date: d,
            note: template.note,
            recurring: true,
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
        );
        created++;
      }
    }
    return created;
  }

  static String _expenseKey(Expense e) =>
      '${e.categoryId}|${e.paymentMethodId}|${e.amount}|${e.note ?? ''}|${e.cardId ?? ''}';
  static String _incomeKey(Income i) =>
      '${i.source.name}|${i.destinationAccountId}|${i.amount}|${i.note ?? ''}';
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
