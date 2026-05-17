import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

final _digits = NumberFormat.decimalPattern('id_ID');

/// Large serif money display for the entry screens. Prefixes "Rp" (or a
/// supplied [prefix]) and shows a blinking cursor when [hasFocus] is true.
/// Used by record-expense, record-income, add-goal, and pay-card flows.
class FtAmountDisplay extends StatefulWidget {
  const FtAmountDisplay({
    super.key,
    required this.amount,
    this.prefix = 'Rp',
    this.fontSize = 48,
    this.hasFocus = true,
    this.color,
  });

  final int amount;
  final String prefix;
  final double fontSize;
  final bool hasFocus;
  final Color? color;

  @override
  State<FtAmountDisplay> createState() => _FtAmountDisplayState();
}

class _FtAmountDisplayState extends State<FtAmountDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? FtColors.ink;
    final text = widget.amount == 0 ? '0' : _digits.format(widget.amount);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: widget.fontSize * 0.15),
          child: Text(
            widget.prefix,
            style: TextStyle(
              color: FtColors.ink3,
              fontSize: widget.fontSize * 0.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: widget.fontSize,
            fontFamily: 'Newsreader',
            fontWeight: FontWeight.w500,
            height: 1.0,
            letterSpacing: -1,
          ),
        ),
        if (widget.hasFocus)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Opacity(
              opacity: _ctrl.value > 0.5 ? 1 : 0,
              child: Container(
                width: 2,
                height: widget.fontSize * 0.7,
                margin: EdgeInsets.only(left: 3, bottom: widget.fontSize * 0.1),
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}
