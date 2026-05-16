import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import 'expense.dart';
import 'expense_repository.dart';

class ExpenseLogScreen extends ConsumerStatefulWidget {
  const ExpenseLogScreen({super.key});

  @override
  ConsumerState<ExpenseLogScreen> createState() => _ExpenseLogScreenState();
}

class _ExpenseLogScreenState extends ConsumerState<ExpenseLogScreen> {
  String? _filterMemberId;
  String? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    final expensesStream = ref.watch(_expensesProvider(household.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _filterMemberId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Anggota',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua')),
                      ...household.members.map((m) => DropdownMenuItem(
                            value: m.userId,
                            child: Text(m.displayName),
                          )),
                    ],
                    onChanged: (v) => setState(() => _filterMemberId = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _filterCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua')),
                      ...household.categories.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.label),
                          )),
                    ],
                    onChanged: (v) => setState(() => _filterCategoryId = v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
      body: expensesStream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (all) {
          final filtered = all.where((e) {
            if (_filterMemberId != null && e.spentBy != _filterMemberId) {
              return false;
            }
            if (_filterCategoryId != null && e.categoryId != _filterCategoryId) {
              return false;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada pengeluaran di siklus ini\n(${Dates.short(cycle.start)} – ${Dates.short(cycle.endExclusive.subtract(const Duration(days: 1)))})',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          final grouped = <DateTime, List<Expense>>{};
          for (final e in filtered) {
            final key = Dates.dayKey(e.date);
            grouped.putIfAbsent(key, () => []).add(e);
          }
          final days = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: days.length,
            itemBuilder: (_, dayIdx) {
              final day = days[dayIdx];
              final items = grouped[day]!;
              final dayTotal =
                  items.fold<int>(0, (a, e) => a + e.amount.toInt());
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            Dates.grouped(day),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(Money.format(dayTotal),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                      ],
                    ),
                  ),
                  ...items.map((e) => _ExpenseTile(
                        expense: e,
                        category: household.categoryOf(e.categoryId),
                        spender: household.memberOf(e.spentBy),
                        onDelete: () => _confirmDelete(household, e),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Household household, Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content: Text('${Money.format(e.amount)} • ${Dates.short(e.date)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(expenseRepositoryProvider).delete(
            householdId: household.id,
            expenseId: e.id,
          );
    }
  }
}

class _ExpenseTile extends ConsumerWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.spender,
    required this.onDelete,
  });
  final Expense expense;
  final Category? category;
  final Member? spender;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = category;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cat != null
            ? _parseColor(cat.color).withValues(alpha: 0.15)
            : Colors.grey.shade100,
        child: Icon(_iconFor(cat?.icon ?? 'category'),
            color: cat != null ? _parseColor(cat.color) : Colors.grey),
      ),
      title: Text(cat?.label ?? '-'),
      subtitle: Text([
        if (spender != null) spender!.displayName,
        if (expense.note != null && expense.note!.isNotEmpty) expense.note!,
      ].join(' • ')),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(Money.format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      onLongPress: onDelete,
    );
  }
}

final _expensesProvider =
    StreamProvider.family<List<Expense>, String>((ref, householdId) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  final cycle = currentCycle(DateTime.now(), payday: household.payday);
  return ref.watch(expenseRepositoryProvider).watchInRange(
        householdId: householdId,
        startInclusive: cycle.start,
        endExclusive: cycle.endExclusive,
      );
});

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
