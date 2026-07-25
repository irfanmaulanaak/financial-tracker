import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';

/// Backwards-compatible re-export. The canonical formatters now live in
/// `lib/src/core/formatters.dart`.
export '../../core/formatters.dart'
    show ThousandsSeparatorFormatter, MoneyExpressionFormatter;

/// Big sans amount input backed by the system **numeric** keyboard (no
/// QWERTY). Drops the custom in-app numpad while keeping the editorial
/// look of [RecordAmountDisplay]: eyebrow label + Rp prefix + large
/// auto-grouped number.
///
/// Internally stores the raw integer; the display is formatted via
/// [ThousandsSeparatorFormatter]. Cursor always lands at the end after
/// formatting — matches the UX of every Indonesian wallet app and avoids
/// the messy "cursor between separator dots" edge cases.
///
/// With [calculator] enabled the field accepts running `+`/`-` sums
/// ("25.000+13.000") typed via two small operator chips (the system numeric
/// keypad has no such keys on iOS). The evaluated total is previewed live,
/// reported through [onChanged], and the text collapses to the total on
/// blur or when tapping `=`. Digits still come from the system keyboard —
/// no custom in-app numpad.
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
    this.calculator = false,
  });

  final int amount;
  final ValueChanged<int> onChanged;
  final String eyebrow;
  final String prefix;
  final Color? activeColor;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Allows +/- expressions in the field and shows the operator chips.
  final bool calculator;

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
    if (widget.calculator) {
      // Chips & "= total" preview depend on text/focus, not just on amount.
      _controller.addListener(_onLocalChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void didUpdateWidget(covariant MoneyField old) {
    super.didUpdateWidget(old);
    // Reflect external resets (e.g. parent clears the form). Compare by
    // value, not text, so an in-progress expression ("25.000+1") isn't
    // clobbered when the parent re-renders with the evaluated total.
    if (_valueOf(_controller.text) != widget.amount) {
      final next = _displayFor(widget.amount);
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    if (widget.calculator) {
      _controller.removeListener(_onLocalChange);
      _focusNode.removeListener(_onFocusChange);
    }
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  static String _displayFor(int amount) => Money.displayDigits(amount);

  int _valueOf(String text) => widget.calculator
      ? (Money.evalExpression(text) ?? 0)
      : (Money.parse(text) ?? 0);

  bool get _isExpression =>
      widget.calculator && _controller.text.contains(RegExp(r'[+\-]'));

  void _onLocalChange() {
    if (mounted) setState(() {});
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _collapse();
    if (mounted) setState(() {});
  }

  /// Appends `+` or `-` to the expression (no-op on empty field).
  void _insertOperator(String op) {
    FtHaptics.select();
    _focusNode.requestFocus();
    final next = Money.formatExpression(_controller.text + op);
    if (next == _controller.text) return;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _emit(next);
  }

  /// Replaces the expression with its evaluated total ("25.000+500" → "25.500").
  void _collapse() {
    if (!_isExpression) return;
    final next = _displayFor(_valueOf(_controller.text));
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _emit(next);
  }

  void _emit(String text) {
    final parsed = _valueOf(text);
    if (parsed != widget.amount) widget.onChanged(parsed);
  }

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
                  inputFormatters: widget.calculator
                      ? [MoneyExpressionFormatter()]
                      : [
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
                  onChanged: _emit,
                ),
              ),
            ),
          ],
        ),
        if (_isExpression)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '= ${Money.format(_valueOf(_controller.text))}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _valueOf(_controller.text) < 0
                    ? FtColors.danger
                    : FtColors.ink3,
              ),
            ),
          ),
        if (widget.calculator && _focusNode.hasFocus)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextFieldTapRegion(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OpChip(label: '+', onTap: () => _insertOperator('+')),
                  const SizedBox(width: 10),
                  _OpChip(label: '−', onTap: () => _insertOperator('-')),
                  if (_isExpression) ...[
                    const SizedBox(width: 10),
                    _OpChip(label: '=', onTap: _collapse),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Small pill button for the calculator row. Lives inside a
/// [TextFieldTapRegion] so tapping it never dismisses the keyboard.
class _OpChip extends StatelessWidget {
  const _OpChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FtColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: FtColors.lineStrong, width: 0.8),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: FtColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
