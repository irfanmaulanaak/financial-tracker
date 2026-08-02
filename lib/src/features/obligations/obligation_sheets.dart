import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../record_common/account_picker.dart';
import '../record_common/money_field.dart';
import 'obligation.dart';
import 'obligation_repository.dart';

class PayObligationSheet extends ConsumerStatefulWidget {
  const PayObligationSheet(this.obligation, {super.key});
  final Obligation obligation;

  static Future<void> show(BuildContext context, Obligation obligation) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayObligationSheet(obligation),
    );
  }

  @override
  ConsumerState<PayObligationSheet> createState() => _PayObligationSheetState();
}

class _PayObligationSheetState extends ConsumerState<PayObligationSheet> {
  String? _accountId;
  bool _busy = false;

  Future<void> _pay() async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null || _accountId == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(obligationRepositoryProvider)
          .payMonth(
            hid: household.id,
            obligationId: widget.obligation.id,
            accountId: _accountId!,
            expectedMonthsPaid: widget.obligation.monthsPaid,
          );
      if (mounted) {
        FtHaptics.success();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showFtErrorSnack(context, e, prefix: 'Gagal membayar');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final accounts = household == null
        ? const <RecordAccountChoice>[]
        : recordAccountChoices(
            cashAccounts: household.cashAccounts,
            savingsAccounts: household.savingsAccounts,
          );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FtColors.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bayar ${widget.obligation.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              Money.format(widget.obligation.monthly),
              style: TextStyle(color: FtColors.ink2, fontSize: 13),
            ),
            const SizedBox(height: 16),
            RecordAccountDropdownField(
              accounts: accounts,
              selectedId: _accountId,
              accent: FtColors.clay,
              onSelect: (id) => setState(() => _accountId = id),
              sheetTitle: 'Pilih rekening pembayaran',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || _accountId == null ? null : _pay,
              child: Text(_busy ? 'Menyimpan...' : 'Bayar 1 bulan'),
            ),
          ],
        ),
      ),
    );
  }
}

class ObligationFormSheet extends ConsumerStatefulWidget {
  const ObligationFormSheet({super.key, this.initial});
  final Obligation? initial;

  static Future<void> show(BuildContext context, {Obligation? initial}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ObligationFormSheet(initial: initial),
    );
  }

  @override
  ConsumerState<ObligationFormSheet> createState() =>
      _ObligationFormSheetState();
}

class _ObligationFormSheetState extends ConsumerState<ObligationFormSheet> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _monthsTotal = TextEditingController(
    text: widget.initial?.monthsTotal.toString() ?? '',
  );
  late final _monthsPaid = TextEditingController(
    text: widget.initial?.monthsPaid.toString() ?? '0',
  );
  late final _dueDay = TextEditingController(
    text: widget.initial?.dueDay.toString() ?? '1',
  );
  late int _monthly = widget.initial?.monthly ?? 0;
  late int _outstanding = widget.initial?.outstandingPrincipal ?? 0;
  late bool _isDebt = widget.initial?.isDebt ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _monthsTotal.dispose();
    _monthsPaid.dispose();
    _dueDay.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final household = ref.read(currentHouseholdProvider).value;
    final uid = ref.read(authStateProvider).value?.uid;
    if (household == null || uid == null) return;
    final label = _label.text.trim();
    final monthsTotal = int.tryParse(_monthsTotal.text) ?? 0;
    final monthsPaid = int.tryParse(_monthsPaid.text) ?? -1;
    final dueDay = int.tryParse(_dueDay.text) ?? 0;
    if (label.isEmpty || _monthly <= 0) {
      showFtInfoSnack(context, 'Isi nama dan cicilan bulanan dulu.');
      return;
    }
    if (monthsTotal < 1 || monthsPaid < 0 || monthsPaid > monthsTotal) {
      showFtInfoSnack(context, 'Periksa jumlah bulan dan bulan terbayar.');
      return;
    }
    if (dueDay < 1 || dueDay > 31) {
      showFtInfoSnack(context, 'Tanggal jatuh tempo harus 1–31.');
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(obligationRepositoryProvider);
      final initial = widget.initial;
      if (initial == null) {
        await repo.add(
          hid: household.id,
          label: label,
          monthly: _monthly,
          monthsTotal: monthsTotal,
          monthsPaid: monthsPaid,
          dueDay: dueDay,
          createdBy: uid,
          isDebt: _isDebt,
          outstandingPrincipal: _outstanding > 0 ? _outstanding : null,
        );
      } else {
        await repo.update(
          hid: household.id,
          obligationId: initial.id,
          fields: {
            'label': label,
            'monthly': _monthly,
            'monthsTotal': monthsTotal,
            'monthsPaid': monthsPaid,
            'dueDay': dueDay,
            'isDebt': _isDebt,
            'outstandingPrincipal': _outstanding > 0 ? _outstanding : null,
          },
        );
      }
      if (mounted) {
        FtHaptics.success();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showFtErrorSnack(context, e, prefix: 'Gagal menyimpan');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FtColors.bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initial == null ? 'Cicilan baru' : 'Edit cicilan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _label,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama cicilan',
                  hintText: 'Leasing mobil',
                ),
              ),
              const SizedBox(height: 16),
              MoneyField(
                amount: _monthly,
                onChanged: (value) => setState(() => _monthly = value),
                eyebrow: 'Cicilan per bulan',
                autofocus: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _monthsTotal,
                      keyboardType: TextInputType.number,
                      inputFormatters: digits,
                      decoration: const InputDecoration(
                        labelText: 'Total bulan',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _monthsPaid,
                      keyboardType: TextInputType.number,
                      inputFormatters: digits,
                      decoration: const InputDecoration(
                        labelText: 'Sudah dibayar',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dueDay,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(
                  labelText: 'Tanggal jatuh tempo (1–31)',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Utang', style: TextStyle(fontSize: 13.5)),
                subtitle: Text(
                  _isDebt
                      ? 'Leasing/KPR — ikut rasio cicilan (batas OJK 30%)'
                      : 'Biaya tetap (sewa dll) — tidak ikut rasio cicilan',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
                value: _isDebt,
                onChanged: (v) => setState(() => _isDebt = v),
              ),
              if (_isDebt) ...[
                const SizedBox(height: 8),
                MoneyField(
                  amount: _outstanding,
                  onChanged: (value) => setState(() => _outstanding = value),
                  eyebrow: 'Sisa pokok (opsional)',
                  autofocus: false,
                ),
                Text(
                  'Sisa pokok dari leasing/bank (opsional)',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
