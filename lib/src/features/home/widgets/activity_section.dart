import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../expenses/expense.dart';
import '../../expenses/expense_detail_sheet.dart';
import '../../household/household.dart';
import 'home_activity_group.dart';
import 'home_formatters.dart';

/// Recent activity, grouped by day with headers ("Hari ini", "Kemarin, 15
/// Okt", "Selasa, 14 Okt"), ending with "Lihat semua" (DESIGN.md section 8).
class ActivitySection extends StatelessWidget {
  const ActivitySection({
    super.key,
    required this.recentAsync,
    required this.household,
  });

  final AsyncValue<List<Expense>> recentAsync;
  final Household household;

  @override
  Widget build(BuildContext context) {
    final recent = recentAsync.value ?? const <Expense>[];
    if (recent.isEmpty) {
      return recentAsync.isLoading
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FtSectionHeader(title: 'Aktivitas'),
                  Text(
                    'Belum ada pengeluaran tercatat siklus ini.',
                    style: TextStyle(color: FtColors.ink3, fontSize: 13),
                  ),
                ],
              ),
            );
    }
    final groups = groupActivityByDay(recent, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in groups) ...[
          FtSectionHeader(title: g.label),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            child: Column(
              children: [
                for (final e in g.items)
                  _ActivityRow(
                    expense: e,
                    category: household.categoryOf(e.categoryId),
                    spender: household.memberOf(e.spentBy),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/expenses'),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Semua aktivitas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FtColors.clay,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.expense,
    required this.category,
    required this.spender,
  });

  final Expense expense;
  final Category? category;
  final Member? spender;

  @override
  Widget build(BuildContext context) {
    final note = expense.note;
    final hasNote = note != null && note.isNotEmpty;
    final title = hasNote ? note : (category?.label ?? '-');
    return FtTapScale(
      scale: 0.99,
      onTap: () => ExpenseDetailSheet.show(context: context, expense: expense),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
        ),
        child: Row(
          children: [
            _MemberDot(member: spender),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category?.label ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: FtColors.ink3, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '−${Money.format(expense.amount)}',
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberDot extends StatelessWidget {
  const _MemberDot({required this.member});
  final Member? member;

  @override
  Widget build(BuildContext context) {
    final color = member != null ? parseColor(member!.color) : FtColors.ink4;
    final initial = member != null
        ? initialsOf(member!.displayName).characters.first.toUpperCase()
        : '?';
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
