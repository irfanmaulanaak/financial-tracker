import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cicilan.dart';
import '../../../core/formatters.dart';
import '../../../core/health_score.dart';
import '../../../core/hide_assets_provider.dart';
import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_sparkline.dart';
import '../../../ui/ft_ui.dart';
import '../../cards/credit_card.dart';
import 'home_formatters.dart';

class HomeOverview extends ConsumerStatefulWidget {
  const HomeOverview({
    super.key,
    required this.nw,
    required this.trend,
    this.trendDates = const [],
    required this.cycleNet,
    required this.spend,
    required this.gajiIncome,
    required this.cards,
    required this.health,
    required this.safe,
  });

  final NetWorth nw;
  final List<double> trend;
  final List<DateTime> trendDates;
  final int cycleNet;
  final int spend;
  final int gajiIncome;
  final List<CreditCard> cards;
  final HealthScore health;
  final ({
    int perDay,
    int remaining,
    int daysLeft,
    DateTime nextPayday,
    bool hasBudget,
  })
  safe;

  @override
  ConsumerState<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends ConsumerState<HomeOverview> {
  int? _trendIndex;

  @override
  Widget build(BuildContext context) {
    final hidden = ref.watch(hideAssetsProvider);
    final cardUsed = widget.cards.fold<int>(0, (sum, card) => sum + card.used);
    final cardMinimum = widget.cards.fold<int>(
      0,
      (sum, card) =>
          sum +
          minimumPayment(balance: card.used, minPaymentPct: card.minPaymentPct),
    );
    final incomeRatio = widget.gajiIncome <= 0
        ? null
        : (widget.spend / widget.gajiIncome * 100).round();
    final canScrub =
        !hidden &&
        widget.trend.length == widget.trendDates.length &&
        widget.trend.isNotEmpty;
    final selectedTrend =
        canScrub && _trendIndex != null && _trendIndex! < widget.trend.length
        ? '${Dates.dayMonth(widget.trendDates[_trendIndex!])} · '
              '${Money.format(widget.trend[_trendIndex!].round())}'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DailyLimitPanel(safe: widget.safe),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Ringkasan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: FtColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Siklus berjalan',
                style: TextStyle(color: FtColors.ink3, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: FtColors.surface,
              border: Border.all(color: FtColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _OverviewRow(
                  key: const Key('overview-net-worth'),
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Kekayaan bersih',
                  value: hidden ? maskMoney() : compactMoney(widget.nw.total),
                  detail: selectedTrend ?? _netWorthDetail(hidden),
                  onTap: () => context.push('/accounts'),
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.trend.length >= 2)
                        SizedBox(
                          width: 88,
                          child: FtSparkline(
                            data: widget.trend,
                            height: 28,
                            color: widget.cycleNet >= 0
                                ? FtColors.moss
                                : FtColors.danger,
                            onHoverPoint: canScrub
                                ? (index) => setState(() => _trendIndex = index)
                                : null,
                          ),
                        ),
                      const SizedBox(width: 4),
                      const HideAssetsEye(size: 17),
                    ],
                  ),
                ),
                const _LedgerDivider(),
                _OverviewRow(
                  icon: Icons.south_east_rounded,
                  iconColor: FtColors.danger,
                  label: 'Pengeluaran',
                  value: compactMoney(widget.spend),
                  detail: incomeRatio == null
                      ? 'Belum ada gaji tercatat'
                      : '$incomeRatio% dari gaji ${compactMoney(widget.gajiIncome)}',
                  onTap: () => context.push('/spend'),
                ),
                const _LedgerDivider(),
                _OverviewRow(
                  icon: Icons.credit_card_outlined,
                  iconColor: FtColors.plum,
                  label: 'Kartu kredit',
                  value: widget.cards.isEmpty
                      ? 'Belum ada'
                      : compactMoney(cardUsed),
                  detail: widget.cards.isEmpty
                      ? 'Tambah kartu untuk pantau tagihan'
                      : '${widget.cards.length} kartu · minimum ${compactMoney(cardMinimum)}',
                  onTap: () => context.push('/cards'),
                ),
                const _LedgerDivider(),
                _OverviewRow(
                  icon: Icons.monitor_heart_outlined,
                  iconColor: _healthColor(widget.health.score),
                  label: 'Kesehatan finansial',
                  value: '${widget.health.score}/100',
                  detail: widget.health.verdict,
                  onTap: () => context.push('/health'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _netWorthDetail(bool hidden) {
    if (hidden) return 'Nilai disembunyikan';
    if (widget.cycleNet == 0) return 'Tunai + tabungan + investasi − utang';
    final sign = widget.cycleNet > 0 ? '+' : '−';
    return '$sign${compactMoney(widget.cycleNet.abs())} siklus ini';
  }
}

class _DailyLimitPanel extends StatelessWidget {
  const _DailyLimitPanel({required this.safe});

  final ({
    int perDay,
    int remaining,
    int daysLeft,
    DateTime nextPayday,
    bool hasBudget,
  })
  safe;

  @override
  Widget build(BuildContext context) {
    final over = safe.hasBudget && safe.remaining <= 0;
    final statusColor = over ? FtColors.danger : FtColors.healthOk;
    final status = !safe.hasBudget
        ? null
        : over
        ? 'Di atas budget'
        : 'Dalam batas';
    final title = !safe.hasBudget
        ? 'Atur budget untuk melihat batas harian'
        : over
        ? Money.format(0)
        : '${Money.format(safe.perDay)}/hari';
    final detail = !safe.hasBudget
        ? 'Mulai dari budget kategori.'
        : over
        ? 'Anggaran terlewati ${Money.compact(-safe.remaining)} · '
              'gajian ${Dates.dayMonth(safe.nextPayday)}'
        : 'Sisa ${Money.compact(safe.remaining)} ÷ ${safe.daysLeft} hari · '
              'gajian ${Dates.dayMonth(safe.nextPayday)}';

    return Semantics(
      button: true,
      label: 'Batas belanja hari ini',
      child: FtTapScale(
        scale: 0.985,
        onTap: () => context.push('/spend'),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Batas belanja hari ini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FtColors.ink3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: over ? FtColors.danger : FtColors.ink,
                              fontSize: safe.hasBudget ? 38 : 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: safe.hasBudget ? -1.2 : -0.4,
                              height: 1.05,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: FtColors.ink3,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink3,
                    fontSize: 11.5,
                    height: 1.35,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    required this.detail,
    required this.onTap,
    this.action,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final String detail;
  final VoidCallback onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.992,
      haptic: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: iconColor ?? FtColors.clay),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: FtColors.ink3, fontSize: 11.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 10.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (action case final action?)
              action
            else ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: FtColors.ink4, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _LedgerDivider extends StatelessWidget {
  const _LedgerDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(height: 1, color: FtColors.line),
    );
  }
}

Color _healthColor(int score) {
  if (score >= 65) return FtColors.healthOk;
  if (score >= 50) return FtColors.healthWarn;
  return FtColors.healthBad;
}
