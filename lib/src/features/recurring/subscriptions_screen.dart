import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/recurring.dart';
import '../../core/recurring_runner.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../incomes/income.dart';
import '../incomes/income_repository.dart';

/// "Langganan & Rutin" — every recurring template (expenses + incomes)
/// derived from rows flagged `recurring: true` in the last 12 months,
/// deduped to the latest instance per template. No new schema.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 5),
      );
    }
    final expensesAsync = ref.watch(recurringExpensesYearProvider);
    final incomesAsync = ref.watch(_recurringIncomesProvider(household.id));
    final expenses = _latestTemplates<Expense>(
      expensesAsync.value ?? const [],
      keyOf: expenseTemplateKey,
      dateOf: (e) => e.date,
    )..sort((a, b) => b.amount.compareTo(a.amount));
    final incomes = _latestTemplates<Income>(
      incomesAsync.value ?? const [],
      keyOf: incomeTemplateKey,
      dateOf: (i) => i.date,
    )..sort((a, b) => b.amount.compareTo(a.amount));

    final monthlyOut = expenses.fold<int>(0, (a, e) => a + e.amount);
    final monthlyIn = incomes.fold<int>(0, (a, i) => a + i.amount);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: FtPageContainer(
          child: FtRefreshable(
            onRefresh: () async {
              ref.invalidate(recurringExpensesYearProvider);
              ref.invalidate(_recurringIncomesProvider(household.id));
              await ftRefreshDelay();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                const FtSubHeader(title: 'Langganan & Rutin'),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('Keluar / bulan'),
                            const SizedBox(height: 4),
                            Text(
                              Money.format(monthlyOut),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('Masuk / bulan'),
                            const SizedBox(height: 4),
                            Text(
                              Money.format(monthlyIn),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontSize: 22,
                                    color: FtColors.sage,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (expenses.isEmpty && incomes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.event_repeat_rounded,
                            size: 48, color: FtColors.ink4),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada transaksi rutin.\nAktifkan toggle "Rutin bulanan" saat mencatat pengeluaran atau pemasukan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FtColors.ink3, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (expenses.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 8, 22, 8),
                    child: Eyebrow('Pengeluaran rutin'),
                  ),
                  for (final e in expenses)
                    _TemplateTile(
                      title: (e.note?.isNotEmpty ?? false)
                          ? e.note!
                          : (household.categoryOf(e.categoryId)?.label ?? '-'),
                      subtitle:
                          '${household.categoryOf(e.categoryId)?.label ?? '-'} · berikutnya ±${Dates.dayMonth(nextMonthlyOccurrence(e.date))}',
                      amount: e.amount,
                      color: _categoryColor(household, e.categoryId),
                    ),
                ],
                if (incomes.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
                    child: Eyebrow('Pemasukan rutin'),
                  ),
                  for (final i in incomes)
                    _TemplateTile(
                      title: (i.note?.isNotEmpty ?? false)
                          ? i.note!
                          : incomeSourceLabel(i.source),
                      subtitle:
                          '${incomeSourceLabel(i.source)} · berikutnya ±${Dates.dayMonth(nextMonthlyOccurrence(i.date))}',
                      amount: i.amount,
                      color: FtColors.sage,
                      positive: true,
                    ),
                ],
                if (expenses.isNotEmpty || incomes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: Text(
                      'Daftar ini dirangkum dari transaksi dengan tanda "Rutin bulanan". Untuk mengubah atau menghentikan, edit / hapus transaksi rutin terbarunya di log.',
                      style: TextStyle(
                          color: FtColors.ink4, fontSize: 11, height: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Latest instance per template key.
List<T> _latestTemplates<T>(
  List<T> all, {
  required String Function(T) keyOf,
  required DateTime Function(T) dateOf,
}) {
  final byKey = <String, T>{};
  for (final item in all) {
    final k = keyOf(item);
    final existing = byKey[k];
    if (existing == null || dateOf(item).isAfter(dateOf(existing))) {
      byKey[k] = item;
    }
  }
  return byKey.values.toList();
}

Color _categoryColor(Household household, String categoryId) {
  final hex = household.categoryOf(categoryId)?.color ?? '#64748B';
  return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    this.positive = false,
  });

  final String title;
  final String subtitle;
  final int amount;
  final Color color;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.event_repeat_rounded, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${positive ? '+' : ''}${Money.format(amount)}/bln',
            style: TextStyle(
              color: positive ? FtColors.sage : FtColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

final _recurringIncomesProvider =
    StreamProvider.family<List<Income>, String>((ref, hid) {
  final since = DateTime.now().subtract(const Duration(days: 365));
  return ref
      .watch(incomeRepositoryProvider)
      .watchRecurringSince(hid: hid, since: since);
});
