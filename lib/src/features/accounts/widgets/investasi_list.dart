import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../investments/investment.dart';
import '../../investments/investments_repository.dart';

class InvestasiList extends ConsumerWidget {
  const InvestasiList({
    required this.householdId,
    required this.items,
    required this.isLoading,
    required this.error,
  });
  final String householdId;
  final List<Investment> items;
  final bool isLoading;
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
        children: [
          FtShimmer(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 3; i++) ...[
            FtShimmer(
              child: Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: FtColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      );
    }
    if (error != null) {
      return Center(child: Text('Gagal: $error'));
    }
    final summary = summarisePortfolio(items);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
      children: [
        InvestasiSummary(summary: summary),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'Belum ada investasi.\nTambah posisi via tombol "+".',
                textAlign: TextAlign.center,
                style: TextStyle(color: FtColors.ink3),
              ),
            ),
          )
        else
          for (final i in items)
            InvestmentTile(
              inv: i,
              onUpdate: () => _openUpdate(context, ref, i),
              onDelete: () => _confirmDelete(context, ref, i),
            ),
      ],
    );
  }

  Future<void> _openUpdate(
      BuildContext context, WidgetRef ref, Investment i) async {
    final ctrl = TextEditingController(text: i.currentValue.toString());
    final v = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
                labelText: 'Nilai sekarang',
                prefixText: 'Rp ',
              ),
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
          .updateValue(hid: householdId, id: i.id, currentValue: v);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Investment i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus "${i.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(investmentsRepositoryProvider)
          .delete(hid: householdId, id: i.id);
    }
  }
}

class InvestasiSummary extends StatelessWidget {
  const InvestasiSummary({required this.summary});
  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final positive = summary.totalGain >= 0;
    final color = positive ? FtColors.sage : FtColors.danger;
    return FtCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Total portofolio'),
          const SizedBox(height: 6),
          Text(
            Money.format(summary.totalValue),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${positive ? '+' : ''}${Money.format(summary.totalGain)} (${(summary.gainPct * 100).toStringAsFixed(1)}%)',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Text(
                '${summary.distinctTypes} jenis aset',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InvestmentTile extends StatelessWidget {
  const InvestmentTile({
    required this.inv,
    required this.onUpdate,
    required this.onDelete,
  });
  final Investment inv;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final positive = inv.gain >= 0;
    final color = positive ? FtColors.sage : FtColors.danger;
    return FtCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onUpdate,
      onLongPress: onDelete,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FtColors.clay.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: FtColors.clay.withValues(alpha: 0.24), width: 0.5),
            ),
            child: Icon(
              _investmentIcon(inv.type),
              color: FtColors.clay,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${investmentTypeLabel(inv.type)} • cost ${Money.format(inv.costBasis)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.format(inv.currentValue),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${positive ? '+' : ''}${(inv.gainPct * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InvestmentDraft {
  final String label;
  final InvestmentType type;
  final int currentValue;
  final int costBasis;
  const InvestmentDraft(this.label, this.type, this.currentValue, this.costBasis);
}

class InvestmentEditSheet extends StatefulWidget {
  const InvestmentEditSheet({super.key});
  @override
  State<InvestmentEditSheet> createState() => _InvestmentEditSheetState();
}

class _InvestmentEditSheetState extends State<InvestmentEditSheet> {
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
                labelText: 'Nama',
                hintText: 'mis. BBCA / Sucorinvest Sharia',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InvestmentType>(
              initialValue: _type,
              items: [
                for (final t in InvestmentType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(investmentTypeLabel(t)),
                  ),
              ],
              onChanged: (v) =>
                  setState(() => _type = v ?? InvestmentType.reksadana),
              decoration: const InputDecoration(labelText: 'Jenis'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cost,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Modal (cost basis)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _current,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nilai saat ini',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final label = _label.text.trim();
                final cv = int.tryParse(_current.text) ?? 0;
                final cb = int.tryParse(_cost.text) ?? 0;
                if (label.isEmpty || cv < 0 || cb < 0) return;
                Navigator.pop(
                    context, InvestmentDraft(label, _type, cv, cb));
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _investmentIcon(InvestmentType t) => switch (t) {
      InvestmentType.saham => Icons.trending_up_rounded,
      InvestmentType.reksadana => Icons.bar_chart_rounded,
      InvestmentType.deposito => Icons.lock_clock_rounded,
      InvestmentType.emas => Icons.workspace_premium_rounded,
      InvestmentType.crypto => Icons.currency_bitcoin_rounded,
      InvestmentType.lainnya => Icons.account_balance_rounded,
    };
