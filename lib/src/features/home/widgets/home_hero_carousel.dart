import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/health_score.dart';
import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import 'home_hero_aset_slide.dart';
import 'home_hero_kesehatan_slide.dart';
import 'home_hero_ratio_slide.dart';
import 'safe_to_spend_slide.dart';

export 'home_hero_commitment_line.dart';

/// 3-page swipeable hero card on the home screen — one question each:
///   1. Total Aset (what do I own, net of debt)
///   2. Aman dibelanjakan (can I spend today)
///   3. Kesehatan finansial (composite verdict, incl. spend-vs-gaji and debt)
///
/// Dropped from the old 5-page version: a standalone "Pengeluaran vs Gaji"
/// slide and a "Kartu Kredit" slide — both answered questions already
/// covered elsewhere (Kesehatan's verdict, the Utang tab, and the home
/// "Perlu perhatian" card's due-date lines), so keeping them here was just
/// more swiping for the same answer.
///
/// Each page is a self-contained card body wrapped in [FtCard] with a
/// `onTap` that routes to the full feature screen. Below the PageView sits
/// a row of dot indicators tracking the active page.
///
/// Beranda "Ringkas" ([compact]) narrows this to 2 pages — Aman dibelanjakan
/// and Pengeluaran vs Gaji — the rest stay reachable from their own
/// tabs/screens.
class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    super.key,
    required this.nw,
    required this.trend,
    this.trendDates = const [],
    required this.cycleNet,
    required this.spend,
    required this.gajiIncome,
    required this.health,
    required this.safe,
    this.compact = false,
  });

  final NetWorth nw;
  final List<double> trend;

  /// Calendar day for each [trend] point; same length when provided.
  /// Enables the hover/scrub readout on the asset sparkline.
  final List<DateTime> trendDates;

  /// Income (Gaji only) minus spend, this cycle. Used by the asset slide
  /// to render the small delta pill.
  final int cycleNet;

  /// Total expenses in the current cycle. Only still used by the Ringkas
  /// ratio slide — the Lengkap carousel no longer has a standalone slide
  /// for this.
  final int spend;

  /// Sum of `IncomeSource.salary` rows for the current cycle. Drives the
  /// Ringkas ratio ring.
  final int gajiIncome;

  final HealthScore health;

  /// Data slide "aman dibelanjakan" (dihitung di home dari budget siklus).
  final ({
    int perDay,
    int remaining,
    int daysLeft,
    DateTime nextPayday,
    bool hasBudget,
  }) safe;

  /// Beranda "Ringkas": only the safe-to-spend hero + this cycle's spending
  /// ratio (2 slides) — net worth and kesehatan stay reachable from their
  /// own tabs/screens but drop off the home carousel.
  final bool compact;

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
            height: 256,
            // Default web/desktop scroll behavior excludes mouse drags, which
            // made slides 2-4 unreachable with a mouse. Opt the PageView in.
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: PageView.builder(
              controller: _controller,
              itemCount: widget.compact ? 2 : 3,
              onPageChanged: (i) {
                FtHaptics.select();
                setState(() => _page = i);
              },
              itemBuilder: (_, index) {
                final safeToSpendSlide = SafeToSpendSlide(
                  perDay: widget.safe.perDay,
                  remaining: widget.safe.remaining,
                  daysLeft: widget.safe.daysLeft,
                  nextPayday: widget.safe.nextPayday,
                  hasBudget: widget.safe.hasBudget,
                );
                final slide = widget.compact
                    ? switch (index) {
                        0 => safeToSpendSlide,
                        _ => RatioSlide(
                            spend: widget.spend,
                            gajiIncome: widget.gajiIncome,
                          ),
                      }
                    : switch (index) {
                        0 => AsetSlide(
                            nw: widget.nw,
                            trend: widget.trend,
                            trendDates: widget.trendDates,
                            cycleNet: widget.cycleNet,
                          ),
                        1 => safeToSpendSlide,
                        _ => KesehatanSlide(score: widget.health),
                      };
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    // PageController.page may be null until first scroll.
                    final page = _controller.hasClients &&
                            _controller.position.hasContentDimensions
                        ? (_controller.page ?? _controller.initialPage.toDouble())
                        : index.toDouble();
                    final offset = (page - index).abs().clamp(0.0, 1.0);
                    final scale = 1 - 0.06 * offset;
                    final opacity = 1 - 0.35 * offset;
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: slide,
                );
              },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Dots(
            count: widget.compact ? 2 : 3,
            active: _page,
            onSelect: (i) => _controller.animateToPage(
              i,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.active,
    required this.onSelect,
  });
  final int count;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            label: 'Slide ${i + 1} dari $count',
            selected: i == active,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: i == active ? null : () => onSelect(i),
              // Padding widens the tap target around the 6px dot.
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == active ? FtColors.ink : FtColors.lineStrong,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
