import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';
import '../../members/member_chip.dart';
import '../expense.dart';

class ExpenseLogTile extends ConsumerWidget {
  const ExpenseLogTile({
    super.key,
    required this.expense,
    required this.category,
    required this.spender,
    required this.onTap,
    required this.onDelete,
  });
  final Expense expense;
  final Category? category;
  final Member? spender;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = category;
    return FtCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.format(expense.amount),
                style: TextStyle(
                  color: FtColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Tanda permintaan cek yang belum beres.
              if (expense.review != null && !expense.review!.done) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, size: 11, color: FtColors.ochre),
                    const SizedBox(width: 3),
                    Text(
                      'minta dicek',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: FtColors.ochre,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
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
  'trending_up' => Icons.trending_up,
  _ => Icons.category,
};

class ExpenseLogTodayCard extends StatelessWidget {
  const ExpenseLogTodayCard({
    super.key,
    required this.expenses,
    required this.onAdd,
  });

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

class ExpenseLogFilterPill extends StatelessWidget {
  const ExpenseLogFilterPill({
    super.key,
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
