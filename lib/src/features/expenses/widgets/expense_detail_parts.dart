import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../accounts/account.dart';
import '../../cards/credit_card.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';
import '../expense.dart';

String sourceLabel(Expense e, Account? source, CreditCard? card) {
  if (source != null) return source.label;
  if (card != null) return card.label;
  if (e.sourceAccountId != null) return e.sourceAccountId!;
  if (e.cardId != null) return e.cardId!;
  return '—';
}

class ExpenseDetailHero extends StatelessWidget {
  const ExpenseDetailHero({
    super.key,
    required this.expense,
    required this.category,
    required this.categoryColor,
  });
  final Expense expense;
  final Category? category;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.24),
              width: 0.5,
            ),
          ),
          child: Icon(
            iconFor(category?.icon ?? 'category'),
            size: 26,
            color: categoryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          Money.format(expense.amount),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 32,
                letterSpacing: -0.5,
              ),
        ),
        if (expense.note != null && expense.note!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            expense.note!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FtColors.ink3,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class ExpenseDetailRow extends StatelessWidget {
  const ExpenseDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: FtColors.ink2),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: FtColors.ink3, fontSize: 12),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? FtColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseDetailDivider extends StatelessWidget {
  const ExpenseDetailDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: FtColors.line);
}

class ExpenseDetailGrabber extends StatelessWidget {
  const ExpenseDetailGrabber({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: FtColors.lineStrong,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class ExpenseDetailEditButton extends StatelessWidget {
  const ExpenseDetailEditButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: FtColors.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, size: 18, color: FtColors.ink),
            const SizedBox(width: 8),
            Text(
              'Edit pengeluaran',
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseDetailDeleteButton extends StatelessWidget {
  const ExpenseDetailDeleteButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: FtColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: FtColors.danger.withValues(alpha: 0.24),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline,
                size: 18, color: FtColors.danger),
            const SizedBox(width: 8),
            Text(
              'Hapus pengeluaran',
              style: TextStyle(
                color: FtColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
