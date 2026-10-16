import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';

/// A single selectable payment option inside [PayCardSheet]. Shows a radio
/// dot, a label + detail line, and an optional amount on the trailing edge.
class PayCardOptionRow extends StatelessWidget {
  const PayCardOptionRow({
    super.key,
    required this.selected,
    required this.label,
    required this.detail,
    required this.amount,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final String detail;
  final int? amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.985,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? FtColors.clay.withValues(alpha: 0.08)
              : FtColors.bg,
          border: Border.all(
            color: selected ? FtColors.clay : FtColors.line,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? FtColors.clay : FtColors.lineStrong,
                  width: selected ? 5 : 1.5,
                ),
                color: FtColors.surface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (amount != null && amount! > 0)
              Text(
                Money.format(amount!),
                style: TextStyle(
                  color: FtColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
