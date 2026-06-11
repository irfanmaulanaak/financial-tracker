import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/recurring.dart';
import '../../core/recurring_runner.dart';
import '../../core/reminders.dart';
import '../cards/cards_screen.dart';
import '../cards/credit_card.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household_providers.dart';

/// Side-effect provider: derives reminder inputs from live data and
/// (re)schedules local notifications. Mounted once from HomeScreen, and
/// recomputes whenever settings / cards / recurring templates change.
/// The service dedupes identical input signatures, so repeated rebuilds
/// are cheap no-ops.
final reminderSchedulerProvider = Provider<void>((ref) {
  if (!ReminderService.supported) return;
  final settings = ref.watch(reminderSettingsProvider);
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return;

  final cards =
      ref.watch(cardsProvider(household.id)).value ?? const <CreditCard>[];
  final recurring =
      ref.watch(recurringExpensesYearProvider).value ?? const <Expense>[];

  final latest = latestPerKey<Expense>(
    recurring,
    keyOf: expenseTemplateKey,
    dateOf: (e) => e.date,
    isRecurring: (e) => e.recurring,
  );
  final templates = <String, Expense>{
    for (final e in recurring)
      if (latest[expenseTemplateKey(e)] == e.date) expenseTemplateKey(e): e,
  };

  final bills = <BillInput>[
    for (final t in templates.values)
      (
        title: (t.note?.isNotEmpty ?? false)
            ? t.note!
            : (household.categoryOf(t.categoryId)?.label ?? 'Tagihan rutin'),
        nextDate: nextMonthlyOccurrence(t.date),
        amount: t.amount,
      ),
  ]..sort((a, b) => a.nextDate.compareTo(b.nextDate));

  final cardInputs = <CardDueInput>[
    for (final c in cards) (label: c.label, dueDay: c.dueDay, used: c.used),
  ];

  // Fire-and-forget; failures surface via debugPrint inside the service.
  // ignore: discarded_futures
  ref.read(reminderServiceProvider).reschedule(
        settings: settings,
        cards: cardInputs,
        bills: bills,
      );
});
