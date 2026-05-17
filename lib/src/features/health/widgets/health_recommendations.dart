import 'package:flutter/material.dart';

import '../../../core/health_score.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';

class _Rec {
  const _Rec({
    required this.icon,
    required this.label,
    required this.detail,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String detail;
  final String route;
}

/// "Rekomendasi" — derived from the live health score + savings/debt
/// inputs. Each row pushes a route on tap.
class HealthRecommendations extends StatelessWidget {
  const HealthRecommendations({
    super.key,
    required this.score,
    required this.cardDebt,
    required this.savingsBalance,
    required this.investmentCount,
    required this.onRoute,
  });
  final HealthScore score;
  final int cardDebt;
  final int savingsBalance;
  final int investmentCount;
  final ValueChanged<String> onRoute;

  List<_Rec> _build() {
    final recs = <_Rec>[];
    if (cardDebt > 0 && cardDebt > savingsBalance * 0.5) {
      recs.add(const _Rec(
        icon: Icons.credit_card_rounded,
        label: 'Prioritaskan pelunasan kartu kredit',
        detail: 'Utang kartu sudah > 50% dari saldo tabungan',
        route: '/cards',
      ));
    }
    if (savingsBalance < 5000000) {
      recs.add(const _Rec(
        icon: Icons.savings_rounded,
        label: 'Bangun dana darurat',
        detail: 'Target awal Rp 5 jt sebelum investasi besar',
        route: '/accounts',
      ));
    }
    if (investmentCount == 0 && savingsBalance > 10000000) {
      recs.add(const _Rec(
        icon: Icons.show_chart_rounded,
        label: 'Mulai diversifikasi ke investasi',
        detail: 'Tabungan cukup — sisipkan ke reksadana atau emas',
        route: '/investments',
      ));
    }
    if (score.score < 50) {
      recs.add(const _Rec(
        icon: Icons.flag_rounded,
        label: 'Tinjau ulang anggaran',
        detail:
            'Skor kesehatan di bawah 50 — atur pos pengeluaran lewat goal',
        route: '/goals',
      ));
    }
    return recs;
  }

  @override
  Widget build(BuildContext context) {
    final recs = _build();
    if (recs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Eyebrow('Rekomendasi'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < recs.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _RecRow(rec: recs[i], onTap: () => onRoute(recs[i].route)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecRow extends StatelessWidget {
  const _RecRow({required this.rec, required this.onTap});
  final _Rec rec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.98,
      haptic: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FtColors.line, width: 0.5),
              ),
              child: Icon(rec.icon, size: 16, color: FtColors.ink2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.label,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rec.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 14, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}
