import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../expenses/expense.dart';
import '../../expenses/expense_detail_sheet.dart';
import '../../household/household.dart';
import '../../household/name_format.dart';
import 'home_formatters.dart';

class RecentList extends StatelessWidget {
  const RecentList({
    super.key,
    required this.recentAsync,
    required this.household,
    required this.onTap,
  });

  final AsyncValue<List<Expense>> recentAsync;
  final Household household;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Aktivitas terbaru',
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Lihat semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FtColors.clay,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...recentAsync.maybeWhen(
            data: (recent) => recent.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Belum ada pengeluaran tercatat siklus ini.',
                            style:
                                TextStyle(color: FtColors.ink3, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/expenses/new'),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'Catat pengeluaran pertama',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                : [
                    for (final e in recent)
                      ExpenseActivityRow(
                        expense: e,
                        category: household.categoryOf(e.categoryId),
                        spender: household.memberOf(e.spentBy),
                      ),
                  ],
            orElse: () => const [
              Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single expense row (icon, note/category title, category · date subtitle,
/// optional spender initial, right-aligned amount). Tap opens
/// [ExpenseDetailSheet]. Shared by the home "Aktivitas Terbaru" list and the
/// spend screen activity list.
class ExpenseActivityRow extends StatelessWidget {
  const ExpenseActivityRow({
    super.key,
    required this.expense,
    required this.category,
    required this.spender,
    this.showTopBorder = true,
  });

  final Expense expense;
  final Category? category;

  /// Only pass non-null when "Semua Anggota" is the active filter (or there
  /// is no filter, e.g. the home activity list) — otherwise every row is
  /// already known to be the one selected member, and the avatar is noise.
  final Member? spender;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? parseColor(category!.color)
        : FtColors.ink3;
    final note = expense.note;
    final hasNote = note != null && note.isNotEmpty;
    final title = hasNote ? note : (category?.label ?? '-');
    return FtTapScale(
      scale: 0.99,
      onTap: () =>
          ExpenseDetailSheet.show(context: context, expense: expense),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: showTopBorder
            ? Border(top: BorderSide(color: FtColors.line, width: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FtColors.tileFor(color),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconFor(category?.icon ?? 'category'),
              color: color,
              size: 18,
            ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${category?.label ?? '-'} · ${Dates.short(expense.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FtColors.ink3,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (spender != null) ...[
                      const SizedBox(width: 6),
                      _SpenderAvatar(member: spender!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            compactMoney(expense.amount),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Small initial-letter avatar — who spent it, without a long name chip.
class _SpenderAvatar extends StatelessWidget {
  const _SpenderAvatar({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final initial = initialsOf(member.displayName).characters.first;
    return Tooltip(
      message: shortName(member.displayName),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: parseColor(member.color),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
