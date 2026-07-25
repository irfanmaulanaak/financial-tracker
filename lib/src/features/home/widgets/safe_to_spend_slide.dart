import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';

/// Slide hero "Aman dibelanjakan" — satu angka yang menjawab "boleh pakai
/// berapa hari ini?", dengan anotasi cara hitungnya (ringkasan beranotasi:
/// angka + artinya, bukan angka telanjang).
class SafeToSpendSlide extends StatelessWidget {
  const SafeToSpendSlide({
    super.key,
    required this.perDay,
    required this.remaining,
    required this.daysLeft,
    required this.nextPayday,
    required this.hasBudget,
  });

  final int perDay;
  final int remaining;
  final int daysLeft;
  final DateTime nextPayday;

  /// False bila household belum mengisi budget kategori sama sekali.
  final bool hasBudget;

  @override
  Widget build(BuildContext context) {
    final over = hasBudget && remaining <= 0;
    final tint = over ? FtColors.danger : FtColors.moss;

    return FtCard(
      onTap: () => context.push('/spend'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Aman dibelanjakan'),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasBudget) ...[
                  Text(
                    'Isi budget kategori dulu',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Setelah ada budget, angka "aman dibelanjakan per hari" muncul di sini. Tap untuk mulai.',
                    style: TextStyle(
                        color: FtColors.ink3, fontSize: 12, height: 1.45),
                  ),
                ] else if (over) ...[
                  Text(
                    Money.format(0),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 34, color: tint),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Anggaran siklus ini sudah terpakai '
                    '${Money.compact(-remaining)} lebih. Geser anggaran atau tahan dulu. Gajian ${Dates.dayMonth(nextPayday)}.',
                    style: TextStyle(
                        color: FtColors.ink2, fontSize: 12, height: 1.45),
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Money.format(perDay),
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontSize: 34, color: tint),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, left: 4),
                        child: Text(
                          '/hari',
                          style:
                              TextStyle(color: FtColors.ink3, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Anotasi: dari mana angka ini.
                  Text(
                    '= sisa anggaran ${Money.compact(remaining)} ÷ $daysLeft hari sampai gajian (${Dates.dayMonth(nextPayday)})',
                    style: TextStyle(
                        color: FtColors.ink3, fontSize: 11.5, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 13, color: FtColors.ink4),
              const SizedBox(width: 6),
              Text(
                'Tap untuk rincian per kategori',
                style: TextStyle(color: FtColors.ink4, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
