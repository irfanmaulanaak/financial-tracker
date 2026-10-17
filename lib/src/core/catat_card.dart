/// Pure math for the small Eling card shown after saving an expense
/// (DESIGN.md section 6, item 3): how much is left in the category's budget,
/// or how far over it now is.
library;

class CatatCardAmounts {
  const CatatCardAmounts({
    required this.over,
    required this.oldValue,
    required this.newValue,
  });

  /// True when the category is over budget after this save.
  final bool over;

  /// Remaining budget (or over-budget amount, 0 if it wasn't over yet)
  /// before this expense — the count starts here.
  final int oldValue;

  /// Remaining budget (or over-budget amount) after this expense — the
  /// count ends here.
  final int newValue;
}

/// Whether the after-Catat card should show at all: the category needs a
/// budget, and the expense must fall inside the current cycle (a backdated
/// or edited-forward entry doesn't reflect "this cycle's" spending).
bool catatCardEligible({
  required int monthlyBudget,
  required DateTime date,
  required DateTime cycleStart,
  required DateTime cycleEndExclusive,
}) =>
    monthlyBudget > 0 &&
    !date.isBefore(cycleStart) &&
    date.isBefore(cycleEndExclusive);

/// [spentBeforeSave] is this cycle's spending in the category *before* the
/// expense being recorded; [amount] is that expense's amount.
CatatCardAmounts catatCardAmounts({
  required int budget,
  required int spentBeforeSave,
  required int amount,
}) {
  final newSpent = spentBeforeSave + amount;
  if (newSpent <= budget) {
    return CatatCardAmounts(
      over: false,
      oldValue: budget - spentBeforeSave,
      newValue: budget - newSpent,
    );
  }
  final oldOver = spentBeforeSave > budget ? spentBeforeSave - budget : 0;
  return CatatCardAmounts(
    over: true,
    oldValue: oldOver,
    newValue: newSpent - budget,
  );
}
