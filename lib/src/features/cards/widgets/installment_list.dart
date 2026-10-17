import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../home/eling/month_path_track.dart';
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
        // Only real installments count as "cicilan" — a one-time (Lunas,
        // 1-month) purchase isn't one, same rule as `monthlyInstallmentDsrTotal`.
        final installments =
            items.where((i) => !i.isComplete && i.monthsTotal > 1).toList();
        final onceOff = items.where((i) => !i.isComplete && i.monthsTotal == 1).toList();
        if (installments.isEmpty && onceOff.isEmpty) {
          return const SizedBox.shrink();
        }
        final totalMonthly =
            installments.fold<int>(0, (a, i) => a + i.monthly);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 10),
              if (installments.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 14, color: FtColors.ink3),
                    const SizedBox(width: 6),
                    Text(
                      '${installments.length} cicilan aktif · ${Money.format(totalMonthly)}/bln',
                      style: TextStyle(
                        color: FtColors.ink2,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final i in installments.take(3))
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
                        MonthPathMini(
                          monthsTotal: i.monthsTotal,
                          monthsPaid: i.monthsPaid,
                        ),
                      ],
                    ),
                  ),
              ],
              if (onceOff.isNotEmpty) ...[
                if (installments.isNotEmpty) const SizedBox(height: 4),
                Text(
                  '${onceOff.length} belum ditagih · '
                  '${Money.format(onceOff.fold<int>(0, (a, i) => a + i.monthly))}',
                  style: TextStyle(
                    color: FtColors.ink3,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
