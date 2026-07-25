import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_keypad.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_repository.dart';
import '../household/household_providers.dart';
import '../record_common/account_picker.dart';
import 'card_repository.dart';
import 'credit_card.dart';
import 'widgets/installment_list.dart';

/// Every plain (non-cicilan) charge ever made on the card — the statement
/// math needs the all-time sum because `plainPaid` is an all-time figure.
final _cardPlainChargesProvider =
    StreamProvider.family<List<Expense>, ({String hid, String cardId})>(
  (ref, p) => ref.watch(expenseRepositoryProvider).watchByCard(
        householdId: p.hid,
        cardId: p.cardId,
        limit: null,
      ),
);

enum _PayMode { min, monthly, custom }

/// Bottom sheet for paying down a credit card. Three options: minimum,
/// pay this month's bill (advances cicilan), or a custom amount entered
/// via keypad. Always asks which household account to debit.
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
  _PayMode _mode = _PayMode.monthly;
  int _custom = 0;
  bool _busy = false;
  String? _sourceAccountId;

  int get _minAmount => minimumPayment(
        balance: widget.card.used,
        minPaymentPct: widget.card.minPaymentPct,
      );

  /// This month's bill, statement-style: one `monthly` per cicilan that has
  /// been billed but not yet paid, plus plain CC charges that have crossed
  /// a statement close ([billedPlainDue]) — a "Lunas" purchase made after
  /// the close belongs to next month's bill, so it's excluded here.
  /// Mirrors [CardRepository.payMonthlyBill]; installments + charges come
  /// from shared streams so the figure matches what the repo will see.
  int _monthlyBillAmount(
    List<Installment> installments,
    List<({int amount, DateTime date})> plainCharges,
  ) {
    final now = DateTime.now();
    var monthlyDue = 0;
    for (final i in installments) {
      if (i.isComplete) continue;
      final billed = computeMonthsBilled(
        startedAt: i.startedAt,
        today: now,
        billingDay: widget.card.billingDay,
      );
      if (billed <= i.monthsPaid) continue;
      monthlyDue += i.monthly;
    }
    final plainDue = billedPlainDue(
      charges: plainCharges,
      plainPaid: widget.card.plainPaid,
      today: now,
      billingDay: widget.card.billingDay,
    );
    return monthlyDue + plainDue;
  }

  /// Plain charges not yet on any statement — they'll appear on the next
  /// bill. Shown as a note so "Bayar Tagihan Bulan Ini" being smaller than
  /// "Sisa" is explainable.
  int _unbilledPlain(List<({int amount, DateTime date})> plainCharges) {
    final now = DateTime.now();
    final plainTotal = plainCharges.fold<int>(0, (a, c) => a + c.amount);
    final outstanding =
        (plainTotal - widget.card.plainPaid).clamp(0, plainTotal);
    final due = billedPlainDue(
      charges: plainCharges,
      plainPaid: widget.card.plainPaid,
      today: now,
      billingDay: widget.card.billingDay,
    );
    return outstanding - due;
  }

  int _amount(
    List<Installment> installments,
    List<({int amount, DateTime date})> plainCharges,
  ) =>
      switch (_mode) {
        _PayMode.min => _minAmount,
        _PayMode.monthly => _monthlyBillAmount(installments, plainCharges),
        _PayMode.custom => _custom,
      };

  Future<void> _pay(
    List<Installment> installments,
    List<({int amount, DateTime date})> plainCharges,
  ) async {
    final amount = _amount(installments, plainCharges);
    final sourceId = _sourceAccountId;
    // Cap vs `outstanding` (true debt): the monthly bill can legitimately
    // exceed `used` when cicilan months haven't rolled into the statement
    // figure yet. Custom amounts stay clamped to `used` at input time.
    final cap =
        widget.card.outstanding > widget.card.used ? widget.card.outstanding : widget.card.used;
    if (amount <= 0 || amount > cap || sourceId == null) {
      FtHaptics.warning();
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(cardRepositoryProvider);
    try {
      switch (_mode) {
        case _PayMode.min:
          await repo.payMinimum(
            hid: widget.hid,
            cardId: widget.card.id,
            sourceAccountId: sourceId,
          );
        case _PayMode.monthly:
          await repo.payMonthlyBill(
            hid: widget.hid,
            cardId: widget.card.id,
            sourceAccountId: sourceId,
          );
        case _PayMode.custom:
          await repo.payCustom(
            hid: widget.hid,
            cardId: widget.card.id,
            sourceAccountId: sourceId,
            amount: amount,
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
    final household = ref.watch(currentHouseholdProvider).value;
    final installments = ref
            .watch(cardInstallmentsProvider((hid: widget.hid, cardId: card.id)))
            .value ??
        const [];
    final plainCharges = [
      for (final e in ref
              .watch(
                  _cardPlainChargesProvider((hid: widget.hid, cardId: card.id)))
              .value ??
          const <Expense>[])
        (amount: e.amount, date: e.date),
    ];
    final accounts = household == null
        ? const <RecordAccountChoice>[]
        : recordAccountChoices(
            cashAccounts: household.cashAccounts,
            savingsAccounts: household.savingsAccounts,
          );
    if (_sourceAccountId == null && accounts.isNotEmpty) {
      _sourceAccountId = accounts.first.id;
    }
    final monthlyBill = _monthlyBillAmount(installments, plainCharges);
    final unbilled = _unbilledPlain(plainCharges);
    final amount = _amount(installments, plainCharges);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: SingleChildScrollView(
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
                mode: _PayMode.monthly,
                groupValue: _mode,
                label: 'Bayar Tagihan Bulan Ini',
                detail: 'Cicilan & transaksi yang sudah tertagih',
                amount: monthlyBill,
                onTap: () => setState(() => _mode = _PayMode.monthly),
              ),
              if (unbilled > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Text(
                    '${Money.format(unbilled)} belum tertagih. Masuk '
                    'tagihan berikutnya (tutup tgl ${card.billingDay}).',
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
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
              const SizedBox(height: 18),
              const Eyebrow('Bayar dari'),
              const SizedBox(height: 10),
              RecordAccountDropdownField(
                accounts: accounts,
                selectedId: _sourceAccountId,
                accent: FtColors.clay,
                sheetTitle: 'Pilih rekening',
                onSelect: (id) {
                  FtHaptics.select();
                  setState(() => _sourceAccountId = id);
                },
                emptyNote:
                    'Belum ada rekening. Tambah dari Aset → Tunai/Tabungan.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _busy ||
                              amount <= 0 ||
                              _sourceAccountId == null
                          ? null
                          : () => _pay(installments, plainCharges),
                      child: _busy
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: FtColors.bg,
                              ),
                            )
                          : Text('Bayar ${Money.format(amount)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              ? FtColors.clay.withValues(alpha: 0.08)
              : FtColors.bg,
          border: Border.all(
            color: selected ? FtColors.clay : FtColors.line,
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
                  color: selected ? FtColors.clay : FtColors.lineStrong,
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
