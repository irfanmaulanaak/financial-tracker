import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_submit_dot.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../record_common/amount_display.dart';
import '../record_common/keypad.dart';
import '../record_common/meta_row.dart';
import 'income.dart';
import 'income_repository.dart';

class RecordIncomeScreen extends ConsumerStatefulWidget {
  const RecordIncomeScreen({super.key});

  @override
  ConsumerState<RecordIncomeScreen> createState() => _RecordIncomeScreenState();
}

class _RecordIncomeScreenState extends ConsumerState<RecordIncomeScreen> {
  int _amount = 0;
  IncomeSource _source = IncomeSource.salary;
  String? _destinationAccountId;
  String? _receivedBy;
  DateTime _date = DateTime.now();
  final _note = TextEditingController();
  bool _recurring = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _tapKey(String k) {
    FtHaptics.tap();
    setState(() => _amount = applyRecordKey(_amount, k));
  }

  Future<void> _pickDate() async {
    FtHaptics.select();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final household = ref.read(currentHouseholdProvider).value;
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (household == null || user == null) return;
    if (_amount <= 0) {
      FtHaptics.warning();
      setState(() => _error = 'Nominal tidak valid');
      return;
    }
    if (_destinationAccountId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Pilih akun tujuan');
      return;
    }
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(incomeRepositoryProvider).add(
            householdId: household.id,
            amount: _amount,
            source: _source,
            destinationAccountId: _destinationAccountId!,
            receivedBy: _receivedBy ?? user.uid,
            date: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            recurring: _recurring,
          );
      if (mounted) {
        FtHaptics.success();
        context.pop();
      }
    } on StateError catch (e) {
      FtHaptics.error();
      setState(() => _error = 'Gagal: ${e.message}');
    } catch (e) {
      FtHaptics.error();
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _receivedBy ??= user.uid;
    final accounts = [
      for (final a in household.cashAccounts)
        (id: a.id, label: a.label, hint: 'Tunai · ${Money.format(a.value)}'),
      for (final a in household.savingsAccounts)
        (id: a.id, label: a.label, hint: 'Tabungan · ${Money.format(a.value)}'),
    ];
    final canSubmit = _amount > 0 &&
        _destinationAccountId != null &&
        !_busy &&
        ref.watch(canRecordTxnProvider);

    return Scaffold(
      backgroundColor: FtColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Catat pemasukan',
              trailing: FtSubmitDot(
                busy: _busy,
                enabled: canSubmit,
                onTap: _submit,
                activeColor: FtColors.moss,
              ),
            ),
            Expanded(
              child: FtFadeUp(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  children: [
                    RecordAmountDisplay(
                      amount: _amount,
                      eyebrow: 'Jumlah pendapatan',
                      prefix: '+Rp',
                      cursorColor: FtColors.moss,
                      activeColor: FtColors.moss,
                    ),
                    const SizedBox(height: 24),
                    const Eyebrow('Sumber'),
                    const SizedBox(height: 10),
                    _SourceChips(
                      selected: _source,
                      onSelect: (s) {
                        FtHaptics.select();
                        setState(() => _source = s);
                      },
                    ),
                    const SizedBox(height: 22),
                    const Eyebrow('Masuk ke'),
                    const SizedBox(height: 10),
                    if (accounts.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Belum ada akun. Tambah dari menu Akun.',
                          style: TextStyle(color: FtColors.danger, fontSize: 12),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final a in accounts) ...[
                            _AccountRow(
                              label: a.label,
                              hint: a.hint,
                              selected: _destinationAccountId == a.id,
                              onTap: () {
                                FtHaptics.select();
                                setState(() => _destinationAccountId = a.id);
                              },
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    const SizedBox(height: 14),
                    FtInput(
                      label: 'Catatan (opsional)',
                      controller: _note,
                      hintText: 'Misal: Bonus akhir tahun',
                    ),
                    const SizedBox(height: 14),
                    RecordMetaRow(
                      date: _date,
                      recurring: _recurring,
                      onPickDate: _pickDate,
                      onToggleRecurring: (v) {
                        FtHaptics.select();
                        setState(() => _recurring = v);
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            RecordKeypad(onTap: _tapKey),
          ],
        ),
      ),
    );
  }
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({required this.selected, required this.onSelect});
  final IncomeSource selected;
  final ValueChanged<IncomeSource> onSelect;

  static const _icons = {
    IncomeSource.salary: Icons.payments_outlined,
    IncomeSource.freelance: Icons.auto_awesome_outlined,
    IncomeSource.invest: Icons.trending_up,
    IncomeSource.gift: Icons.card_giftcard_outlined,
    IncomeSource.refund: Icons.south_outlined,
    IncomeSource.other: Icons.more_horiz,
  };
  static final _colors = {
    IncomeSource.salary: FtColors.sage,
    IncomeSource.freelance: FtColors.clay,
    IncomeSource.invest: FtColors.moss,
    IncomeSource.gift: FtColors.plum,
    IncomeSource.refund: FtColors.sky,
    IncomeSource.other: FtColors.ink3,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in IncomeSource.values)
          FtTapScale(
            scale: 0.95,
            haptic: false,
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected == s ? _colors[s] : FtColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected == s ? _colors[s]! : FtColors.line,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[s],
                    size: 13,
                    color: selected == s ? Colors.white : _colors[s],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    incomeSourceLabel(s),
                    style: TextStyle(
                      color: selected == s ? Colors.white : FtColors.ink2,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.985,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? FtColors.moss.withValues(alpha: 0.08)
              : FtColors.surface,
          border: Border.all(
            color: selected ? FtColors.moss : FtColors.line,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? FtColors.moss : FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? FtColors.moss : FtColors.line,
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.account_balance_outlined,
                size: 14,
                color: selected ? Colors.white : FtColors.ink2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check, size: 16, color: FtColors.moss),
          ],
        ),
      ),
    );
  }
}

