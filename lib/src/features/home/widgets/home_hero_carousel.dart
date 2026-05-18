import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cicilan.dart';
import '../../../core/health_score.dart';
import '../../../core/hide_assets_provider.dart';
import '../../../core/in_app_indicators.dart';
import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_donut.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_sparkline.dart';
import '../../../ui/ft_ui.dart';
import '../../cards/credit_card.dart';
import 'home_formatters.dart';

/// 4-page swipeable hero card on the home screen:
///   1. Total Aset (net worth + breakdown)
///   2. Pengeluaran vs Gaji (ring chart, this cycle)
///   3. Kartu Kredit (akumulasi tagihan)
///   4. Kesehatan finansial
///
/// Each page is a self-contained card body wrapped in [FtCard] with a
/// `onTap` that routes to the full feature screen. Below the PageView sits
/// a row of dot indicators tracking the active page.
class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    super.key,
    required this.nw,
    required this.trend,
    required this.cycleNet,
    required this.spend,
    required this.gajiIncome,
    required this.cards,
    required this.health,
  });

  final NetWorth nw;
  final List<double> trend;

  /// Income (Gaji only) minus spend, this cycle. Used by the asset slide
  /// to render the small delta pill.
  final int cycleNet;

  /// Total expenses in the current cycle.
  final int spend;

  /// Sum of `IncomeSource.salary` rows for the current cycle. Drives the
  /// ratio ring on page 2.
  final int gajiIncome;

  final List<CreditCard> cards;
  final HealthScore health;

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) {
                FtHaptics.select();
                setState(() => _page = i);
              },
              children: [
                _AsetSlide(
                  nw: widget.nw,
                  trend: widget.trend,
                  cycleNet: widget.cycleNet,
                ),
                _RatioSlide(
                  spend: widget.spend,
                  gajiIncome: widget.gajiIncome,
                ),
                _KartuSlide(cards: widget.cards),
                _KesehatanSlide(score: widget.health),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Dots(count: 4, active: _page),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? FtColors.ink : FtColors.lineStrong,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Slide 1 — Total Aset
/// ---------------------------------------------------------------------------
class _AsetSlide extends ConsumerWidget {
  const _AsetSlide({
    required this.nw,
    required this.trend,
    required this.cycleNet,
  });

  final NetWorth nw;
  final List<double> trend;
  final int cycleNet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    final showDelta = !hidden && cycleNet != 0 && nw.total > 0;
    final positive = cycleNet >= 0;
    final segments = <FtDonutSegment>[
      if (nw.cash > 0)
        FtDonutSegment(value: nw.cash.toDouble(), color: FtColors.sky),
      if (nw.savings > 0)
        FtDonutSegment(value: nw.savings.toDouble(), color: FtColors.moss),
      if (nw.investments > 0)
        FtDonutSegment(value: nw.investments.toDouble(), color: FtColors.clay),
    ];
    return FtCard(
      onTap: () => context.push('/accounts'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: Eyebrow('Total Aset')),
              HideAssetsEye(),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hidden ? maskMoney() : compactMoney(nw.total),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            height: 1,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w500,
                            color: FtColors.ink,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (showDelta)
                      _DeltaPill(positive: positive, amount: cycleNet.abs())
                    else
                      Text(
                        'Tunai + tabungan + investasi',
                        style: TextStyle(color: FtColors.ink3, fontSize: 11),
                      ),
                    if (trend.length >= 2) ...[
                      const SizedBox(height: 10),
                      FtSparkline(
                        data: trend,
                        height: 22,
                        color: positive ? FtColors.moss : FtColors.danger,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (segments.isNotEmpty)
                FtDonut(segments: segments, size: 72, thickness: 9),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: FtColors.line),
          const SizedBox(height: 10),
          Row(
            children: [
              _BreakdownStat(
                label: 'Tunai',
                value: nw.cash,
                color: FtColors.sky,
                hidden: hidden,
              ),
              const SizedBox(width: 8),
              _BreakdownStat(
                label: 'Tabungan',
                value: nw.savings,
                color: FtColors.moss,
                hidden: hidden,
              ),
              const SizedBox(width: 8),
              _BreakdownStat(
                label: 'Investasi',
                value: nw.investments,
                color: FtColors.clay,
                hidden: hidden,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  const _BreakdownStat({
    required this.label,
    required this.value,
    required this.color,
    this.hidden = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink3,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            hidden ? maskMoney() : compactMoney(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.positive, required this.amount});
  final bool positive;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final color = positive ? FtColors.moss : FtColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '${positive ? '+' : '−'}${compactMoney(amount)} siklus ini',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Slide 2 — Pengeluaran vs Gaji
/// ---------------------------------------------------------------------------
class _RatioSlide extends StatelessWidget {
  const _RatioSlide({required this.spend, required this.gajiIncome});

  final int spend;
  final int gajiIncome;

  @override
  Widget build(BuildContext context) {
    final hasGaji = gajiIncome > 0;
    final spendShare = !hasGaji
        ? (spend > 0 ? 1.0 : 0.0)
        : (spend / gajiIncome).clamp(0.0, 1.0);
    final overBudget = hasGaji && spend > gajiIncome;
    final pct = hasGaji ? (spend / gajiIncome * 100).round() : 0;

    return FtCard(
      onTap: () => context.push('/incomes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: Eyebrow('Rasio Pengeluaran · Gaji')),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 116,
                  height: 116,
                  child: CustomPaint(
                    painter: _RatioRingPainter(
                      spendShare: spendShare,
                      overBudget: overBudget,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasGaji ? '$pct%' : '–',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: overBudget
                                  ? FtColors.danger
                                  : FtColors.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            hasGaji ? 'Gaji terpakai' : 'belum ada gaji',
                            style: TextStyle(
                              color: FtColors.ink3,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Legend(
                        color: FtColors.danger,
                        label: 'Pengeluaran',
                        value: compactMoney(spend),
                      ),
                      const SizedBox(height: 10),
                      _Legend(
                        color: FtColors.moss,
                        label: 'Gaji',
                        value: hasGaji ? compactMoney(gajiIncome) : 'Catat gaji',
                      ),
                      if (!hasGaji) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk catat gaji pertama.',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                      if (overBudget) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Melampaui gaji siklus ini.',
                          style: TextStyle(
                            color: FtColors.danger,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Two-arc ring: red arc for expense share, green arc fills the remainder.
/// When [overBudget] is true the red arc covers the full circle (the green
/// disappears).
class _RatioRingPainter extends CustomPainter {
  _RatioRingPainter({required this.spendShare, required this.overBudget});

  final double spendShare;
  final bool overBudget;
  static const double _thickness = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _thickness) / 2,
    );

    final track = Paint()
      ..color = FtColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (overBudget) {
      final red = Paint()
        ..color = FtColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, red);
      return;
    }

    // Green underlay for the full circle (income capacity).
    final green = Paint()
      ..color = FtColors.moss
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, green);

    if (spendShare > 0) {
      final red = Paint()
        ..color = FtColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * spendShare,
        false,
        red,
      );
    }
  }

  @override
  bool shouldRepaint(_RatioRingPainter old) =>
      old.spendShare != spendShare || old.overBudget != overBudget;
}

/// ---------------------------------------------------------------------------
/// Slide 3 — Kartu Kredit
/// ---------------------------------------------------------------------------
class _KartuSlide extends StatelessWidget {
  const _KartuSlide({required this.cards});

  final List<CreditCard> cards;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final used = cards.fold<int>(0, (a, b) => a + b.used);
    final minPay = cards.fold<int>(
      0,
      (a, b) =>
          a + minimumPayment(balance: b.used, minPaymentPct: b.minPaymentPct),
    );

    CreditCard? soonest;
    int? soonestDays;
    for (final c in cards) {
      if (c.used <= 0) continue;
      final d = daysUntilDue(dueDay: c.dueDay, now: now, warnWithinDays: 365)
          ?? 30;
      if (soonestDays == null || d < soonestDays) {
        soonestDays = d;
        soonest = c;
      }
    }

    return FtCard(
      onTap: () => context.push('/cards'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Eyebrow('Kartu Kredit · Utang')),
              if (minPay > 0)
                _Chip(
                  text: '${compactMoney(minPay)} min',
                  color: FtColors.plum,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada kartu kredit.\nTap untuk menambah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FtColors.ink3, fontSize: 12),
                ),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  compactMoney(used),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        height: 1.1,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  'akumulasi tagihan',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SegmentedLimitBar(cards: cards),
            const SizedBox(height: 12),
            Container(height: 0.5, color: FtColors.line),
            const SizedBox(height: 10),
            Row(
              children: [
                if (soonest != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jatuh tempo terdekat',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 10,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dueLabel(soonest.dueDay, soonestDays ?? 0,
                              soonest.label),
                          style: TextStyle(
                            color: FtColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kartu aktif',
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cards.length}',
                      style: TextStyle(
                        color: FtColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _dueLabel(int dueDay, int days, String cardLabel) {
    final shortName = cardLabel.split(' ').first;
    if (days <= 0) return 'Tgl $dueDay · $shortName (lewat)';
    if (days <= 14) return 'Tgl $dueDay · $shortName ($days hr)';
    return 'Tgl $dueDay · $shortName';
  }
}

class _SegmentedLimitBar extends StatelessWidget {
  const _SegmentedLimitBar({required this.cards});
  final List<CreditCard> cards;

  @override
  Widget build(BuildContext context) {
    final totalLimit = cards.fold<int>(0, (a, b) => a + b.limit);
    if (totalLimit <= 0) {
      return FtProgressBar(value: 0, max: 1, color: FtColors.plum);
    }
    return SizedBox(
      height: 6,
      child: Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(
              flex: (cards[i].limit / totalLimit * 1000).round().clamp(1, 1000),
              child: _SegmentTrack(
                used: cards[i].used,
                limit: cards[i].limit,
              ),
            ),
            if (i != cards.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _SegmentTrack extends StatelessWidget {
  const _SegmentTrack({required this.used, required this.limit});
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final pct = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(color: FtColors.line),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(color: FtColors.plum),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Slide 4 — Kesehatan finansial
/// ---------------------------------------------------------------------------
class _KesehatanSlide extends StatelessWidget {
  const _KesehatanSlide({required this.score});
  final HealthScore score;

  Color _stateColor() {
    if (score.score >= 80) return FtColors.healthOk;
    if (score.score >= 50) return FtColors.healthWarn;
    return FtColors.healthBad;
  }

  String _summary() {
    final available = score.factors.where((f) => f.contribution != null).toList()
      ..sort((a, b) => (a.contribution ?? 0).compareTo(b.contribution ?? 0));
    if (available.isEmpty) return 'Data belum cukup untuk membaca pola.';
    return '${available.first.label} paling perlu perhatian.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _stateColor();
    return FtCard(
      onTap: () => context.push('/health'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Kesehatan Finansial'),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _HealthRingPainter(
                      value: score.score / 100,
                      color: color,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${score.score}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: color,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '/ 100',
                            style: TextStyle(
                              color: FtColors.ink3,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score.verdict,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 17,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _summary(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FtColors.ink2,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  _HealthRingPainter({required this.value, required this.color});

  final double value;
  final Color color;
  static const double _thickness = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _thickness) / 2,
    );
    final track = Paint()
      ..color = FtColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (value <= 0) return;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_HealthRingPainter old) =>
      old.value != value || old.color != color;
}
