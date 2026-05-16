import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/csv_export.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_repository.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../incomes/income_repository.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});
  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _busy = false;

  Future<void> _exportExpenses(Household household) async {
    setState(() => _busy = true);
    try {
      // Last 90 days for the export window — internal app, small data.
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 3, now.day);
      final repo = ref.read(expenseRepositoryProvider);
      final list = await repo
          .watchInRange(
            householdId: household.id,
            startInclusive: start,
            endExclusive: now.add(const Duration(days: 1)),
          )
          .first;

      final rows = list.map((Expense e) {
        final cat = household.categoryOf(e.categoryId);
        final pm = household.paymentMethodOf(e.paymentMethodId);
        final member = household.memberOf(e.spentBy);
        return (
          date: e.date,
          amount: e.amount,
          category: cat?.label ?? e.categoryId,
          paymentMethod: pm?.label ?? e.paymentMethodId,
          spentBy: prettyName(member?.displayName ?? e.spentBy),
          note: e.note,
        );
      });

      final csv = expensesToCsv(rows);
      await _shareCsv(csv, 'pengeluaran_${_stamp()}.csv');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportIncomes(Household household) async {
    setState(() => _busy = true);
    try {
      final list = await ref
          .read(incomeRepositoryProvider)
          .watchRecent(hid: household.id, limit: 500)
          .first;
      final rows = list.map((i) {
        final dest = household.accountOf(i.destinationAccountId);
        final member = household.memberOf(i.receivedBy);
        return (
          date: i.date,
          amount: i.amount,
          category: i.source.name,
          paymentMethod: dest?.label ?? i.destinationAccountId,
          spentBy: prettyName(member?.displayName ?? i.receivedBy),
          note: i.note,
        );
      });
      final csv = expensesToCsv(rows);
      await _shareCsv(csv, 'pemasukan_${_stamp()}.csv');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareCsv(String csv, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: filename),
    );
  }

  String _stamp() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final start = DateTime.now().subtract(const Duration(days: 90));
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const FtSubHeader(title: 'Ekspor data'),
            FtCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Format'),
                  const SizedBox(height: 6),
                  Text('CSV', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    'Pengeluaran: 90 hari terakhir (sejak ${_short(start)}).\nPemasukan: 500 catatan terbaru.\nSiklus aktif: ${_short(cycle.start)} – ${_short(cycle.endExclusive.subtract(const Duration(days: 1)))}.',
                    style: const TextStyle(color: FtColors.ink3, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : () => _exportExpenses(household),
              icon: const Icon(Icons.download),
              label: const Text('Ekspor pengeluaran (CSV)'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _exportIncomes(household),
              icon: const Icon(Icons.download),
              label: const Text('Ekspor pemasukan (CSV)'),
            ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  String _short(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
