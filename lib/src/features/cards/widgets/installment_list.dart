import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../card_repository.dart';
import '../credit_card.dart';

/// Stream of installments for a single card. Public so the cards screen,
/// card-detail screen, and home-page summary widgets can share a single
/// Firestore subscription per (hid, cardId).
final cardInstallmentsProvider =
    StreamProvider.family<List<Installment>, ({String hid, String cardId})>(
  (ref, p) => ref
      .watch(cardRepositoryProvider)
      .watchInstallments(hid: p.hid, cardId: p.cardId),
);

/// Inline list of active installments shown inside [CardTile]. Renders an
/// empty box when the card has no active plans.
class CardInstallmentsInline extends ConsumerWidget {
  const CardInstallmentsInline({
    super.key,
    required this.hid,
    required this.cardId,
  });

  final String hid;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(cardInstallmentsProvider((hid: hid, cardId: cardId)));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        final active = items.where((i) => !i.isComplete).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        final totalMonthly = active.fold<int>(0, (a, i) => a + i.monthly);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_month, size: 14, color: FtColors.ink3),
                  const SizedBox(width: 6),
                  Text(
                    '${active.length} cicilan aktif · ${Money.format(totalMonthly)}/bln',
                    style: TextStyle(
                      color: FtColors.ink2,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final i in active.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.label.isNotEmpty ? i.label : 'Cicilan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: FtColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${i.monthsPaid}/${i.monthsTotal} bulan · ${Money.format(i.monthly)}/bln',
                              style: TextStyle(
                                color: FtColors.ink3,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: FtProgressBar(
                          value: i.monthsPaid,
                          max: i.monthsTotal,
                          color:
                              ftProgressColor(i.monthsPaid, i.monthsTotal),
                          height: 4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
