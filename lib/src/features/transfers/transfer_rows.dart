import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../theme.dart';

/// Optional transfer/top-up fee input row used by the transfer screen.
class TransferFeeRow extends StatefulWidget {
  const TransferFeeRow({super.key, required this.fee, required this.onChanged});
  final int fee;
  final ValueChanged<int> onChanged;

  @override
  State<TransferFeeRow> createState() => _TransferFeeRowState();
}

class _TransferFeeRowState extends State<TransferFeeRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _displayFor(widget.fee));
  }

  @override
  void didUpdateWidget(covariant TransferFeeRow old) {
    super.didUpdateWidget(old);
    final next = _displayFor(widget.fee);
    if (_ctrl.text != next) {
      _ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _displayFor(int v) =>
      v == 0 ? '' : Money.format(v).replaceFirst(RegExp(r'^Rp\s*'), '');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FtColors.surface,
        border: Border.all(color: FtColors.line, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: FtColors.ink3),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Biaya transfer / top-up (opsional)',
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Rp ',
            style: TextStyle(color: FtColors.ink3, fontSize: 13),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110, minWidth: 40),
            child: IntrinsicWidth(
              child: TextField(
                controller: _ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorFormatter(),
                ],
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0',
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: FtColors.ink,
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (raw) {
                  final v = Money.parse(raw) ?? 0;
                  if (v != widget.fee) widget.onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable date row showing the transfer date used by the transfer screen.
class TransferDateRow extends StatelessWidget {
  const TransferDateRow({super.key, required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.event, size: 16, color: FtColors.ink2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tanggal: ${date.day}/${date.month}/${date.year}',
                style: TextStyle(color: FtColors.ink, fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}
