import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_action_sheet.dart';
import '../../ui/ft_celebrate.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/household_repository.dart';

/// "Geser anggaran" — pindahkan sebagian anggaran kategori lain ke [toId]
/// di tengah siklus (YNAB "roll with the punches"). Tercatat siapa/kapan
/// di log household (tampil di recap).
class BudgetMoveSheet extends ConsumerStatefulWidget {
  const BudgetMoveSheet({super.key, required this.toId});

  /// Kategori tujuan (yang anggarannya mau ditambah).
  final String toId;

  static Future<void> show(BuildContext context, {required String toId}) {
    return showFtActionSheet<void>(
      context: context,
      builder: (_) => BudgetMoveSheet(toId: toId),
    );
  }

  @override
  ConsumerState<BudgetMoveSheet> createState() => _BudgetMoveSheetState();
}

class _BudgetMoveSheetState extends ConsumerState<BudgetMoveSheet> {
  String? _fromId;
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final household = ref.read(currentHouseholdProvider).value;
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (household == null || user == null || _fromId == null) return;
    final amount = Money.parse(_amount.text) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Isi jumlah yang mau digeser');
      return;
    }
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(householdRepositoryProvider).moveBudget(
            householdId: household.id,
            fromId: _fromId!,
            toId: widget.toId,
            amount: amount,
            by: user.uid,
          );
      if (mounted) {
        FtCelebrate.show(context, message: 'Anggaran digeser');
        Navigator.of(context).pop();
      }
    } on StateError catch (e) {
      FtHaptics.error();
      setState(() => _error = switch (e.message) {
            'insufficient_budget' => 'Anggaran kategori sumber tidak cukup',
            'same_category' => 'Pilih kategori yang berbeda',
            _ => 'Gagal: ${e.message}',
          });
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
    if (household == null) return const SizedBox.shrink();
    final to = household.categoryOf(widget.toId);
    final expenses =
        ref.watch(cycleExpensesProvider).value ?? const <Expense>[];
    final spentBy = <String, int>{};
    for (final e in expenses) {
      spentBy.update(e.categoryId, (v) => v + e.amount,
          ifAbsent: () => e.amount);
    }
    final sources = [
      for (final c in household.categories)
        if (!c.archived && c.id != widget.toId && c.monthlyBudget > 0) c,
    ]..sort((a, b) {
        // Paling longgar (sisa terbanyak) di atas — kandidat terbaik.
        final ra = a.monthlyBudget - (spentBy[a.id] ?? 0);
        final rb = b.monthlyBudget - (spentBy[b.id] ?? 0);
        return rb.compareTo(ra);
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geser anggaran ke "${to?.label ?? '?'}"',
            style: TextStyle(
              fontFamily: 'Geist',
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 20,
              color: FtColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ambil dari kategori yang masih longgar. Total anggaran siklus tidak berubah; pergeseran tercatat untuk semua anggota.',
            style: TextStyle(color: FtColors.ink3, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Eyebrow('Ambil dari'),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 210),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final c in sources)
                    _SourceRow(
                      category: c,
                      remaining:
                          c.monthlyBudget - (spentBy[c.id] ?? 0),
                      selected: _fromId == c.id,
                      onTap: () {
                        FtHaptics.select();
                        setState(() => _fromId = c.id);
                      },
                    ),
                ],
              ),
            ),
          ),
          if (sources.isEmpty)
            Text(
              'Tidak ada kategori lain yang punya anggaran.',
              style: TextStyle(color: FtColors.ink3, fontSize: 12),
            ),
          const SizedBox(height: 14),
          FtInput(
            label: 'Jumlah',
            controller: _amount,
            hintText: 'Misal: 200.000',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorFormatter()],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: FtColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_busy || _fromId == null) ? null : _submit,
              child: Text(_busy ? 'Menyimpan…' : 'Geser anggaran'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.category,
    required this.remaining,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final int remaining;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? FtColors.ink : FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? FtColors.ink : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: TextStyle(
                  color: selected ? FtColors.bg : FtColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              remaining >= 0
                  ? 'sisa ${Money.compact(remaining)} / ${Money.compact(category.monthlyBudget)}'
                  : 'lebih ${Money.compact(-remaining)}',
              style: TextStyle(
                color: selected
                    ? FtColors.bg.withValues(alpha: 0.8)
                    : (remaining < 0 ? FtColors.danger : FtColors.ink3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
