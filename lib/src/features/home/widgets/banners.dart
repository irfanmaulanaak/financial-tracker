import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

enum AttentionKind { due, ratio }

/// One actionable line in "Perlu dibereskan" — a due bill (date tile + amount)
/// or the DSR warning (percent ring + "Lihat"). Not for passive info; those
/// get their own quiet treatment elsewhere.
class AttentionItem {
  /// A bill/obligation coming due.
  const AttentionItem.due({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.danger,
    required this.onTap,
  })  : kind = AttentionKind.due,
        ratio = null,
        actionLabel = null;

  /// A ratio warning (e.g. DSR over the OJK cap), shown with a percent ring.
  const AttentionItem.ratio({
    required this.title,
    required this.subtitle,
    required this.ratio,
    required this.actionLabel,
    required this.onTap,
  })  : kind = AttentionKind.ratio,
        date = null,
        amount = null,
        danger = true;

  final AttentionKind kind;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  // Due variant.
  final DateTime? date;
  final int? amount;
  final bool danger;

  // Ratio variant.
  final double? ratio;
  final String? actionLabel;
}

/// "Perlu dibereskan" — plain rows (no card), split by hairlines, matching the
/// mockup. Renders nothing when [items] is empty; there's no "all clear" state.
class AttentionSection extends StatelessWidget {
  const AttentionSection({super.key, required this.items});

  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FtSectionHeader(title: 'Perlu dibereskan'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Column(
            children: [
              for (final item in items) _AttentionRow(item: item),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});
  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.99,
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
        ),
        child: Row(
          children: [
            if (item.kind == AttentionKind.due)
              _DateTile(date: item.date!)
            else
              _PercentRing(ratio: item.ratio ?? 0),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: FtColors.ink3, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.kind == AttentionKind.due)
              Text(
                compactMoney(item.amount ?? 0),
                style: TextStyle(
                  color: item.danger ? FtColors.danger : FtColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            else
              Text(
                item.actionLabel ?? 'Lihat',
                style: TextStyle(
                  color: FtColors.clay,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: FtColors.warnTile,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w600,
              color: FtColors.onWarnTile,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Dates.monthShort(date),
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w600,
              color: FtColors.onWarnTile,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentRing extends StatelessWidget {
  const _PercentRing({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _RingPainter(
          ratio: ratio.clamp(0.0, 1.0),
          color: FtColors.danger,
          track: FtColors.line,
        ),
        child: Center(
          child: Text(
            '${(ratio * 100).round()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: FtColors.danger,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.ratio, required this.color, required this.track});
  final double ratio;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 3,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = track;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(rect.center, rect.width / 2, base);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * ratio, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio || old.color != color || old.track != track;
}
