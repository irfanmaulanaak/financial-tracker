import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/hide_assets_provider.dart';
import '../../../theme.dart';
import '../../../ui/ft_refresh.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household_providers.dart' show currentHouseholdProvider;
import '../../home/widgets/home_formatters.dart';
import '../../investments/investment.dart';
import '../../investments/investments_repository.dart';

class InvestasiList extends ConsumerWidget {
  const InvestasiList({
    super.key,
    required this.householdId,
    required this.items,
    required this.isLoading,
    required this.error,
    this.onAdd,
  });
  final String householdId;
  final List<Investment> items;
  final bool isLoading;
  final Object? error;
  final VoidCallback? onAdd;

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(currentHouseholdProvider);
    ref.invalidate(investmentsProvider(householdId));
    await ftRefreshDelay();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    if (isLoading) {
      return FtRefreshable(
        onRefresh: () => _onRefresh(ref),
        child: ListView(
        padding:
            const EdgeInsets.fromLTRB(22, 4, 22, kFtFabClearance),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
        ),
      );
    }
    if (error != null) {
      return Center(child: Text('Gagal: $error'));
    }
    final summary = summarisePortfolio(items);
    return FtRefreshable(
      onRefresh: () => _onRefresh(ref),
      child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, kFtFabClearance),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        InvestasiSummary(summary: summary, hidden: hidden),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'Belum ada investasi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FtColors.ink3),
              ),
            ),
          )
        else
          for (final i in items)
            InvestmentTile(
              inv: i,
              hidden: hidden,
              onUpdate: () => _openUpdate(context, ref, i),
              onDelete: () => _confirmDelete(context, ref, i),
            ),
        if (onAdd != null) ...[
          const SizedBox(height: 12),
          FtDashedAdd(label: 'Tambah posisi investasi', onTap: onAdd!),
        ],
      ],
      ),
    );
  }

  Future<void> _openUpdate(
      BuildContext context, WidgetRef ref, Investment i) async {
    final v = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UpdateInvestmentValueSheet(investment: i),
    );
    if (v != null) {
      try {
        await ref
            .read(investmentsRepositoryProvider)
            .updateValue(hid: householdId, id: i.id, currentValue: v);
      } catch (e) {
        if (context.mounted) {
          showFtErrorSnack(context, e, prefix: 'Gagal memperbarui investasi');
        }
      }
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
      try {
        await ref
            .read(investmentsRepositoryProvider)
            .delete(hid: householdId, id: i.id);
      } catch (e) {
        if (context.mounted) {
          showFtErrorSnack(context, e, prefix: 'Gagal menghapus investasi');
        }
      }
    }
  }
}

class InvestasiSummary extends StatelessWidget {
  const InvestasiSummary({
    super.key,
    required this.summary,
    this.hidden = false,
  });
  final PortfolioSummary summary;
  final bool hidden;

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
            hidden ? maskMoney() : Money.format(summary.totalValue),
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
                hidden
                    ? '${maskMoney()} (${(summary.gainPct * 100).toStringAsFixed(1)}%)'
                    : '${positive ? '+' : ''}${Money.format(summary.totalGain)} (${(summary.gainPct * 100).toStringAsFixed(1)}%)',
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
    super.key,
    required this.inv,
    required this.onUpdate,
    required this.onDelete,
    this.hidden = false,
  });
  final Investment inv;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final bool hidden;

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
                  hidden
                      ? '${investmentTypeLabel(inv.type)} • cost ${maskMoney()}'
                      : '${investmentTypeLabel(inv.type)} • cost ${Money.format(inv.costBasis)}',
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
                hidden ? maskMoney() : Money.format(inv.currentValue),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Modal (cost basis)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _current,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Nilai saat ini',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final label = _label.text.trim();
                final cv = Money.parse(_current.text) ?? 0;
                final cb = Money.parse(_cost.text) ?? 0;
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

/// Stateful update sheet for "Nilai sekarang". A stateless `Padding` here
/// would capture `MediaQuery.viewInsets.bottom` once and leave the input
/// trapped under the keyboard — instead this widget re-reads viewInsets on
/// every build so the bottom padding tracks the keyboard.
class UpdateInvestmentValueSheet extends StatefulWidget {
  const UpdateInvestmentValueSheet({super.key, required this.investment});
  final Investment investment;

  @override
  State<UpdateInvestmentValueSheet> createState() =>
      _UpdateInvestmentValueSheetState();
}

class _UpdateInvestmentValueSheetState
    extends State<UpdateInvestmentValueSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: Money.displayDigits(widget.investment.currentValue),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = Money.parse(_ctrl.text);
    if (v == null) return;
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: viewInsets + 16,
      ),
      child: SingleChildScrollView(
        reverse: true,
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update ${widget.investment.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Nilai sekarang',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
