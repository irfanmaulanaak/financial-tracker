import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../credit_card.dart';
import 'installment_list.dart';

class LabeledStat extends StatelessWidget {
  const LabeledStat({
    super.key,
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
class CicilanTotalStat extends ConsumerWidget {
  const CicilanTotalStat({super.key, required this.hid, required this.cards});
  final String hid;
  final List<CreditCard> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var total = 0;
    for (final c in cards) {
      total += monthlyInstallmentDsrTotal(ref
              .watch(cardInstallmentsProvider((hid: hid, cardId: c.id)))
              .value ??
          const []);
    }
    return LabeledStat(
      label: 'Cicilan/bln',
      value: total > 0 ? compactMoney(total) : '—',
    );
  }
}

/// Cicilan bulanan berjalan yang ikut DSR: multi-bulan saja, tenor 1×
/// adalah tagihan sekali bayar.
int monthlyInstallmentDsrTotal(Iterable<Installment> installments) {
  return installments
      .where((i) => !i.isComplete && i.monthsTotal > 1)
      .fold(0, (total, i) => total + i.monthly);
}

/// "Saran" tip card at the bottom of the cards list — calls out high
/// debt-service ratios and suggests action.
class SaranTip extends ConsumerWidget {
  const SaranTip({
    super.key,
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
      monthlyInstallments += monthlyInstallmentDsrTotal(list);
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
