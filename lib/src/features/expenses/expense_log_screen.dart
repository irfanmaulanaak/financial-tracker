import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import 'expense.dart';
import 'expense_detail_sheet.dart';
import 'expense_repository.dart';
import 'widgets/expense_log_tiles.dart';

class ExpenseLogScreen extends ConsumerStatefulWidget {
  const ExpenseLogScreen({super.key});

  @override
  ConsumerState<ExpenseLogScreen> createState() => _ExpenseLogScreenState();
}

class _ExpenseLogScreenState extends ConsumerState<ExpenseLogScreen> {
  String? _filterMemberId;
  String? _filterCategoryId;
  bool _searchOpen = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Matches note, category label, or amount digits ("25000" finds Rp25.000).
  bool _matchesQuery(Expense e, Household household) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final note = e.note?.toLowerCase() ?? '';
    if (note.contains(q)) return true;
    final cat = household.categoryOf(e.categoryId)?.label.toLowerCase() ?? '';
    if (cat.contains(q)) return true;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && e.amount.toString().contains(digits)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 6),
      );
    }
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    final expensesStream = ref.watch(_expensesProvider(household.id));

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.spend,
        child: Column(
          children: [
              FtSubHeader(
                title: 'Pengeluaran',
                trailing: FtTapScale(
                  scale: 0.92,
                  onTap: () => setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) _search.clear();
                  }),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _searchOpen ? FtColors.ink : FtColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: FtColors.line, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _searchOpen
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      size: 17,
                      color: _searchOpen ? Colors.white : FtColors.ink2,
                    ),
                  ),
                ),
              ),
              if (_searchOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: FtColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FtColors.line, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 16, color: FtColors.ink3),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                                color: FtColors.ink, fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Cari catatan, kategori, jumlah…',
                              hintStyle: TextStyle(
                                  color: FtColors.ink4, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11),
                            ),
                          ),
                        ),
                        if (_search.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(_search.clear),
                            child: Icon(Icons.cancel_rounded,
                                size: 16, color: FtColors.ink4),
                          ),
                      ],
                    ),
                  ),
                ),
              expensesStream.when(
                data: (all) => ExpenseLogTodayCard(
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
                      ExpenseLogFilterPill(
                        label: 'Semua Anggota',
                        active: _filterMemberId == null,
                        onTap: () => setState(() => _filterMemberId = null),
                      ),
                      for (final m in household.members) ...[
                        const SizedBox(width: 8),
                        ExpenseLogFilterPill(
                          label: prettyName(m.displayName),
                          active: _filterMemberId == m.userId,
                          color: parseColor(m.color),
                          onTap: () => setState(
                              () => _filterMemberId = m.userId),
                        ),
                      ],
                      const SizedBox(width: 16),
                      ExpenseLogFilterPill(
                        label: 'Semua Kategori',
                        active: _filterCategoryId == null,
                        onTap: () => setState(() => _filterCategoryId = null),
                      ),
                      for (final c in household.categories) ...[
                        const SizedBox(width: 8),
                        ExpenseLogFilterPill(
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
              child: FtRefreshable(
                onRefresh: () async {
                  ref.invalidate(currentHouseholdProvider);
                  ref.invalidate(_expensesProvider(household.id));
                  await ftRefreshDelay();
                },
                child: expensesStream.when(
                  loading: () => const FtSkeletonListView(
                    count: 6,
                    padding: EdgeInsets.only(bottom: kFtFabClearance),
                  ),
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
                      return _matchesQuery(e, household);
                    }).toList();

                    if (filtered.isEmpty) {
                      return ListView(
                        padding:
                            const EdgeInsets.only(bottom: kFtFabClearance),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        children: [
                          Padding(
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
                                  _search.text.trim().isNotEmpty
                                      ? 'Tidak ada hasil untuk "${_search.text.trim()}"'
                                      : 'Belum ada pengeluaran di siklus ini\n(${Dates.short(cycle.start)} – ${Dates.short(cycle.endExclusive.subtract(const Duration(days: 1)))})',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    final grouped = <DateTime, List<Expense>>{};
                    for (final e in filtered) {
                      final key = Dates.dayKey(e.date);
                      grouped.putIfAbsent(key, () => []).add(e);
                    }
                    final days = grouped.keys.toList()
                      ..sort((a, b) => b.compareTo(a));

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: ListView.builder(
                      key: ValueKey(
                          '${_filterMemberId ?? ''}|${_filterCategoryId ?? ''}|${_search.text}|${filtered.length}'),
                      padding: const EdgeInsets.only(
                        top: 2,
                        bottom: kFtFabClearance,
                      ),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: days.length,
                      itemBuilder: (_, dayIdx) {
                        final day = days[dayIdx];
                        final items = grouped[day]!;
                        final dayTotal = items.fold<int>(
                          0,
                          (a, e) => a + e.amount.toInt(),
                        );
                        // Flat tile index across all previous day groups so
                        // the reveal cascades continuously down the list
                        // instead of restarting per day.
                        var flatIndex = 0;
                        for (var i = 0; i < dayIdx; i++) {
                          flatIndex += grouped[days[i]]!.length + 1;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FtListReveal(
                              index: flatIndex,
                              child: Padding(
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
                            ),
                            for (var i = 0; i < items.length; i++)
                              FtListReveal(
                                index: flatIndex + 1 + i,
                                child: ExpenseLogTile(
                                  expense: items[i],
                                  category:
                                      household.categoryOf(items[i].categoryId),
                                  spender: household.memberOf(items[i].spentBy),
                                  onTap: () => ExpenseDetailSheet.show(
                                    context: context,
                                    expense: items[i],
                                  ),
                                  onDelete: () =>
                                      _confirmDelete(household, items[i]),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    );
                  },
                ),
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
      try {
        await ref
            .read(expenseRepositoryProvider)
            .delete(householdId: household.id, expenseId: e.id);
      } catch (err) {
        if (!mounted) return;
        showFtErrorSnack(context, err, prefix: 'Gagal menghapus pengeluaran');
      }
    }
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
