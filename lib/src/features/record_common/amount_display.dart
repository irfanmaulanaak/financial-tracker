import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../theme.dart';

/// Record-screen-style amount display: eyebrow label + large serif number
/// with static "Rp" / "+Rp" prefix and a colored blinking cursor.
/// Shared by `record_expense_screen.dart` and `record_income_screen.dart`.
class RecordAmountDisplay extends StatelessWidget {
  const RecordAmountDisplay({
    super.key,
    required this.amount,
    this.eyebrow = 'Jumlah',
    this.prefix = 'Rp',
    this.cursorColor,
    this.activeColor,
  });

  final int amount;
  final String eyebrow;
  final String prefix;

  /// Cursor stroke color. Defaults to [FtColors.clay] (expense flow).
  /// Pass [FtColors.moss] for income.
  final Color? cursorColor;

  /// Color the number tints to when [amount] > 0. When null, uses [FtColors.ink].
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final tint = amount > 0 && activeColor != null ? activeColor! : FtColors.ink;
    return Column(
      children: [
        Eyebrow(eyebrow),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              prefix,
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  // Strip leading "Rp" since the prefix is rendered separately.
                  Money.format(amount).replaceFirst(RegExp(r'^Rp\s*'), ''),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 48,
                        height: 1,
                        letterSpacing: -1.5,
                        color: tint,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _BlinkCursor(color: cursorColor ?? FtColors.clay),
          ],
        ),
      ],
    );
  }
}

class _BlinkCursor extends StatefulWidget {
  const _BlinkCursor({required this.color});
  final Color color;

  @override
  State<_BlinkCursor> createState() => _BlinkCursorState();
}

class _BlinkCursorState extends State<_BlinkCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curve,
      builder: (_, _) {
        final t = curve.value;
        return Opacity(
          opacity: 0.45 + (1 - t) * 0.55,
          child: Transform.scale(
            scaleY: 1 - t * 0.05,
            child: Container(width: 2, height: 38, color: widget.color),
          ),
        );
      },
    );
  }
}
