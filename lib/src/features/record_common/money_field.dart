import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../theme.dart';

/// Big serif amount input backed by the system **numeric** keyboard (no
/// QWERTY). Drops the custom in-app numpad while keeping the editorial
/// look of [RecordAmountDisplay]: eyebrow label + Rp prefix + large
/// auto-grouped number.
///
/// Internally stores the raw integer; the display is formatted via
/// [ThousandsSeparatorFormatter]. Cursor always lands at the end after
/// formatting — matches the UX of every Indonesian wallet app and avoids
/// the messy "cursor between separator dots" edge cases.
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.amount,
    required this.onChanged,
    this.eyebrow = 'Jumlah',
    this.prefix = 'Rp',
    this.activeColor,
    this.autofocus = true,
    this.focusNode,
  });

  final int amount;
  final ValueChanged<int> onChanged;
  final String eyebrow;
  final String prefix;
  final Color? activeColor;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayFor(widget.amount));
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant MoneyField old) {
    super.didUpdateWidget(old);
    // Reflect external resets (e.g. parent clears the form). Skip when the
    // value already matches so we don't fight the user's typing.
    final next = _displayFor(widget.amount);
    if (_controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  static String _displayFor(int amount) =>
      amount == 0 ? '' : Money.format(amount).replaceFirst(RegExp(r'^Rp\s*'), '');

  @override
  Widget build(BuildContext context) {
    final tint = widget.amount > 0 && widget.activeColor != null
        ? widget.activeColor!
        : FtColors.ink;
    final cursorColor = widget.activeColor ?? FtColors.clay;

    return Column(
      children: [
        Eyebrow(widget.eyebrow),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.prefix,
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorFormatter(),
                  ],
                  textAlign: TextAlign.left,
                  cursorColor: cursorColor,
                  cursorWidth: 2,
                  cursorHeight: 38,
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0',
                    hintStyle: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(
                          fontSize: 48,
                          height: 1,
                          letterSpacing: -1.5,
                          color: FtColors.ink4,
                        ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 48,
                        height: 1,
                        letterSpacing: -1.5,
                        color: tint,
                      ),
                  onChanged: (raw) {
                    final parsed = Money.parse(raw) ?? 0;
                    if (parsed != widget.amount) widget.onChanged(parsed);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Input formatter that re-groups digits into id-ID style (`1.000.000`).
/// Cursor always settles at end-of-text after reformatting.
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final n = int.parse(digits);
    final grouped = Money.format(n).replaceFirst(RegExp(r'^Rp\s*'), '');
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }
}
