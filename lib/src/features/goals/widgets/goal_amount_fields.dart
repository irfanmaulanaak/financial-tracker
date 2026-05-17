import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../record_common/money_field.dart' show ThousandsSeparatorFormatter;

/// Two stacked editable fields — Target (required) + Sudah Terkumpul
/// (optional). Each tap focuses a native numeric keyboard input. Mirrors
/// the "Jumlah" block in screens-extras.jsx but driven by the system
/// keyboard instead of a custom numpad.
class GoalAmountFields extends StatelessWidget {
  const GoalAmountFields({
    super.key,
    required this.target,
    required this.current,
    required this.tone,
    required this.onChangeTarget,
    required this.onChangeCurrent,
  });

  final int target;
  final int current;
  final Color tone;
  final ValueChanged<int> onChangeTarget;
  final ValueChanged<int> onChangeCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(
          eyebrow: 'TARGET',
          amount: target,
          tone: tone,
          onChanged: onChangeTarget,
        ),
        const SizedBox(height: 8),
        _Field(
          eyebrow: 'SUDAH TERKUMPUL · OPSIONAL',
          amount: current,
          tone: tone,
          onChanged: onChangeCurrent,
        ),
      ],
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.eyebrow,
    required this.amount,
    required this.tone,
    required this.onChanged,
  });
  final String eyebrow;
  final int amount;
  final Color tone;
  final ValueChanged<int> onChanged;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _displayFor(widget.amount));
    _focus = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _Field old) {
    super.didUpdateWidget(old);
    final next = _displayFor(widget.amount);
    if (_ctrl.text != next && !_focus.hasFocus) {
      _ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() => _focused = _focus.hasFocus);

  static String _displayFor(int amount) =>
      amount == 0 ? '' : Money.format(amount).replaceFirst(RegExp(r'^Rp\s*'), '');

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _focused ? widget.tone.withValues(alpha: 0.10) : FtColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? widget.tone : FtColors.line,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.eyebrow,
            style: TextStyle(
              color: FtColors.ink3,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rp ',
                style: TextStyle(color: FtColors.ink3, fontSize: 18),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorFormatter(),
                  ],
                  cursorColor: widget.tone,
                  cursorWidth: 2,
                  decoration: const InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0',
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 22,
                        height: 1,
                        letterSpacing: -0.3,
                        color: FtColors.ink,
                      ),
                  onChanged: (raw) {
                    final v = Money.parse(raw) ?? 0;
                    if (v != widget.amount) widget.onChanged(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
