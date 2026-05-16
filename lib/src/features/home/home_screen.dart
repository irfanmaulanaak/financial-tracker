import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/net_worth.dart';
import '../../core/payday.dart';
import '../auth/auth_repository.dart';
import '../cards/cards_screen.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household.dart';
import '../household/household_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    final cycleAsync = ref.watch(cycleExpensesProvider);
    final recentAsync = ref.watch(recentExpensesProvider(5));
    final household = householdAsync.value;
    final cardsAsync =
        household != null ? ref.watch(cardsProvider(household.id)) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(householdAsync.value?.name ?? 'Financial Tracker'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'members':
                  context.push('/members');
                case 'categories':
                  context.push('/categories');
                case 'accounts':
                  context.push('/accounts');
                case 'cards':
                  context.push('/cards');
                case 'incomes':
                  context.push('/incomes');
                case 'signout':
                  ref.read(authRepositoryProvider).signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'accounts', child: Text('Akun')),
              PopupMenuItem(value: 'cards', child: Text('Kartu kredit')),
              PopupMenuItem(value: 'incomes', child: Text('Pemasukan')),
              PopupMenuItem(value: 'categories', child: Text('Kategori')),
              PopupMenuItem(value: 'members', child: Text('Anggota')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'signout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
      body: householdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (household) {
          if (household == null) {
            return const Center(child: Text('Tidak ada rumah tangga.'));
          }
          final cycle = currentCycle(DateTime.now(), payday: household.payday);
          final cycleExpenses = cycleAsync.value ?? const <Expense>[];
          final records = cycleExpenses
              .map((e) => ExpenseRecord(
                    amount: e.amount,
                    categoryId: e.categoryId,
                    spentBy: e.spentBy,
                    date: e.date,
                  ))
              .toList();
          final totalSpentValue = totalSpent(records);
          final byCat = spentByCategory(records);
          final daily = dailyBudget(
            monthlyBudget: household.monthlyBudgetTotal,
            cycleDays: cycleLengthDays(cycle),
          );
          final activeCats = household.categories
              .where((c) => !c.archived)
              .toList()
            ..sort((a, b) {
              final sa = byCat[a.id] ?? 0;
              final sb = byCat[b.id] ?? 0;
              if (sa != sb) return sb.compareTo(sa);
              return a.sortOrder.compareTo(b.sortOrder);
            });

          final cards = cardsAsync?.value ?? const [];
          final cashBalances = household.cashAccounts
              .map((a) => AccountBalance(id: a.id, label: a.label, value: a.value))
              .toList();
          final savingsBalances = household.savingsAccounts
              .map((a) => AccountBalance(id: a.id, label: a.label, value: a.value))
              .toList();
          final cardBalances = cards
              .map((c) => CardBalance(
                  id: c.id, label: c.label, limit: c.limit, used: c.used))
              .toList();
          final nw = computeNetWorth(
            cash: cashBalances,
            savings: savingsBalances,
            cards: cardBalances,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _NetWorthCard(nw: nw),
              const SizedBox(height: 12),
              _BudgetCard(
                totalSpent: totalSpentValue,
                monthlyBudget: household.monthlyBudgetTotal,
                daily: daily,
                cycleStart: cycle.start,
                cycleEndExclusive: cycle.endExclusive,
              ),
              const SizedBox(height: 16),
              Text('Top kategori',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...activeCats.take(5).map((c) {
                final spent = byCat[c.id] ?? 0;
                return _CategoryProgress(
                  category: c,
                  spent: spent,
                );
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text('Pengeluaran terbaru',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton(
                    onPressed: () => context.push('/expenses'),
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...recentAsync.maybeWhen(
                data: (recent) => recent.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('Belum ada pengeluaran.',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ),
                        ),
                      ]
                    : recent
                        .map((e) => _RecentExpenseTile(
                              expense: e,
                              category: household.categoryOf(e.categoryId),
                              spender: household.memberOf(e.spentBy),
                            ))
                        .toList(),
                orElse: () => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.nw});
  final NetWorth nw;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total kekayaan bersih',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            Money.format(nw.total),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: nw.total < 0 ? scheme.error : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCell(
                    label: 'Tunai', value: nw.cash, color: scheme.primary),
              ),
              Expanded(
                child: _MetricCell(
                    label: 'Tabungan',
                    value: nw.savings,
                    color: scheme.tertiary),
              ),
              Expanded(
                child: _MetricCell(
                    label: 'Utang kartu',
                    value: -nw.debt,
                    color: scheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(Money.format(value),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.totalSpent,
    required this.monthlyBudget,
    required this.daily,
    required this.cycleStart,
    required this.cycleEndExclusive,
  });
  final int totalSpent;
  final int monthlyBudget;
  final int daily;
  final DateTime cycleStart;
  final DateTime cycleEndExclusive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = monthlyBudget == 0 ? 0.0 : (totalSpent / monthlyBudget).clamp(0.0, 1.0);
    final over = monthlyBudget > 0 && totalSpent > monthlyBudget;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Siklus ${Dates.short(cycleStart)} – ${Dates.short(cycleEndExclusive.subtract(const Duration(days: 1)))}',
            style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            Money.format(totalSpent),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(
            'dari ${Money.format(monthlyBudget)}',
            style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                  over ? scheme.error : scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Budget harian: ${Money.format(daily)}',
            style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  const _CategoryProgress({required this.category, required this.spent});
  final Category category;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final budget = category.monthlyBudget;
    final pct = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final color = _parseColor(category.color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(category.icon), size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(category.label)),
              Text(
                budget > 0
                    ? '${Money.format(spent)} / ${Money.format(budget)}'
                    : Money.format(spent),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({
    required this.expense,
    required this.category,
    required this.spender,
  });
  final Expense expense;
  final Category? category;
  final Member? spender;

  @override
  Widget build(BuildContext context) {
    final color = category != null ? _parseColor(category!.color) : Colors.grey;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(_iconFor(category?.icon ?? 'category'), color: color),
      ),
      title: Text(category?.label ?? '-'),
      subtitle: Text([
        Dates.short(expense.date),
        if (spender != null) spender!.displayName,
      ].join(' • ')),
      trailing: Text(
        Money.format(expense.amount),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

IconData _iconFor(String name) => switch (name) {
      'restaurant' => Icons.restaurant,
      'receipt_long' => Icons.receipt_long,
      'shopping_bag' => Icons.shopping_bag,
      'directions_car' => Icons.directions_car,
      'movie' => Icons.movie,
      'favorite' => Icons.favorite,
      'school' => Icons.school,
      'pets' => Icons.pets,
      'sports_esports' => Icons.sports_esports,
      _ => Icons.category,
    };
