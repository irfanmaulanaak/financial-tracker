import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../record_common/account_picker.dart';
import 'card_repository.dart';
import 'credit_card.dart';

/// Bottom sheet for paying a single installment's monthly billing.
/// Picks the source account, advances `monthsPaid` by one, decrements
/// `card.used` by `monthly`, and debits the chosen account — all atomic.
class PayInstallmentSheet extends ConsumerStatefulWidget {
  const PayInstallmentSheet({
    super.key,
    required this.hid,
    required this.cardId,
    required this.installment,
  });

  final String hid;
  final String cardId;
  final Installment installment;

  static Future<void> show({
    required BuildContext context,
    required String hid,
    required String cardId,
    required Installment installment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayInstallmentSheet(
        hid: hid,
        cardId: cardId,
        installment: installment,
      ),
    );
  }

  @override
  ConsumerState<PayInstallmentSheet> createState() =>
      _PayInstallmentSheetState();
}

class _PayInstallmentSheetState extends ConsumerState<PayInstallmentSheet> {
  String? _sourceAccountId;
  bool _busy = false;

  Future<void> _pay() async {
    final sourceId = _sourceAccountId;
    if (sourceId == null) {
      FtHaptics.warning();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cardRepositoryProvider).incrementInstallment(
            hid: widget.hid,
            cardId: widget.cardId,
            installmentId: widget.installment.id,
            sourceAccountId: sourceId,
          );
      FtHaptics.success();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showFtErrorSnack(context, e, prefix: 'Gagal membayar cicilan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final inst = widget.installment;
    final household = ref.watch(currentHouseholdProvider).value;
    final accounts = household == null
        ? const <RecordAccountChoice>[]
        : recordAccountChoices(
            cashAccounts: household.cashAccounts,
            savingsAccounts: household.savingsAccounts,
          );
    if (_sourceAccountId == null && accounts.isNotEmpty) {
      _sourceAccountId = accounts.first.id;
    }
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
              const Eyebrow('Bayar Cicilan Bulan Ini'),
              const SizedBox(height: 6),
              Text(
                inst.label.isNotEmpty ? inst.label : 'Cicilan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${inst.monthsPaid + 1}/${inst.monthsTotal} bulan · '
                'Sisa ${Money.format(inst.remainingAmount)}',
                style: TextStyle(color: FtColors.ink3, fontSize: 11),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: FtColors.plum.withValues(alpha: 0.08),
                  border: Border.all(color: FtColors.plum, width: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cicilan bulan ini',
                            style: TextStyle(
                              color: FtColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sisa tagihan kartu berkurang ${Money.format(inst.monthly)}',
                            style:
                                TextStyle(color: FtColors.ink3, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Money.format(inst.monthly),
                      style: TextStyle(
                        color: FtColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Eyebrow('Bayar dari'),
              const SizedBox(height: 10),
              RecordAccountDropdownField(
                accounts: accounts,
                selectedId: _sourceAccountId,
                accent: FtColors.plum,
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
                      onPressed: _busy || _sourceAccountId == null
                          ? null
                          : _pay,
                      child: _busy
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: FtColors.bg,
                              ),
                            )
                          : Text('Bayar ${Money.format(inst.monthly)}'),
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
