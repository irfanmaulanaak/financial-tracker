import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/hide_assets_provider.dart';
import '../../../theme.dart';
import 'home_formatters.dart';

/// Right column of the Lengkap hero (DESIGN.md section 8 item 2): "Kekayaan
/// bersih", the live net worth number, and its two-week change. Counts up
/// alongside the left safe-to-spend number during the entrance, using the same
/// timing and the same reduce-motion rule. Tapping the number opens Aset.
class HeroNetWorth extends ConsumerWidget {
  const HeroNetWorth({
    super.key,
    required this.total,
    required this.changeFrom,
    required this.stable,
    required this.countUp,
    required this.reduce,
  });

  /// Live net worth (`computeNetWorth`), not the last snapshot.
  final int total;

  /// First value of the 14-day daily series, or null when there's no history.
  /// The change line is `total - changeFrom` (live top, historical base) so a
  /// fresh snapshot write doesn't move the line right after the hero settles.
  final double? changeFrom;

  /// While false the number area is reserved but empty (data not settled yet).
  final bool stable;

  /// Count up from 0 on the entrance (false for revisits / reduce motion).
  final bool countUp;
  final bool reduce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    final labelColor = FtColors.onHero.withValues(alpha: 0.65);
    final delta = changeFrom == null ? null : total - changeFrom!.round();
    final showChange = !hidden && delta != null && delta != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Kekayaan bersih',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            HideAssetsEye(color: labelColor),
          ],
        ),
        const SizedBox(height: 6),
        if (!stable)
          const SizedBox(height: 34)
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/accounts'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 34,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: hidden ? _masked() : _number(),
                  ),
                ),
                if (showChange) ...[
                  const SizedBox(height: 4),
                  // Two fixed lines so it never breaks as "dalam 2 / minggu"
                  // in the narrow column.
                  Text(
                    '${delta < 0 ? 'Turun' : 'Naik'} '
                    '${compactMoney(delta.abs())}\ndalam 2 minggu',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color:
                          delta < 0 ? FtColors.onHeroDanger : FtColors.onHero,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _masked() => Text(
        maskMoney(),
        style: GoogleFonts.fredoka(
          fontSize: 34,
          height: 1,
          fontWeight: FontWeight.w600,
          color: FtColors.onHero,
        ),
      );

  Widget _number() {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: countUp ? 0 : total, end: total),
      duration: Duration(milliseconds: reduce ? 0 : (countUp ? 950 : 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final parts = heroMoneyParts(value);
        final big = GoogleFonts.fredoka(
          fontSize: 34,
          height: 1,
          letterSpacing: -0.5,
          fontWeight: FontWeight.w600,
          color: FtColors.onHero,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        final small = GoogleFonts.fredoka(
          fontSize: 18,
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
}
