import 'package:flutter/material.dart';

import '../theme.dart';
import 'ft_haptics.dart';
import 'ft_motion.dart';

/// 12-key numeric keypad used by record-expense, record-income, add-goal,
/// edit-asset, and pay-card flows. Keys: 0..9, "000", and a backspace.
/// Emits string keys ("0".."9", "000") plus a `null` for backspace via the
/// [onKey] callback. The host owns the amount state.
class FtKeypad extends StatelessWidget {
  const FtKeypad({
    super.key,
    required this.onKey,
    this.compact = false,
  });

  /// Called with "0".."9", "000", or `null` for backspace.
  final ValueChanged<String?> onKey;

  /// When true, shrinks the key height (~46) for use inside bottom sheets.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 46.0 : 56.0;
    final keys = const [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['000', '0', '<'],
    ];
    return Column(
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  Expanded(child: _Key(label: row[i], height: h, onKey: onKey)),
                  if (i != row.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.height,
    required this.onKey,
  });

  final String label;
  final double height;
  final ValueChanged<String?> onKey;

  @override
  Widget build(BuildContext context) {
    final isBack = label == '<';
    return FtTapScale(
      scale: 0.94,
      haptic: false,
      onTap: () {
        FtHaptics.tap();
        onKey(isBack ? null : label);
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        alignment: Alignment.center,
        child: isBack
            ? Icon(Icons.backspace_outlined, size: 18, color: FtColors.ink2)
            : Text(
                label,
                style: TextStyle(
                  color: FtColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
