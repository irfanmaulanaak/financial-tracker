import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../debt.dart';
import 'debts_sheets.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: Eyebrow(text),
    );
  }
}

class DebtTile extends ConsumerWidget {
  const DebtTile({
    super.key,
    required this.debt,
    required this.canTxn,
    this.dimmed = false,
  });

  final Debt debt;
  final bool canTxn;
  final bool dimmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUtang = debt.type == DebtType.utang;
    final accent = debt.settled
        ? FtColors.ink4
        : isUtang
            ? FtColors.danger
            : FtColors.sage;
    final overdue = !debt.settled &&
        debt.dueDate != null &&
        debt.dueDate!.isBefore(DateTime.now());

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      padding: const EdgeInsets.all(14),
      child: FtTapScale(
        onTap: canTxn && !debt.settled
            ? () => DebtActionsSheet.show(context, debt)
            : null,
        child: Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isUtang
                        ? Icons.call_made_rounded
                        : Icons.call_received_rounded,
                    size: 15,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      debt.counterparty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                  Text(
                    debt.settled
                        ? 'Lunas'
                        : Money.format(debt.remaining),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (!debt.settled && debt.paid > 0)
                    'terbayar ${Money.format(debt.paid)} dari ${Money.format(debt.amount)}',
                  if (debt.settled) Money.format(debt.amount),
                  if (debt.dueDate != null)
                    overdue
                        ? 'lewat jatuh tempo ${Dates.short(debt.dueDate!)}'
                        : 'jatuh tempo ${Dates.short(debt.dueDate!)}',
                  if ((debt.note ?? '').isNotEmpty) debt.note!,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: overdue ? FtColors.danger : FtColors.ink3,
                  fontSize: 11,
                ),
              ),
              if (!debt.settled && debt.paid > 0) ...[
                const SizedBox(height: 8),
                FtProgressBar(
                  value: debt.paid,
                  max: debt.amount <= 0 ? 1 : debt.amount,
                  color: ftProgressColor(debt.paid, debt.amount),
                  height: 3,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
