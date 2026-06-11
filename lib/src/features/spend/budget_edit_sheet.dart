import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_snackbar.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/household_repository.dart';

/// Bottom sheet for editing a single category's monthly budget — invoked
/// from the Spend screen row popup. Keeps the heavier add/edit-category UX
/// in `category_manage_screen.dart`; this sheet stays focused on the one
/// number that needs tweaking from the spend context.
class BudgetEditSheet extends ConsumerStatefulWidget {
  const BudgetEditSheet({super.key, required this.category});

  final Category category;

  static Future<void> show({
    required BuildContext context,
    required Category category,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetEditSheet(category: category),
    );
  }

  @override
  ConsumerState<BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<BudgetEditSheet> {
  late final TextEditingController _budget = TextEditingController(
    text: Money.displayDigits(widget.category.monthlyBudget),
  );
  late bool _rollover = widget.category.rollover;
  bool _busy = false;

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;
    final next = Money.parse(_budget.text) ?? 0;
    setState(() => _busy = true);
    try {
      final updated = household.categories
          .map((c) => c.id == widget.category.id
              ? c.copyWith(monthlyBudget: next, rollover: _rollover)
              : c)
          .toList();
      await ref.read(householdRepositoryProvider).updateCategories(
            householdId: household.id,
            categories: updated,
          );
      if (mounted) {
        FtHaptics.success();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showFtErrorSnack(context, e, prefix: 'Gagal menyimpan anggaran');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: FtColors.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Anggaran ${widget.category.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Batas pengeluaran bulanan untuk kategori ini.',
              style: TextStyle(color: FtColors.ink3, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budget,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Anggaran bulanan',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sisa amplop bergulir',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sisa anggaran siklus lalu ditambahkan ke amplop siklus ini.',
                        style: TextStyle(color: FtColors.ink3, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _rollover,
                  activeTrackColor: FtColors.clay,
                  onChanged: (v) {
                    FtHaptics.select();
                    setState(() => _rollover = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
