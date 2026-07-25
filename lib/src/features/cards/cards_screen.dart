import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../incomes/income_providers.dart';
import 'card_repository.dart';
import 'credit_card.dart';
import 'edit_card_sheet.dart';
import 'widgets/card_tile.dart';
import 'widgets/installment_list.dart';

final cardsProvider = StreamProvider.family<List<CreditCard>, String>((
  ref,
  hid,
) {
  return ref.watch(cardRepositoryProvider).watchAll(hid);
});

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  /// Tracks which (household, card) pairs have already been recalc'd this
  /// session so we don't loop on every stream emit. Cleared when the
  /// household changes.
  final _autoSynced = <String>{};
  bool _recalcAllRunning = false;

  void _autoSyncIfNeeded(String hid, List<CreditCard> cards) {
    final repo = ref.read(cardRepositoryProvider);
    for (final c in cards) {
      final key = '$hid/${c.id}';
      if (_autoSynced.contains(key)) continue;
      _autoSynced.add(key);
      // Fire-and-forget. recalcUsed is idempotent; a failure here only
      // means `used` stays stale until the user taps "Hitung ulang".
      unawaited(repo.recalcUsed(hid: hid, cardId: c.id));
    }
  }

  Future<void> _recalcAll(String hid, List<CreditCard> cards) async {
    if (_recalcAllRunning || cards.isEmpty) return;
    setState(() => _recalcAllRunning = true);
    final repo = ref.read(cardRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final c in cards) {
        await repo.recalcUsed(hid: hid, cardId: c.id);
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Hitung ulang ${cards.length} kartu selesai')),
      );
    } catch (e) {
      if (!mounted) return;
      showFtErrorSnack(context, e, prefix: 'Gagal hitung ulang semua');
    } finally {
      if (mounted) setState(() => _recalcAllRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 4, tileHeight: 96),
      );
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
          // Heal monthsBilled rollovers without user action — first emit
          // per (hid, cardId) triggers a one-shot recalcUsed.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _autoSyncIfNeeded(household.id, items);
          });
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
            child: FtRefreshable(
              onRefresh: () async {
                ref.invalidate(currentHouseholdProvider);
                ref.invalidate(cardsProvider(household.id));
                await ftRefreshDelay();
              },
              child: ListView(
              padding: const EdgeInsets.only(bottom: kFtFabClearance),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                FtSubHeader(
                  title: 'Utang & Kartu Kredit',
                  trailing: IconButton(
                    tooltip: 'Hitung ulang semua kartu',
                    icon: _recalcAllRunning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    onPressed: items.isEmpty || _recalcAllRunning
                        ? null
                        : () => _recalcAll(household.id, items),
                  ),
                ),
                FtCard(
                  heroTag: 'ft-kartu-hero',
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
                        color: ftProgressColor(
                          totalUsed,
                          totalLimit,
                          dangerWhenOver: true,
                        ),
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
                              color: FtColors.clay,
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
                  for (var i = 0; i < items.length; i++)
                    FtListReveal(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                        child: CardTile(
                          card: items[i],
                          hid: household.id,
                          ownerName: prettyName(
                              household.memberOf(items[i].ownerId)?.displayName ?? '-'),
                          onTap: () => context.push('/cards/${items[i].id}'),
                        ),
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
    try {
      await ref
          .read(cardRepositoryProvider)
          .addCard(
            hid: hid,
            ownerId: result.ownerId,
            label: result.label,
            last4: result.last4,
            limit: result.limit,
            dueDay: result.dueDay,
            billingDay: result.billingDay,
            apr: result.apr,
            accent: result.accent,
            minPaymentPct: result.minPaymentPct,
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menambah kartu');
      }
    }
  }
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
              .watch(cardInstallmentsProvider((hid: hid, cardId: c.id)))
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
              .watch(cardInstallmentsProvider((hid: hid, cardId: c.id)))
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
                ? 'Total cicilan ${compactMoney(monthlyInstallments)} ($pct% dari pendapatan). Idealnya di bawah 30%. Pertimbangkan menyelesaikan cicilan lebih awal.'
                : monthlyInstallments == 0
                    ? 'Saat ini belum ada cicilan aktif. Pastikan rasio pembayaran tetap di bawah 30% dari pendapatan.'
                    : 'Cicilan ${compactMoney(monthlyInstallments)} ($pct% dari pendapatan), masih dalam batas sehat.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontFeatures: const [FontFeature.tabularFigures()],
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
