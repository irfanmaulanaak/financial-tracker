import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';
import '../daily_insight_lock.dart';
import '../eling/eling_mood.dart';
import '../eling/eling_scene.dart';
import '../home_data_synced.dart';
import 'home_formatters.dart';

/// The hero panel (DESIGN.md section 8 item 2): "Aman dibelanjakan hari ini",
/// the big safe-to-spend number, one plain sentence, then the Eling hill scene.
/// Sits on the `hero` color, full width.
///
/// Firestore streams deliver cached/partial data first, so the hero inputs
/// (perDay, remaining, mood) jump around on a cold start. We debounce: nothing
/// is shown — and Eling waits as a still ball at the start dot — until the
/// inputs have held steady for [_settleMs]. Only then does the entrance play.
/// Afterwards, data changes just re-count the number; the roll never replays.
class HomeHeroScene extends ConsumerStatefulWidget {
  const HomeHeroScene({
    super.key,
    required this.perDay,
    required this.remaining,
    required this.daysLeft,
    required this.hasBudget,
    required this.mood,
    required this.daysElapsed,
    required this.cycleLength,
    required this.insightCandidate,
    required this.startLabel,
    required this.paydayLabel,
    required this.inputsReady,
  });

  final int perDay;
  final int remaining;
  final int daysLeft;
  final bool hasBudget;
  final ElingMood mood;
  final int daysElapsed;
  final int cycleLength;
  final String? insightCandidate;
  final String startLabel;
  final String paydayLabel;

  /// True once every provider behind [perDay] / [remaining] / [mood] has loaded.
  /// The settle check waits for this so the entrance doesn't play over a budget
  /// computed from partial data (cards/installments/obligations load late).
  final bool inputsReady;

  @override
  ConsumerState<HomeHeroScene> createState() => _HomeHeroSceneState();
}

class _HomeHeroSceneState extends ConsumerState<HomeHeroScene> {
  static const _settleMs = 700;

  Timer? _settle;
  bool _stable = false;
  bool _reduce = false;
  bool _firstEver = false;
  bool _countFromZero = false;
  bool _syncedLatched = false;

  String? _lastCandidate;
  bool _resolvedOnce = false;

  @override
  void initState() {
    super.initState();
    _firstEver = !ElingSession.settledOnce;
    // Revisits already have loaded, steady data — show at once, no entrance.
    if (!_firstEver) {
      _stable = true;
      _syncedLatched = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(HomeHeroScene old) {
    super.didUpdateWidget(old);
    // Only re-wait on input changes after the data has synced; before that the
    // settle timer hasn't started yet (we're still waiting for the server).
    if (_stable || !_syncedLatched) return;
    if (widget.perDay != old.perDay ||
        widget.remaining != old.remaining ||
        widget.mood != old.mood) {
      _startSettle(); // inputs still moving — wait again
    }
  }

  void _startSettle() {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: _settleMs), () {
      if (!mounted) return;
      setState(() {
        _stable = true;
        _countFromZero = _firstEver && !_reduce;
      });
      ElingSession.settledOnce = true;
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wait for real server data before starting the settle check / entrance —
    // Firestore emits cache-first snapshots that would otherwise animate the
    // number over wrong values on a cold start.
    final synced = ref.watch(homeDataSyncedProvider).value ?? false;
    if (!_stable && synced && widget.inputsReady && !_syncedLatched) {
      _syncedLatched = true;
      _startSettle();
    }

    final locked = ref.watch(dailyInsightLockProvider);
    // Lock today's insight the first time a candidate shows up (and whenever it
    // changes as data streams in). Done after the frame to avoid mutating a
    // provider during build.
    if (!_resolvedOnce || widget.insightCandidate != _lastCandidate) {
      _resolvedOnce = true;
      _lastCandidate = widget.insightCandidate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // ignore: discarded_futures
          ref
              .read(dailyInsightLockProvider.notifier)
              .resolve(widget.insightCandidate);
        }
      });
    }
    final bubbleText = locked ?? elingLine(widget.mood);

    return Container(
      width: double.infinity,
      color: FtColors.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Text(
              'Aman dibelanjakan hari ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: FtColors.onHero.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            child: !_stable
                // Waiting for the data to settle: reserve the number's height
                // so the hill doesn't jump, but show no value.
                ? const SizedBox(height: 58)
                : widget.hasBudget
                    ? _number()
                    : _noBudget(context),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: _stable && widget.hasBudget
                ? _sentence()
                : const SizedBox(height: 19),
          ),
          const SizedBox(height: 4),
          ElingScene(
            ready: _stable,
            mood: widget.mood,
            perDay: widget.perDay,
            daysElapsed: widget.daysElapsed,
            cycleLength: widget.cycleLength,
            bubbleText: bubbleText,
            startLabel: widget.startLabel,
            paydayLabel: widget.paydayLabel,
          ),
        ],
      ),
    );
  }

  Widget _number() {
    return TweenAnimationBuilder<int>(
      tween: IntTween(
        begin: _countFromZero ? 0 : widget.perDay,
        end: widget.perDay,
      ),
      // Entrance counts up over 950ms; later data changes get a short count.
      duration: Duration(
        milliseconds: _reduce ? 0 : (_countFromZero ? 950 : 400),
      ),
      curve: Curves.easeOutCubic,
      onEnd: () {
        if (_countFromZero) setState(() => _countFromZero = false);
      },
      builder: (context, value, _) {
        final parts = heroMoneyParts(value);
        final big = GoogleFonts.fredoka(
          fontSize: 58,
          height: 1,
          letterSpacing: -0.5,
          fontWeight: FontWeight.w600,
          color: FtColors.onHero,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        final small = GoogleFonts.fredoka(
          fontSize: 26,
          fontWeight: FontWeight.w500,
          color: FtColors.onHero,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        return RichText(
          text: TextSpan(children: [
            TextSpan(text: '${parts.prefix} ', style: small),
            TextSpan(text: parts.number, style: big),
            if (parts.suffix.isNotEmpty)
              TextSpan(text: parts.suffix, style: small),
          ]),
        );
      },
    );
  }

  Widget _noBudget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Belum ada anggaran',
          style: GoogleFonts.fredoka(
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w600,
            color: FtColors.onHero,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/spend'),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Atur anggaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FtColors.clay,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sentence() {
    final over = widget.remaining < 0;
    final text = over
        ? 'Anggaran siklus ini sudah lewat ${compactMoney(widget.remaining.abs())}.'
        : 'Sisa ${compactMoney(widget.remaining)} dibagi ${widget.daysLeft} hari sampai gajian.';
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: over ? FontWeight.w600 : FontWeight.w400,
        color: over
            ? FtColors.onHeroDanger
            : FtColors.onHero.withValues(alpha: 0.65),
      ),
    );
  }
}
