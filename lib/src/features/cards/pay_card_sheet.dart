import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_keypad.dart';
import '../../ui/ft_ui.dart';
import 'card_repository.dart';
import 'credit_card.dart';

enum _PayMode { min, full, custom }

/// Bottom sheet for paying down a credit card. Three options: minimum,
/// full balance, or a custom amount entered via keypad. Mirrors the
/// `PayCardSheet` in `claude-design/design/screens-extras.jsx`.
class PayCardSheet extends ConsumerStatefulWidget {
  const PayCardSheet({
    super.key,
    required this.hid,
    required this.card,
  });

  final String hid;
  final CreditCard card;

  static Future<void> show({
    required BuildContext context,
    required String hid,
    required CreditCard card,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayCardSheet(hid: hid, card: card),
    );
  }

  @override
  ConsumerState<PayCardSheet> createState() => _PayCardSheetState();
}

class _PayCardSheetState extends ConsumerState<PayCardSheet> {
  _PayMode _mode = _PayMode.full;
  int _custom = 0;
  bool _busy = false;

  int get _minAmount => minimumPayment(
        balance: widget.card.used,
        minPaymentPct: widget.card.minPaymentPct,
      );

  int get _amount => switch (_mode) {
        _PayMode.min => _minAmount,
        _PayMode.full => widget.card.used,
        _PayMode.custom => _custom,
      };

  Future<void> _pay() async {
    if (_amount <= 0 || _amount > widget.card.used) {
      FtHaptics.warning();
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(cardRepositoryProvider);
    try {
      if (_mode == _PayMode.full) {
        await repo.payFull(hid: widget.hid, cardId: widget.card.id);
      } else if (_mode == _PayMode.min) {
        await repo.payMinimum(hid: widget.hid, cardId: widget.card.id);
      } else {
        await repo.applyUsageDelta(
          hid: widget.hid,
          cardId: widget.card.id,
          delta: -_amount,
        );
      }
      FtHaptics.success();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showFtErrorSnack(context, e, prefix: 'Gagal membayar kartu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FtColors.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Eyebrow('Bayar Tagihan'),
            const SizedBox(height: 6),
            Text(
              card.label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sisa ${Money.format(card.used)} · Tgl ${card.dueDay}',
              style: TextStyle(color: FtColors.ink3, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _OptionRow(
              mode: _PayMode.min,
              groupValue: _mode,
              label: 'Bayar Minimum',
              detail: 'Setoran terendah · hindari denda',
              amount: _minAmount,
              onTap: () => setState(() => _mode = _PayMode.min),
            ),
            const SizedBox(height: 8),
            _OptionRow(
              mode: _PayMode.full,
              groupValue: _mode,
              label: 'Lunas',
              detail: 'Bebas bunga · disarankan',
              amount: card.used,
              onTap: () => setState(() => _mode = _PayMode.full),
            ),
            const SizedBox(height: 8),
            _OptionRow(
              mode: _PayMode.custom,
              groupValue: _mode,
              label: 'Jumlah Lain',
              detail: 'Tentukan sendiri',
              amount: _mode == _PayMode.custom ? _custom : null,
              onTap: () => setState(() => _mode = _PayMode.custom),
            ),
            if (_mode == _PayMode.custom) ...[
              const SizedBox(height: 14),
              FtKeypad(
                compact: true,
                onKey: (k) {
                  FtHaptics.tap();
                  setState(() {
                    if (k == null) {
                      _custom = _custom ~/ 10;
                    } else if (k == '000') {
                      _custom = (_custom * 1000).clamp(0, card.used);
                    } else {
                      _custom =
                          (_custom * 10 + int.parse(k)).clamp(0, card.used);
                    }
                  });
                },
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _busy || _amount <= 0 ? null : _pay,
                    child: _busy
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FtColors.bg,
                            ),
                          )
                        : Text('Bayar ${Money.format(_amount)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.mode,
    required this.groupValue,
    required this.label,
    required this.detail,
    required this.amount,
    required this.onTap,
  });

  final _PayMode mode;
  final _PayMode groupValue;
  final String label;
  final String detail;
  final int? amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = mode == groupValue;
    return FtTapScale(
      scale: 0.985,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? FtColors.plum.withValues(alpha: 0.08)
              : FtColors.bg,
          border: Border.all(
            color: selected ? FtColors.plum : FtColors.line,
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
                  color: selected ? FtColors.plum : FtColors.lineStrong,
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
