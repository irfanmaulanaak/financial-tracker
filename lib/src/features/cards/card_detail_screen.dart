import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'credit_card.dart';
import 'card_repository.dart';
import 'edit_card_sheet.dart';

final _cardProvider =
    StreamProvider.family<CreditCard?, ({String hid, String cardId})>((ref, p) {
      return ref
          .watch(cardRepositoryProvider)
          .watchOne(hid: p.hid, cardId: p.cardId);
    });

final _installmentsProvider =
    StreamProvider.family<List<Installment>, ({String hid, String cardId})>((
      ref,
      p,
    ) {
      return ref
          .watch(cardRepositoryProvider)
          .watchInstallments(hid: p.hid, cardId: p.cardId);
    });

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cardAsync = ref.watch(
      _cardProvider((hid: household.id, cardId: cardId)),
    );
    final installmentsAsync = ref.watch(
      _installmentsProvider((hid: household.id, cardId: cardId)),
    );

    Future<void> editCard(CreditCard c) async {
      final result = await showModalBottomSheet<CardDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EditCardSheet(initial: c),
      );
      if (result == null) return;
      await ref
          .read(cardRepositoryProvider)
          .updateCard(
            hid: household.id,
            cardId: cardId,
            label: result.label,
            last4: result.last4,
            limit: result.limit,
            dueDay: result.dueDay,
            apr: result.apr,
            accent: result.accent,
            minPaymentPct: result.minPaymentPct,
          );
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: cardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (card) {
          if (card == null) {
            return const SafeArea(
              child: Column(
                children: [
                  FtSubHeader(title: 'Kartu'),
                  Expanded(
                    child: Center(child: Text('Kartu tidak ditemukan.')),
                  ),
                ],
              ),
            );
          }
          final minPay = minimumPayment(
            balance: card.used,
            minPaymentPct: card.minPaymentPct,
          );
          final available = (card.limit - card.used).clamp(0, card.limit);
          return SafeArea(
            child: FtAppChrome(
              current: FtTab.cards,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  FtSubHeader(
                    title: card.label,
                    trailing: IconButton.filledTonal(
                      tooltip: 'Edit',
                      onPressed: () => editCard(card),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ),
                  _Header(card: card, available: available),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: card.used == 0
                              ? null
                              : () => _confirm(
                                  context,
                                  'Bayar minimum (${Money.format(minPay)})?',
                                  () async {
                                    await ref
                                        .read(cardRepositoryProvider)
                                        .payMinimum(
                                          hid: household.id,
                                          cardId: cardId,
                                        );
                                  },
                                ),
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          label: Text('Min ${Money.format(minPay)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: card.used == 0
                              ? null
                              : () => _confirm(
                                  context,
                                  'Bayar lunas (${Money.format(card.used)})?',
                                  () async {
                                    await ref
                                        .read(cardRepositoryProvider)
                                        .payFull(
                                          hid: household.id,
                                          cardId: cardId,
                                        );
                                  },
                                ),
                          icon: const Icon(Icons.check),
                          label: Text('Lunasi ${Money.format(card.used)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const FtSectionHeader(title: 'Cicilan aktif'),
                  ...installmentsAsync.maybeWhen(
                    data: (items) => items.isEmpty
                        ? [
                            FtCard(
                              child: Center(
                                child: Text(
                                  'Belum ada cicilan.',
                                  style: TextStyle(color: FtColors.ink3),
                                ),
                              ),
                            ),
                          ]
                        : items
                              .map(
                                (i) => _InstallmentTile(
                                  inst: i,
                                  onPaidOne: () => ref
                                      .read(cardRepositoryProvider)
                                      .incrementInstallment(
                                        hid: household.id,
                                        cardId: cardId,
                                        installmentId: i.id,
                                      ),
                                ),
                              )
                              .toList(),
                    orElse: () => const [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await action();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.card, required this.available});
  final CreditCard card;
  final int available;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(card.accent);
    final pct = card.limit == 0
        ? 0.0
        : (card.used / card.limit).clamp(0.0, 1.0);
    return FtCard(
      backgroundColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              if (card.last4.isNotEmpty)
                Text(
                  '•••• ${card.last4}',
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Terpakai',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            Money.format(card.used),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tersedia: ${Money.format(available)} dari ${Money.format(card.limit)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jatuh tempo: tgl ${card.dueDay}  •  APR: ${(card.apr * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.inst, required this.onPaidOne});
  final Installment inst;
  final VoidCallback onPaidOne;

  @override
  Widget build(BuildContext context) {
    final pct = inst.monthsPaid / inst.monthsTotal;
    return FtCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    inst.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${inst.monthsPaid}/${inst.monthsTotal} bln',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: FtProgressBar(value: pct, max: 1, color: FtColors.sky),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cicilan: ${Money.format(inst.monthly)} / bln  •  Sisa: ${Money.format(inst.remainingAmount)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (!inst.isComplete)
                  TextButton(
                    onPressed: onPaidOne,
                    child: const Text('Tandai dibayar'),
                  )
                else
                  const Chip(
                    label: Text('Lunas'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
