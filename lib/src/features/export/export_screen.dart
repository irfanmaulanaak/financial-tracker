import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/csv_export.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
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
      // Resolve card labels for credit-flow rows.
      final cards =
          await ref.read(cardsProvider(household.id).future);
      final cardById = {for (final CreditCard c in cards) c.id: c};

      final rows = list.map((Expense e) {
        final cat = household.categoryOf(e.categoryId);
        final member = household.memberOf(e.spentBy);
        final source = _expenseSourceLabel(e, household, cardById);
        return (
          date: e.date,
          amount: e.amount,
          category: cat?.label ?? e.categoryId,
          source: source,
          spentBy: prettyName(member?.displayName ?? e.spentBy),
          note: e.note,
        );
      });

      final csv = expensesToCsv(rows);
      await _shareCsv(csv, 'pengeluaran_${_stamp()}.csv');
    } catch (e) {
      if (mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal ekspor pengeluaran');
      }
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
          source: dest?.label ?? i.destinationAccountId,
          spentBy: prettyName(member?.displayName ?? i.receivedBy),
          note: i.note,
        );
      });
      final csv = expensesToCsv(rows);
      await _shareCsv(csv, 'pemasukan_${_stamp()}.csv');
    } catch (e) {
      if (mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal ekspor pemasukan');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareCsv(String csv, String filename) async {
    // In-memory XFile keeps this cross-platform: share_plus writes a temp
    // file on Android/iOS internally, and uses a blob/download on web.
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, name: filename, mimeType: 'text/csv'),
        ],
        fileNameOverrides: [filename],
        text: filename,
      ),
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
      body: FtRefreshable(
        onRefresh: () async {
          ref.invalidate(currentHouseholdProvider);
          await ftRefreshDelay();
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
      ),
    );
  }

  String _short(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

/// Resolves an expense's "where the money came from" label for the CSV
/// export. Order: cash account → savings account → credit card → empty
/// (legacy rows recorded before sourceAccountId existed).
String _expenseSourceLabel(
  Expense e,
  Household household,
  Map<String, CreditCard> cardById,
) {
  if (e.sourceAccountId != null) {
    final acc = household.accountOf(e.sourceAccountId!);
    if (acc != null) return acc.label;
    return e.sourceAccountId!;
  }
  if (e.cardId != null) {
    final c = cardById[e.cardId];
    if (c != null) return c.label;
    return e.cardId!;
  }
  return '';
}

