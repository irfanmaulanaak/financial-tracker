import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import '../../ui/ft_submit_dot.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../record_common/account_picker.dart';
import '../record_common/money_field.dart';
import 'transfer_repository.dart';

/// Move money between two of the household's tracked accounts. Tracked
/// in `households/{hid}/transfers` so the user can audit the history;
/// the actual balance changes are atomically applied to the household
/// root's `cashAccounts`/`savingsAccounts` arrays in the same txn.
///
/// Fees are entered separately and "lost" — money leaves the source by
/// `amount + fee` but only `amount` lands on the destination. The gap
/// is the operator/transfer fee.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  int _amount = 0;
  int _fee = 0;
  String? _sourceId;
  String? _destinationId;
  DateTime _date = DateTime.now();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
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
    if (_sourceId == null || _destinationId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Pilih sumber dan tujuan');
      return;
    }
    if (_sourceId == _destinationId) {
      FtHaptics.warning();
      setState(() => _error = 'Sumber dan tujuan tidak boleh sama');
      return;
    }
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(transferRepositoryProvider).add(
            householdId: household.id,
            amount: _amount,
            fee: _fee,
            sourceAccountId: _sourceId!,
            destinationAccountId: _destinationId!,
            transferredBy: user.uid,
            date: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) {
        FtHaptics.success();
        context.pop();
      }
    } on StateError catch (e) {
      FtHaptics.error();
      final msg = switch (e.message) {
        'insufficient' => 'Saldo rekening sumber tidak cukup',
        'account_missing' => 'Rekening tidak ditemukan',
        'same_account' => 'Sumber dan tujuan tidak boleh sama',
        _ => 'Gagal: ${e.message}',
      };
      setState(() => _error = msg);
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
    final all = recordAccountChoices(
      cashAccounts: household.cashAccounts,
      savingsAccounts: household.savingsAccounts,
    );
    if (all.length < 2) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              const FtSubHeader(title: 'Pindah Dana'),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Butuh minimal dua rekening untuk pindah dana. Tambah rekening lewat Aset → Tunai atau Tabungan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FtColors.ink3, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final canSubmit = _amount > 0 &&
        _sourceId != null &&
        _destinationId != null &&
        _sourceId != _destinationId &&
        !_busy &&
        ref.watch(canRecordTxnProvider);
    final netToDest = _amount;
    final totalFromSrc = _amount + _fee;

    return Scaffold(
      backgroundColor: FtColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Pindah Dana',
              trailing: FtSubmitDot(
                busy: _busy,
                enabled: canSubmit,
                onTap: _submit,
                activeColor: FtColors.clay,
              ),
            ),
            Expanded(
              child: FtFadeUp(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  children: [
                    MoneyField(
                      amount: _amount,
                      onChanged: (v) => setState(() => _amount = v),
                      eyebrow: 'Jumlah pindah',
                      activeColor: FtColors.clay,
                    ),
                    const SizedBox(height: 14),
                    _FeeRow(
                      fee: _fee,
                      onChanged: (v) => setState(() => _fee = v),
                    ),
                    if (_fee > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Total dipotong dari sumber: ${Money.format(totalFromSrc)} · Masuk ke tujuan: ${Money.format(netToDest)}',
                        style: TextStyle(color: FtColors.ink3, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Eyebrow('Dari rekening'),
                    const SizedBox(height: 10),
                    RecordAccountDropdownField(
                      accounts: all,
                      selectedId: _sourceId,
                      accent: FtColors.clay,
                      sheetTitle: 'Pilih rekening sumber',
                      enableSubKindFilter: true,
                      onSelect: (id) {
                        FtHaptics.select();
                        setState(() {
                          _sourceId = id;
                          if (_destinationId == id) _destinationId = null;
                          _error = null;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    const Eyebrow('Ke rekening'),
                    const SizedBox(height: 10),
                    RecordAccountDropdownField(
                      accounts:
                          all.where((a) => a.id != _sourceId).toList(),
                      selectedId: _destinationId,
                      accent: FtColors.clay,
                      sheetTitle: 'Pilih rekening tujuan',
                      enableSubKindFilter: true,
                      onSelect: (id) {
                        FtHaptics.select();
                        setState(() {
                          _destinationId = id;
                          _error = null;
                        });
                      },
                      emptyNote:
                          'Pilih rekening sumber dulu untuk melihat tujuan.',
                    ),
                    const SizedBox(height: 18),
                    FtInput(
                      label: 'Catatan (opsional)',
                      controller: _note,
                      hintText: 'Misal: Top-up GoPay',
                    ),
                    const SizedBox(height: 14),
                    _DateRow(date: _date, onTap: _pickDate),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: FtColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatefulWidget {
  const _FeeRow({required this.fee, required this.onChanged});
  final int fee;
  final ValueChanged<int> onChanged;

  @override
  State<_FeeRow> createState() => _FeeRowState();
}

class _FeeRowState extends State<_FeeRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _displayFor(widget.fee));
  }

  @override
  void didUpdateWidget(covariant _FeeRow old) {
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

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap});
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
