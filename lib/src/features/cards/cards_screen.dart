import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../incomes/income_providers.dart';
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
          final income = ref.watch(currentCycleIncomeTotalProvider);
          // Beban utang ratio — if monthly cards debt > 40% of income, warn.
          final debtRatio = income > 0 ? totalUsed / income : 0.0;
          final debtState = debtRatio > 0.4
              ? FtColors.danger
              : debtRatio > 0.25
                  ? FtColors.ochre
                  : FtColors.healthOk;
          return FtAppChrome(
            current: FtTab.cards,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const FtSubHeader(title: 'Utang & Kartu Kredit'),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _LabeledStat(
                              label: 'Min. bayar',
                              value: compactMoney(totalMin),
                              color: FtColors.plum,
                            ),
                          ),
                          Expanded(
                            child: _CicilanTotalStat(
                              hid: household.id,
                              cards: items,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Beban utang',
                                  style: TextStyle(
                                    color: FtColors.ink3,
                                    fontSize: 10,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: debtState,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
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
                FtDashedAdd(
                  margin: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                  label: 'Tambah kartu kredit',
                  onTap: () => _openAddSheet(
                    context,
                    ref,
                    household.id,
                    household.members.first.userId,
                  ),
                ),
                if (items.isNotEmpty)
                  _SaranTip(
                    hid: household.id,
                    cards: items,
                    income: income,
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
          _CardActions(hid: hid, card: card),
        ],
      ),
    );
  }
}

class _CardActions extends ConsumerWidget {
  const _CardActions({required this.hid, required this.card});
  final String hid;
  final CreditCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (card.used <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: FtTapScale(
              scale: 0.97,
              onTap: () => _confirm(
                context,
                ref,
                full: false,
                amount: minimumPayment(
                  balance: card.used,
                  minPaymentPct: card.minPaymentPct,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: FtColors.surfaceAlt,
                  border: Border.all(color: FtColors.line, width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Bayar minimum',
                  style: TextStyle(
                    color: FtColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FtTapScale(
              scale: 0.97,
              onTap: () => _confirm(
                context,
                ref,
                full: true,
                amount: card.used,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: FtColors.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Bayar penuh',
                  style: TextStyle(
                    color: FtColors.bg,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required bool full,
    required int amount,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(full ? 'Bayar penuh?' : 'Bayar minimum?'),
        content: Text(
          'Catat pembayaran ${Money.format(amount)} untuk ${card.label}? Saldo kartu akan berkurang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    FtHaptics.success();
    final repo = ref.read(cardRepositoryProvider);
    if (full) {
      await repo.payFull(hid: hid, cardId: card.id);
    } else {
      await repo.payMinimum(hid: hid, cardId: card.id);
    }
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

class _LabeledStat extends StatelessWidget {
  const _LabeledStat({
    required this.label,
    required this.value,
    this.color,
  });
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: FtColors.ink3,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? FtColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Sums monthly cicilan across every card by watching each card's installments
/// stream. Renders `—` while no data has loaded yet.
class _CicilanTotalStat extends ConsumerWidget {
  const _CicilanTotalStat({required this.hid, required this.cards});
  final String hid;
  final List<CreditCard> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var total = 0;
    for (final c in cards) {
      final list = ref
              .watch(_cardInstallmentsProvider((hid: hid, cardId: c.id)))
              .value ??
          const [];
      for (final i in list) {
        if (!i.isComplete) total += i.monthly;
      }
    }
    return _LabeledStat(
      label: 'Cicilan/bln',
      value: total > 0 ? compactMoney(total) : '—',
    );
  }
}

/// "Saran" tip card at the bottom of the cards list — calls out high
/// debt-service ratios and suggests action.
class _SaranTip extends ConsumerWidget {
  const _SaranTip({
    required this.hid,
    required this.cards,
    required this.income,
  });
  final String hid;
  final List<CreditCard> cards;
  final int income;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var monthlyInstallments = 0;
    for (final c in cards) {
      final list = ref
              .watch(_cardInstallmentsProvider((hid: hid, cardId: c.id)))
              .value ??
          const [];
      for (final i in list) {
        if (!i.isComplete) monthlyInstallments += i.monthly;
      }
    }
    if (income <= 0) return const SizedBox.shrink();
    final ratio = monthlyInstallments / income;
    final overweight = ratio > 0.3;
    final pct = (ratio * 100).round();
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
      backgroundColor: FtColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: FtColors.clay),
              const SizedBox(width: 6),
              const Eyebrow('Saran'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            overweight
                ? 'Total cicilan ${compactMoney(monthlyInstallments)} ($pct% dari pendapatan). Idealnya di bawah 30% — pertimbangkan menyelesaikan cicilan lebih awal.'
                : monthlyInstallments == 0
                    ? 'Saat ini belum ada cicilan aktif. Pastikan rasio pembayaran tetap di bawah 30% dari pendapatan.'
                    : 'Cicilan ${compactMoney(monthlyInstallments)} ($pct% dari pendapatan) — masih dalam batas sehat.',
            style: TextStyle(
              fontFamily: 'Newsreader',
              color: FtColors.ink,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
