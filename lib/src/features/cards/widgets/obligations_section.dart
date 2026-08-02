import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../obligations/obligation_repository.dart';

/// Ringkasan cicilan tetap (leasing/KPR/sewa) di tab Utang, pintu masuk
/// utama ke /obligations.
class ObligationsSection extends ConsumerWidget {
  const ObligationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligations = ref.watch(obligationsProvider).value ?? const [];
    final active = obligations.where((o) => !o.isComplete).toList();
    final total = active.fold<int>(0, (a, o) => a + o.monthly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
          child: Eyebrow('Cicilan Tetap'),
        ),
        if (active.isEmpty)
          FtDashedAdd(
            margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            label: 'Tambah cicilan tetap (leasing, KPR, sewa)',
            onTap: () => context.push('/obligations'),
          )
        else
          FtCard(
            margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: InkWell(
              onTap: () => context.push('/obligations'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${active.length} cicilan · ${compactMoney(total)}/bln',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: FtColors.ink3),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final o in active.take(3))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${o.label} · ${compactMoney(o.monthly)}/bln · ${o.monthsPaid}/${o.monthsTotal}',
                        style: TextStyle(color: FtColors.ink3, fontSize: 11.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
