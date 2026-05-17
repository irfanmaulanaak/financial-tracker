import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/providers.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';
import 'settings_row.dart';

/// "Rumah Tangga" section in Settings — name / payday / monthly budget.
/// Edits are gated by `canEdit` (full-access only); blocked attempts emit
/// a toast.
class HouseholdSection extends StatelessWidget {
  const HouseholdSection({
    super.key,
    required this.household,
    required this.canEdit,
    required this.ref,
  });

  final Household household;
  final bool canEdit;
  final WidgetRef ref;

  void _gate(BuildContext context, Future<void> Function() action) {
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak punya akses untuk tindakan ini.')),
      );
      return;
    }
    // ignore: discarded_futures
    action();
  }

  Future<void> _editName(BuildContext context) async {
    final ctrl = TextEditingController(text: household.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nama keluarga'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Mis. Keluarga Andini'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref
          .read(firestoreProvider)
          .collection('households')
          .doc(household.id)
          .update({'name': ctrl.text.trim()});
    }
    ctrl.dispose();
  }

  Future<void> _editPayday(BuildContext context) async {
    int selected = household.payday;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tanggal gajian'),
        content: StatefulBuilder(
          builder: (_, setState) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 31,
              itemBuilder: (_, i) {
                final day = i + 1;
                return ListTile(
                  dense: true,
                  title: Text('Tanggal $day'),
                  trailing:
                      selected == day ? const Icon(Icons.check) : null,
                  onTap: () => setState(() => selected = day),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(firestoreProvider)
          .collection('households')
          .doc(household.id)
          .update({'payday': selected});
    }
  }

  Future<void> _editBudget(BuildContext context) async {
    final ctrl = TextEditingController(
      text: household.monthlyBudgetTotal.toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anggaran bulanan'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            hintText: '5000000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final v = int.tryParse(ctrl.text.replaceAll(RegExp(r'\D'), ''));
      if (v != null) {
        await ref
            .read(firestoreProvider)
            .collection('households')
            .doc(household.id)
            .update({'monthlyBudgetTotal': v});
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: Eyebrow('Rumah Tangga'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                label: 'Nama keluarga',
                detail: household.name,
                onTap: () => _gate(context, () => _editName(context)),
              ),
              const Divider(),
              SettingsRow(
                label: 'Tanggal gajian',
                detail: 'Tgl ${household.payday}',
                onTap: () => _gate(context, () => _editPayday(context)),
              ),
              const Divider(),
              SettingsRow(
                label: 'Anggaran bulanan',
                detail: Money.format(household.monthlyBudgetTotal),
                onTap: () => _gate(context, () => _editBudget(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
