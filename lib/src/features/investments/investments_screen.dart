import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../household/household_providers.dart';
import 'investment.dart';
import 'investments_repository.dart';

final investmentsProvider =
    StreamProvider.family<List<Investment>, String>((ref, hid) {
  return ref.watch(investmentsRepositoryProvider).watchAll(hid);
});

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final invAsync = ref.watch(investmentsProvider(household.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Investasi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context, ref, household.id),
        icon: const Icon(Icons.add),
        label: const Text('Posisi baru'),
      ),
      body: invAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (items) {
          final summary = summarisePortfolio(items);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _Summary(summary: summary),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'Belum ada investasi.\nTambah posisi manual via tombol "+".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...items.map((i) => _InvestmentTile(
                      inv: i,
                      onUpdate: () =>
                          _openUpdateValue(context, ref, household.id, i),
                      onDelete: () => _confirmDelete(context, ref, household.id, i),
                    )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAdd(
      BuildContext context, WidgetRef ref, String hid) async {
    final draft = await showModalBottomSheet<_Draft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _InvestmentEditSheet(),
    );
    if (draft == null) return;
    await ref.read(investmentsRepositoryProvider).add(
          hid: hid,
          label: draft.label,
          type: draft.type,
          currentValue: draft.currentValue,
          costBasis: draft.costBasis,
        );
  }

  Future<void> _openUpdateValue(
      BuildContext context, WidgetRef ref, String hid, Investment i) async {
    final ctrl = TextEditingController(text: i.currentValue.toString());
    final v = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update ${i.label}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Nilai sekarang', prefixText: 'Rp '),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text);
                if (v == null) return;
                Navigator.pop(context, v);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (v != null) {
      await ref
          .read(investmentsRepositoryProvider)
          .updateValue(hid: hid, id: i.id, currentValue: v);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String hid, Investment i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus "${i.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(investmentsRepositoryProvider)
          .delete(hid: hid, id: i.id);
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});
  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final positive = summary.totalGain >= 0;
    final color = positive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total portofolio',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          Text(Money.format(summary.totalValue),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '${positive ? '+' : ''}${Money.format(summary.totalGain)} (${(summary.gainPct * 100).toStringAsFixed(1)}%)',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Diversifikasi: ${summary.distinctTypes} jenis aset',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  const _InvestmentTile(
      {required this.inv, required this.onUpdate, required this.onDelete});
  final Investment inv;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final positive = inv.gain >= 0;
    final color = positive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Card(
      child: ListTile(
        onTap: onUpdate,
        title: Text(inv.label),
        subtitle: Text(
            '${investmentTypeLabel(inv.type)} • cost ${Money.format(inv.costBasis)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Money.format(inv.currentValue),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${positive ? '+' : ''}${(inv.gainPct * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        onLongPress: onDelete,
      ),
    );
  }
}

class _Draft {
  final String label;
  final InvestmentType type;
  final int currentValue;
  final int costBasis;
  const _Draft(this.label, this.type, this.currentValue, this.costBasis);
}

class _InvestmentEditSheet extends StatefulWidget {
  const _InvestmentEditSheet();
  @override
  State<_InvestmentEditSheet> createState() => _InvestmentEditSheetState();
}

class _InvestmentEditSheetState extends State<_InvestmentEditSheet> {
  final _label = TextEditingController();
  final _current = TextEditingController();
  final _cost = TextEditingController();
  InvestmentType _type = InvestmentType.reksadana;

  @override
  void dispose() {
    _label.dispose();
    _current.dispose();
    _cost.dispose();
    super.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Investasi baru',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Nama', hintText: 'mis. BBCA / Sucorinvest Sharia'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InvestmentType>(
              initialValue: _type,
              items: [
                for (final t in InvestmentType.values)
                  DropdownMenuItem(
                      value: t, child: Text(investmentTypeLabel(t))),
              ],
              onChanged: (v) => setState(() => _type = v ?? InvestmentType.reksadana),
              decoration: const InputDecoration(labelText: 'Jenis'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cost,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Modal (cost basis)', prefixText: 'Rp '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _current,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Nilai saat ini', prefixText: 'Rp '),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final label = _label.text.trim();
                final cv = int.tryParse(_current.text) ?? 0;
                final cb = int.tryParse(_cost.text) ?? 0;
                if (label.isEmpty || cv < 0 || cb < 0) return;
                Navigator.pop(context, _Draft(label, _type, cv, cb));
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
