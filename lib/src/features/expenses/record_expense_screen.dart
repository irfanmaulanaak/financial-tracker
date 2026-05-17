import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import 'expense_repository.dart';

class RecordExpenseScreen extends ConsumerStatefulWidget {
  const RecordExpenseScreen({super.key});

  @override
  ConsumerState<RecordExpenseScreen> createState() =>
      _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  int _amount = 0;
  String? _categoryId;
  String _payType = 'cash'; // 'cash' | 'credit'
  String? _cashMethodId;
  String? _cardId;
  String? _spentBy;
  DateTime _date = DateTime.now();
  final _note = TextEditingController();
  bool _recurring = false;
  bool _cicilan = false;
  int _cicilanMonths = 6;
  double _cicilanApr = 0.0;
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

  Future<void> _submit(Household h, List<CreditCard> cards) async {
    if (_amount <= 0 || _categoryId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Lengkapi jumlah & kategori');
      return;
    }
    final methodId =
        _payType == 'credit' ? _creditMethodId(h) : _cashMethodId;
    if (methodId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Pilih metode bayar');
      return;
    }
    if (_payType == 'credit' && _cardId == null) {
      FtHaptics.warning();
      setState(() => _error = 'Pilih kartu kredit');
      return;
    }
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();
      final user = ref.read(firebaseAuthProvider).currentUser!;
      final spentBy = _spentBy ?? user.uid;

      if (_payType == 'credit' && _cicilan) {
        await repo.addCicilanExpense(
          householdId: h.id,
          principal: _amount,
          categoryId: _categoryId!,
          paymentMethodId: methodId,
          spentBy: spentBy,
          date: _date,
          cardId: _cardId!,
          months: _cicilanMonths,
          apr: _cicilanApr,
          note: note,
        );
      } else if (_payType == 'credit') {
        await repo.addCardExpense(
          householdId: h.id,
          amount: _amount,
          categoryId: _categoryId!,
          paymentMethodId: methodId,
          spentBy: spentBy,
          date: _date,
          cardId: _cardId!,
          note: note,
          recurring: _recurring,
        );
      } else {
        await repo.add(
          householdId: h.id,
          amount: _amount,
          categoryId: _categoryId!,
          paymentMethodId: methodId,
          spentBy: spentBy,
          date: _date,
          note: note,
          recurring: _recurring,
        );
      }
      if (mounted) {
        FtHaptics.success();
        context.pop();
      }
    } catch (e) {
      FtHaptics.error();
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _creditMethodId(Household h) =>
      h.paymentMethods.where((p) => p.type == 'credit').isNotEmpty
          ? h.paymentMethods.firstWhere((p) => p.type == 'credit').id
          : null;

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _spentBy ??= user.uid;
    final categories =
        household.categories.where((c) => !c.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // Default-select the first category so the form starts in a valid state.
    if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
    final cashMethods = household.paymentMethods
        .where((p) => p.type != 'credit')
        .toList();
    final cards = ref.watch(cardsProvider(household.id)).value ?? const [];
    if (_payType == 'cash' &&
        _cashMethodId == null &&
        cashMethods.isNotEmpty) {
      _cashMethodId = cashMethods.first.id;
    }
    if (_payType == 'credit' && _cardId == null && cards.isNotEmpty) {
      _cardId = cards.first.id;
      _cicilanApr = cards.first.apr;
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Catat pengeluaran',
              trailing: _SubmitDot(
                busy: _busy,
                enabled: _amount > 0 && _categoryId != null,
                onTap: () => _submit(household, cards),
              ),
            ),
            Expanded(
              child: FtFadeUp(
                duration: const Duration(milliseconds: 320),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  children: [
                    _AmountDisplay(amount: _amount),
                    const SizedBox(height: 24),
                    const Eyebrow('Kategori'),
                    const SizedBox(height: 10),
                    _CategoryChips(
                      categories: categories,
                      selected: _categoryId,
                      onSelect: (id) {
                        FtHaptics.select();
                        setState(() => _categoryId = id);
                      },
                    ),
                    const SizedBox(height: 22),
                    const Eyebrow('Pembayaran'),
                    const SizedBox(height: 10),
                    _PayTypeToggle(
                      value: _payType,
                      onChange: (v) {
                        FtHaptics.select();
                        setState(() => _payType = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_payType == 'cash')
                      _MethodChips(
                        methods: cashMethods,
                        selected: _cashMethodId,
                        onSelect: (id) {
                          FtHaptics.select();
                          setState(() => _cashMethodId = id);
                        },
                      )
                    else
                      _CardPicker(
                        cards: cards,
                        selected: _cardId,
                        onSelect: (id) {
                          FtHaptics.select();
                          setState(() {
                            _cardId = id;
                            final c = cards.firstWhere((x) => x.id == id);
                            _cicilanApr = c.apr;
                          });
                        },
                      ),
                    if (_payType == 'credit' && cards.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Eyebrow('Cicilan'),
                      const SizedBox(height: 10),
                      _CicilanPlans(
                        cicilan: _cicilan,
                        months: _cicilanMonths,
                        apr: _cicilanApr,
                        onSelect: (months, apr) {
                          FtHaptics.select();
                          setState(() {
                            _cicilan = months > 1;
                            _cicilanMonths = months > 1 ? months : 6;
                            _cicilanApr = apr;
                          });
                        },
                      ),
                      if (_cicilan && _amount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _CicilanPreview(
                            amount: _amount,
                            months: _cicilanMonths,
                            apr: _cicilanApr,
                          ),
                        ),
                    ],
                    const SizedBox(height: 22),
                    FtInput(
                      label: 'Catatan (opsional)',
                      controller: _note,
                      hintText: 'Misal: Kopi Tuku',
                    ),
                    const SizedBox(height: 14),
                    _MetaRow(
                      date: _date,
                      recurring: _recurring,
                      onPickDate: _pickDate,
                      onToggleRecurring: _cicilan
                          ? null
                          : (v) {
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
      onTap: enabled && !busy ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? FtColors.ink : FtColors.line,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FtColors.bg,
                ),
              )
            : Icon(
                Icons.check,
                size: 18,
                color: enabled ? FtColors.bg : FtColors.ink3,
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
        const Eyebrow('Jumlah'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Rp',
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
                  // Strip the leading "Rp" (with or without trailing space) —
                  // the static "Rp" prefix is rendered separately above.
                  Money.format(amount).replaceFirst(RegExp(r'^Rp\s*'), ''),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 48,
                        height: 1,
                        letterSpacing: -1.5,
                        color: FtColors.ink,
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
      // Matches design's `ft-pulse` 2.4s ease-in-out breath.
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curve,
      builder: (_, _) {
        final t = curve.value;
        return Opacity(
          opacity: 0.45 + (1 - t) * 0.55,
          child: Transform.scale(
            scaleY: 1 - t * 0.05,
            child: Container(width: 2, height: 38, color: FtColors.clay),
          ),
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<Category> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in categories)
          _CategoryChip(
            label: c.label.split(' ').first,
            color: Color(int.parse('FF${c.color.replaceFirst('#', '')}',
                radix: 16)),
            iconKey: c.icon,
            selected: selected == c.id,
            onTap: () => onSelect(c.id),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  static final _icons = <String, IconData>{
    'restaurant': Icons.restaurant,
    'receipt_long': Icons.receipt_long,
    'shopping_bag': Icons.shopping_bag,
    'directions_car': Icons.directions_car,
    'movie': Icons.movie,
    'favorite': Icons.favorite,
    'school': Icons.school,
    'sports_esports': Icons.sports_esports,
  };

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.95,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[iconKey] ?? Icons.category,
              size: 13,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : FtColors.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayTypeToggle extends StatelessWidget {
  const _PayTypeToggle({required this.value, required this.onChange});
  final String value;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtColors.line, width: 0.5),
      ),
      child: Row(
        children: [
          _seg(value == 'cash', Icons.payments_outlined, 'Tunai / Debit',
              () => onChange('cash')),
          _seg(value == 'credit', Icons.credit_card_outlined, 'Kartu Kredit',
              () => onChange('credit')),
        ],
      ),
    );
  }

  Widget _seg(bool on, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: FtTapScale(
        scale: 0.97,
        haptic: false,
        onTap: on ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? FtColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: on ? FtColors.bg : FtColors.ink2),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: on ? FtColors.bg : FtColors.ink2,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodChips extends StatelessWidget {
  const _MethodChips({
    required this.methods,
    required this.selected,
    required this.onSelect,
  });
  final List<PaymentMethod> methods;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in methods)
          FtTapScale(
            scale: 0.97,
            haptic: false,
            onTap: () => onSelect(m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected == m.id
                    ? FtColors.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected == m.id
                      ? FtColors.lineStrong
                      : FtColors.line,
                  width: 0.5,
                ),
              ),
              child: Text(
                m.label,
                style: TextStyle(
                  color: selected == m.id ? FtColors.ink : FtColors.ink3,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CardPicker extends StatelessWidget {
  const _CardPicker({
    required this.cards,
    required this.selected,
    required this.onSelect,
  });
  final List<CreditCard> cards;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Text(
        'Belum ada kartu. Tambah dari menu Kartu kredit.',
        style: TextStyle(color: FtColors.ink3, fontSize: 12),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(
            child: _CardTile(
              card: cards[i],
              selected: selected == cards[i].id,
              onTap: () => onSelect(cards[i].id),
            ),
          ),
          if (i != cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });
  final CreditCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = FtColors.plum;
    final remaining = card.limit - card.used;
    return FtTapScale(
      scale: 0.97,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : FtColors.surface,
          border: Border.all(
            color: selected ? accent : FtColors.line,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    card.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '•••• ${card.last4}',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 10,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: card.limit <= 0
                    ? 0
                    : (card.used / card.limit).clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: FtColors.line,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sisa ${Money.format(remaining).replaceFirst('Rp ', 'Rp')}',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 9.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CicilanPlans extends StatelessWidget {
  const _CicilanPlans({
    required this.cicilan,
    required this.months,
    required this.apr,
    required this.onSelect,
  });
  final bool cicilan;
  final int months;
  final double apr;
  final void Function(int months, double apr) onSelect;

  @override
  Widget build(BuildContext context) {
    final plans = [
      (1, 0.0, 'Lunas'),
      (3, 0.0, '3×'),
      (6, 0.0, '6×'),
      (12, apr, '12×'),
    ];
    return Row(
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          Expanded(
            child: _planChip(
              label: plans[i].$3,
              apr: plans[i].$2,
              selected: cicilan
                  ? months == plans[i].$1
                  : plans[i].$1 == 1,
              onTap: () => onSelect(plans[i].$1, plans[i].$2),
            ),
          ),
          if (i != plans.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _planChip({
    required String label,
    required double apr,
    required bool selected,
    required VoidCallback onTap,
  }) {
    // Caption rules — design uses "penuh" for the 1-month full-payment plan,
    // "0%" for interest-free installments, "{apr}% pa" for accruing plans.
    final caption = label == 'Lunas'
        ? 'penuh'
        : apr == 0
            ? '0%'
            : '${(apr * 100).toStringAsFixed(0)}% pa';
    return FtTapScale(
      scale: 0.95,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? FtColors.ink : FtColors.surface,
          border: Border.all(
            color: selected ? FtColors.ink : FtColors.line,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Newsreader',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? FtColors.bg : FtColors.ink2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              caption,
              style: TextStyle(
                color: selected ? FtColors.bg : FtColors.ink3,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CicilanPreview extends StatelessWidget {
  const _CicilanPreview({
    required this.amount,
    required this.months,
    required this.apr,
  });
  final int amount;
  final int months;
  final double apr;

  @override
  Widget build(BuildContext context) {
    final plan = computeCicilan(principal: amount, months: months, apr: apr);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        border: Border.all(color: FtColors.line, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cicilan per bulan',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ),
              Text.rich(
                TextSpan(
                  text: Money.format(plan.monthly),
                  style: TextStyle(
                    fontFamily: 'Newsreader',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: FtColors.ink,
                  ),
                  children: [
                    TextSpan(
                      text: ' × $months bln',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: FtColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total bayar',
                  style: TextStyle(color: FtColors.ink3, fontSize: 10),
                ),
              ),
              Text(
                Money.format(plan.total),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: FtColors.ink3,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (plan.totalInterest > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bunga (${(apr * 100).toStringAsFixed(1)}% pa)',
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    '+${Money.format(plan.totalInterest)}',
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 10,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
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
  final ValueChanged<bool>? onToggleRecurring;

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
        if (onToggleRecurring != null)
          FtTapScale(
            scale: 0.97,
            onTap: () => onToggleRecurring!(!recurring),
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
    final keyboardOpen = bottomInset > 0;
    if (keyboardOpen) return const SizedBox.shrink();
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
