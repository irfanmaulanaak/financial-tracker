import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import 'card_repository.dart';
import 'credit_card.dart';
import 'edit_card_sheet.dart';

final _cardInstallmentsProvider =
    StreamProvider.family<List<Installment>, ({String hid, String cardId})>(
  (ref, p) => ref
      .watch(cardRepositoryProvider)
      .watchInstallments(hid: p.hid, cardId: p.cardId),
);

final cardsProvider = StreamProvider.family<List<CreditCard>, String>((
  ref,
  hid,
) {
  return ref.watch(cardRepositoryProvider).watchAll(hid);
});

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cards = ref.watch(cardsProvider(household.id));
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: cards.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
          children: [
            FtShimmer(
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: FtColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < 2; i++) ...[
              FtShimmer(
                child: Container(
                  height: 160,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: FtColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (items) {
          final totalUsed = items.fold<int>(0, (a, b) => a + b.used);
          final totalLimit = items.fold<int>(0, (a, b) => a + b.limit);
          final totalMin = items.fold<int>(
            0,
            (a, b) =>
                a +
                minimumPayment(balance: b.used, minPaymentPct: b.minPaymentPct),
          );
          return FtAppChrome(
            current: FtTab.cards,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                FtSubHeader(
                  title: 'Utang & Kartu Kredit',
                  trailing: FtAddButton(
                    tooltip: 'Tambah kartu',
                    onTap: () => _openAddSheet(
                      context,
                      ref,
                      household.id,
                      household.members.first.userId,
                    ),
                  ),
                ),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Akumulasi Tagihan'),
                      const SizedBox(height: 6),
                      Text(
                        Money.format(totalUsed),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      FtProgressBar(
                        value: totalUsed,
                        max: totalLimit <= 0 ? 1 : totalLimit,
                        color: FtColors.plum,
                        height: 6,
                      ),
                      const SizedBox(height: 14),
                      FtStatGrid(
                        items: [
                          FtStatItem(
                            label: 'Limit total',
                            value: Money.format(totalLimit),
                          ),
                          FtStatItem(
                            label: 'Min. bayar',
                            value: Money.format(totalMin),
                            color: FtColors.plum,
                          ),
                          FtStatItem(
                            label: 'Kartu aktif',
                            value: '${items.length}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
                  child: Eyebrow('Kartu Aktif'),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Belum ada kartu.',
                        style: TextStyle(color: FtColors.ink3, fontSize: 13),
                      ),
                    ),
                  )
                else
                  for (final c in items)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                      child: _CardTile(
                        card: c,
                        hid: household.id,
                        ownerName: prettyName(
                            household.memberOf(c.ownerId)?.displayName ?? '-'),
                        onTap: () => context.push('/cards/${c.id}'),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    String hid,
    String defaultOwnerId,
  ) async {
    final result = await showModalBottomSheet<CardDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditCardSheet(defaultOwnerId: defaultOwnerId),
    );
    if (result == null) return;
    await ref
        .read(cardRepositoryProvider)
        .addCard(
          hid: hid,
          ownerId: result.ownerId,
          label: result.label,
          last4: result.last4,
          limit: result.limit,
          dueDay: result.dueDay,
          apr: result.apr,
          accent: result.accent,
          minPaymentPct: result.minPaymentPct,
        );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.hid,
    required this.ownerName,
    required this.onTap,
  });
  final CreditCard card;
  final String hid;
  final String ownerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(card.accent);
    final pct = card.limit == 0
        ? 0.0
        : (card.used / card.limit).clamp(0.0, 1.0);
    return FtCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 132),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, FtColors.plum],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.last4.isNotEmpty ? '•••• ${card.last4}' : '',
                  style: const TextStyle(color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        Money.format(card.used),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FtProgressBar(
                  value: pct,
                  max: 1,
                  color: Colors.white,
                  trackColor: Colors.white24,
                  height: 3,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FtStatGrid(
              items: [
                FtStatItem(label: 'Pemilik', value: ownerName),
                FtStatItem(label: 'Limit', value: Money.format(card.limit)),
                FtStatItem(label: 'Jatuh tempo', value: 'Tgl ${card.dueDay}'),
              ],
            ),
          ),
          _CardInstallmentsInline(
            hid: hid,
            cardId: card.id,
          ),
        ],
      ),
    );
  }
}

class _CardInstallmentsInline extends ConsumerWidget {
  const _CardInstallmentsInline({required this.hid, required this.cardId});
  final String hid;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_cardInstallmentsProvider((hid: hid, cardId: cardId)));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final active = items.where((i) => !i.isComplete).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        final totalMonthly = active.fold<int>(0, (a, i) => a + i.monthly);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_month, size: 14, color: FtColors.ink3),
                  const SizedBox(width: 6),
                  Text(
                    '${active.length} cicilan aktif · ${Money.format(totalMonthly)}/bln',
                    style: TextStyle(
                      color: FtColors.ink2,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final i in active.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.label.isNotEmpty ? i.label : 'Cicilan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: FtColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${i.monthsPaid}/${i.monthsTotal} bulan · ${Money.format(i.monthly)}/bln',
                              style: TextStyle(
                                color: FtColors.ink3,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: FtProgressBar(
                          value: i.monthsPaid,
                          max: i.monthsTotal,
                          color: FtColors.plum,
                          height: 4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
