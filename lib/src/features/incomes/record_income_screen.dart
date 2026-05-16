import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
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
    setState(() {
      if (k == '←') {
        _amount = _amount ~/ 10;
      } else if (k == '000') {
        _amount = (_amount * 1000).clamp(0, 999999999);
      } else {
        _amount = (_amount * 10 + int.parse(k)).clamp(0, 999999999);
      }
    });
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
    final canSubmit =
        _amount > 0 && _destinationAccountId != null && !_busy;

    return Scaffold(
      backgroundColor: FtColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Catat pemasukan',
              trailing: _SubmitDot(
                busy: _busy,
                enabled: canSubmit,
                onTap: _submit,
              ),
            ),
            Expanded(
              child: FtFadeUp(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  children: [
                    _AmountDisplay(amount: _amount),
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
                    _MetaRow(
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
            _Keypad(onTap: _tapKey),
          ],
        ),
      ),
    );
  }
}

class _SubmitDot extends StatelessWidget {
  const _SubmitDot({
    required this.busy,
    required this.enabled,
    required this.onTap,
  });
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.9,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? FtColors.moss : FtColors.line,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                Icons.check,
                size: 18,
                color: enabled ? Colors.white : FtColors.ink3,
              ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Eyebrow('Jumlah pendapatan'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '+Rp',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Money.format(amount).replaceFirst('Rp ', ''),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 48,
                        height: 1,
                        letterSpacing: -1.5,
                        color: amount > 0 ? FtColors.moss : FtColors.ink,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const _BlinkCursor(),
          ],
        ),
      ],
    );
  }
}

class _BlinkCursor extends StatefulWidget {
  const _BlinkCursor();
  @override
  State<_BlinkCursor> createState() => _BlinkCursorState();
}

class _BlinkCursorState extends State<_BlinkCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(_ctrl),
      child: Container(width: 2, height: 38, color: FtColors.moss),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.date,
    required this.recurring,
    required this.onPickDate,
    required this.onToggleRecurring,
  });
  final DateTime date;
  final bool recurring;
  final VoidCallback onPickDate;
  final ValueChanged<bool> onToggleRecurring;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FtTapScale(
            scale: 0.97,
            onTap: onPickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: FtColors.surface,
                border: Border.all(color: FtColors.line, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: FtColors.ink3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Dates.short(date),
                      style: TextStyle(
                        color: FtColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FtTapScale(
          scale: 0.97,
          onTap: () => onToggleRecurring(!recurring),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: recurring ? FtColors.moss : FtColors.surface,
              border: Border.all(
                color: recurring ? FtColors.moss : FtColors.line,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_repeat_outlined,
                  size: 14,
                  color: recurring ? Colors.white : FtColors.ink3,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rutin',
                  style: TextStyle(
                    color: recurring ? Colors.white : FtColors.ink2,
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

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onTap});
  final ValueChanged<String> onTap;

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '000', '0', '←',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (bottomInset > 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            for (final k in _keys)
              FtTapScale(
                scale: 0.94,
                haptic: false,
                onTap: () => onTap(k),
                child: Container(
                  decoration: BoxDecoration(
                    color: FtColors.surface,
                    border: Border.all(color: FtColors.line, width: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    k,
                    style: TextStyle(
                      fontFamily: 'Newsreader',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: FtColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
