import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_motion.dart';

/// Date picker chip + optional recurring toggle. Shared by record-expense
/// and record-income; the expense flow hides the recurring toggle when a
/// cicilan plan is active by passing `onToggleRecurring: null`.
class RecordMetaRow extends StatelessWidget {
  const RecordMetaRow({
    super.key,
    required this.date,
    required this.recurring,
    required this.onPickDate,
    required this.onToggleRecurring,
  });

  final DateTime date;
  final bool recurring;
  final VoidCallback onPickDate;
  final ValueChanged<bool>? onToggleRecurring;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FtTapScale(
            scale: 0.97,
            onTap: onPickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: FtColors.surface,
                border: Border.all(color: FtColors.line, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: FtColors.ink3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Dates.short(date),
                      style: TextStyle(
                        color: FtColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (onToggleRecurring != null)
          FtTapScale(
            scale: 0.97,
            onTap: () => onToggleRecurring!(!recurring),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: recurring ? FtColors.moss : FtColors.surface,
                border: Border.all(
                  color: recurring ? FtColors.moss : FtColors.line,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_repeat_outlined,
                    size: 14,
                    color: recurring ? Colors.white : FtColors.ink3,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rutin',
                    style: TextStyle(
                      color: recurring ? Colors.white : FtColors.ink2,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
