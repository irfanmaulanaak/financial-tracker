import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../members/member_chip.dart';
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
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.spend,
        child: Column(
          children: [
              const FtSubHeader(title: 'Pengeluaran'),
              expensesStream.when(
                data: (all) => _TodayCard(
                  expenses: all,
                  onAdd: () => context.push('/expenses/new'),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 0, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'Semua Anggota',
                        active: _filterMemberId == null,
                        onTap: () => setState(() => _filterMemberId = null),
                      ),
                      for (final m in household.members) ...[
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: prettyName(m.displayName),
                          active: _filterMemberId == m.userId,
                          color: parseColor(m.color),
                          onTap: () => setState(
                              () => _filterMemberId = m.userId),
                        ),
                      ],
                      const SizedBox(width: 16),
                      _FilterPill(
                        label: 'Semua Kategori',
                        active: _filterCategoryId == null,
                        onTap: () => setState(() => _filterCategoryId = null),
                      ),
                      for (final c in household.categories) ...[
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: c.label.split(' ').first,
                          active: _filterCategoryId == c.id,
                          color: parseColor(c.color),
                          onTap: () => setState(
                              () => _filterCategoryId = c.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Expanded(
              child: expensesStream.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Gagal: $e')),
                  data: (all) {
                    final filtered = all.where((e) {
                      if (_filterMemberId != null &&
                          e.spentBy != _filterMemberId) {
                        return false;
                      }
                      if (_filterCategoryId != null &&
                          e.categoryId != _filterCategoryId) {
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
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: FtColors.ink4,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada pengeluaran di siklus ini\n(${Dates.short(cycle.start)} – ${Dates.short(cycle.endExclusive.subtract(const Duration(days: 1)))})',
                                textAlign: TextAlign.center,
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
                      padding: const EdgeInsets.only(top: 2, bottom: 120),
                      itemCount: days.length,
                      itemBuilder: (_, dayIdx) {
                        final day = days[dayIdx];
                        final items = grouped[day]!;
                        final dayTotal = items.fold<int>(
                          0,
                          (a, e) => a + e.amount.toInt(),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      Dates.grouped(day),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Money.format(dayTotal),
                                    style: TextStyle(
                                      color: FtColors.ink3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...items.map(
                              (e) => _ExpenseTile(
                                expense: e,
                                category: household.categoryOf(e.categoryId),
                                spender: household.memberOf(e.spentBy),
                                onDelete: () => _confirmDelete(household, e),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
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
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(expenseRepositoryProvider)
          .delete(householdId: household.id, expenseId: e.id);
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
    return FtCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      onLongPress: onDelete,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cat != null
                ? _parseColor(cat.color).withValues(alpha: 0.15)
                : FtColors.surfaceAlt,
            child: Icon(
              _iconFor(cat?.icon ?? 'category'),
              color: cat != null ? _parseColor(cat.color) : FtColors.ink3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat?.label ?? '-',
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expense.note != null && expense.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    expense.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (spender != null) ...[
                  const SizedBox(height: 4),
                  MemberChip(member: spender!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Money.format(expense.amount),
            style: TextStyle(
              color: FtColors.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

final _expensesProvider = StreamProvider.family<List<Expense>, String>((
  ref,
  householdId,
) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  final cycle = currentCycle(DateTime.now(), payday: household.payday);
  return ref
      .watch(expenseRepositoryProvider)
      .watchInRange(
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.expenses, required this.onAdd});

  final List<Expense> expenses;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final today = expenses
        .where((e) => Dates.dayKey(e.date) == todayKey)
        .fold<int>(0, (a, e) => a + e.amount.toInt());
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 10, 22, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Hari ini'),
                const SizedBox(height: 4),
                Text(
                  Money.format(today),
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontSize: 26, letterSpacing: -0.3),
                ),
              ],
            ),
          ),
          FtAddButton(onTap: onAdd, tooltip: 'Catat pengeluaran'),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? (color ?? FtColors.ink)
              : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? (color ?? FtColors.ink)
                : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : FtColors.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

