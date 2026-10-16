part of 'expense_repository.dart';

extension ExpenseRepositoryQueries on ExpenseRepository {
  Stream<List<Expense>> watchInRange({
    required String householdId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _col(householdId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive))
        .where('date', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }

  /// Emits whether each snapshot of the *identical* [watchInRange] query came
  /// from the server (`true`) rather than the local cache (`false`). Same query
  /// shape, so Firestore shares the existing listener — no extra reads. Used
  /// only by the home sync gate to avoid starting the entrance on cached data.
  Stream<bool> watchRangeServerSynced({
    required String householdId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _col(householdId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive))
        .where('date', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((s) => !s.metadata.isFromCache);
  }

  Stream<List<Expense>> watchRecent({
    required String householdId,
    int limit = 5,
  }) {
    return _col(householdId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }

  /// All recurring-flagged rows since [since]. Same query shape as the
  /// recurring runner — served by the deployed recurring+date composite
  /// index. Powers the "Langganan & Rutin" screen.
  Stream<List<Expense>> watchRecurringSince({
    required String householdId,
    required DateTime since,
  }) {
    return _col(householdId)
        .where('recurring', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }

  /// Watches the most recent expenses for a single card. By default cicilan
  /// rows are excluded (`includeCicilan: false`) — the pay sheet's statement
  /// math must only see plain charges. The card-detail history passes
  /// `includeCicilan: true` and joins against the installments stream to
  /// show settled cicilan alongside plain charges.
  ///
  /// Server-side query is just `where('cardId', isEqualTo: cardId)` so we
  /// only need Firestore's auto-created single-field index — combining it
  /// with `orderBy('date')` would require a deployed composite index and
  /// the stream silently stalls until the index is built. Sort + slice
  /// happen client-side; for a 2–5 person household the per-card row count
  /// is small enough that this is cheap. `limit: null` returns every row
  /// (the pay sheet needs the all-time plain sum for statement math).
  Stream<List<Expense>> watchByCard({
    required String householdId,
    required String cardId,
    int? limit = 20,
    bool includeCicilan = false,
  }) {
    return _col(householdId)
        .where('cardId', isEqualTo: cardId)
        .snapshots()
        .map((s) {
          final rows = s.docs
              .map(Expense.fromSnapshot)
              .where((e) => includeCicilan || e.installmentPlanId == null)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return limit != null && rows.length > limit
              ? rows.sublist(0, limit)
              : rows;
        });
  }

  /// Watches recent expenses paid from a given cash/savings account.
  ///
  /// Server-side query is a single `where('sourceAccountId', isEqualTo: ...)`
  /// to avoid needing a composite index. Sort by date desc and slice
  /// client-side — for a 2–5 person household per-account row counts are
  /// small enough that this is cheap.
  Stream<List<Expense>> watchByAccount({
    required String householdId,
    required String accountId,
    int limit = 100,
  }) {
    return _col(householdId)
        .where('sourceAccountId', isEqualTo: accountId)
        .snapshots()
        .map((s) {
          final rows = s.docs.map(Expense.fromSnapshot).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return rows.length > limit ? rows.sublist(0, limit) : rows;
        });
  }

  Stream<List<Expense>> watchByCategory({
    required String householdId,
    required String categoryId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _col(householdId)
        .where('categoryId', isEqualTo: categoryId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive))
        .where('date', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }
}
