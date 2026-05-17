import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/ft_motion.dart';

/// Segmented "Tunai / Debit" vs "Kartu Kredit" toggle on the record-expense
/// screen. [value] is `'cash'` or `'credit'`.
class PayTypeToggle extends StatelessWidget {
  const PayTypeToggle({
    super.key,
    required this.value,
    required this.onChange,
  });

  final String value;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtColors.line, width: 0.5),
      ),
      child: Row(
        children: [
          _seg(value == 'cash', Icons.payments_outlined, 'Tunai / Debit',
              () => onChange('cash')),
          _seg(value == 'credit', Icons.credit_card_outlined, 'Kartu Kredit',
              () => onChange('credit')),
        ],
      ),
    );
  }

  Widget _seg(bool on, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: FtTapScale(
        scale: 0.97,
        haptic: false,
        onTap: on ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? FtColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: on ? FtColors.bg : FtColors.ink2),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: on ? FtColors.bg : FtColors.ink2,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
