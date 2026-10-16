import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../insights/insights_providers.dart';
import 'home_formatters.dart';

/// "Uang yang sudah ada pemiliknya": total tagihan terjadwal sisa siklus +
/// perkiraan sisa kas setelahnya. Angka sama persis dengan Kalender Tagihan
/// (satu provider). Tap → kalender. Lives below the hero carousel, not
/// nested inside the asset card — it answers a different question ("what's
/// already spoken for") than net worth ("what do I own").
class CommitmentLine extends ConsumerWidget {
  const CommitmentLine({super.key, required this.hidden});
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(cycleBillsProvider);
    if (bills == null || bills.items.isEmpty) return const SizedBox.shrink();
    final total = bills.projection.upcomingBills;
    final sisa = bills.projection.projected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/calendar'),
        child: Row(
          children: [
            Icon(Icons.event_note_rounded, size: 13, color: FtColors.ink3),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                hidden
                    ? 'Tagihan siklus ini ···· · sisa kas ····'
                    : 'Tagihan siklus ini ${compactMoney(total)} · '
                        'sisa kas ±${compactMoney(sisa)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sisa < 0 && !hidden ? FtColors.danger : FtColors.ink3,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 14, color: FtColors.ink3),
          ],
        ),
      ),
    );
  }
}
