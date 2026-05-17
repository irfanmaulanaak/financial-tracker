import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';

/// Field that the keypad on the add-goal screen currently writes into.
enum GoalAmountField { target, current }

/// Two large stacked buttons — Target (required) + Sudah Terkumpul
/// (optional). Tap to focus a field, then the keypad below mutates that
/// field's value. Mirrors the "Jumlah" block in screens-extras.jsx.
class GoalAmountFields extends StatelessWidget {
  const GoalAmountFields({
    super.key,
    required this.activeField,
    required this.target,
    required this.current,
    required this.tone,
    required this.onSelect,
  });

  final GoalAmountField activeField;
  final int target;
  final int current;
  final Color tone;
  final ValueChanged<GoalAmountField> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(
          field: GoalAmountField.target,
          eyebrow: 'TARGET',
          amount: target,
          tone: tone,
          active: activeField == GoalAmountField.target,
          onTap: () => onSelect(GoalAmountField.target),
        ),
        const SizedBox(height: 8),
        _Field(
          field: GoalAmountField.current,
          eyebrow: 'SUDAH TERKUMPUL · OPSIONAL',
          amount: current,
          tone: tone,
          active: activeField == GoalAmountField.current,
          onTap: () => onSelect(GoalAmountField.current),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.field,
    required this.eyebrow,
    required this.amount,
    required this.tone,
    required this.active,
    required this.onTap,
  });
  final GoalAmountField field;
  final String eyebrow;
  final int amount;
  final Color tone;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? tone.withValues(alpha: 0.10) : FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? tone : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Money.format(amount),
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontSize: 22,
                                  height: 1,
                                  letterSpacing: -0.3,
                                  color: FtColors.ink,
                                ),
                          ),
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(width: 4),
                        Container(width: 2, height: 18, color: tone),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_rounded, size: 16, color: tone),
          ],
        ),
      ),
    );
  }
}
