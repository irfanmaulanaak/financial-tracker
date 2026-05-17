import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/ft_motion.dart';
import '../household/household.dart';

/// Wrapped row of cash/debit/e-wallet payment-method chips for the
/// record-expense screen. Only non-credit methods are passed here; the
/// credit-card path uses the dedicated card picker.
class PaymentMethodRow extends StatelessWidget {
  const PaymentMethodRow({
    super.key,
    required this.methods,
    required this.selected,
    required this.onSelect,
  });

  final List<PaymentMethod> methods;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in methods)
          FtTapScale(
            scale: 0.97,
            haptic: false,
            onTap: () => onSelect(m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected == m.id
                    ? FtColors.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected == m.id
                      ? FtColors.lineStrong
                      : FtColors.line,
                  width: 0.5,
                ),
              ),
              child: Text(
                m.label,
                style: TextStyle(
                  color: selected == m.id ? FtColors.ink : FtColors.ink3,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
