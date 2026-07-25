import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../theme.dart';
import '../../../ui/ft_action_sheet.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';
import '../../household/household_providers.dart';
import '../expense.dart';
import '../expense_social.dart';

/// Minta-cek transaksi: satu anggota menandai anggota lain untuk meninjau
/// transaksi ini ("ini benar nggak?"). Status hidup di doc expense
/// (`review: {by, to, done, at}`), jadi langsung kelihatan di semua device.
class ExpenseReviewSection extends ConsumerWidget {
  const ExpenseReviewSection({
    super.key,
    required this.expense,
    required this.household,
  });

  final Expense expense;
  final Household household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final canTxn = ref.watch(canRecordTxnProvider);
    final live = ref
        .watch(expenseLiveProvider((hid: household.id, eid: expense.id)))
        .value;
    final review = live?.review ?? expense.review;
    final others = household.members
        .where((m) => m.userId != uid)
        .toList(growable: false);

    // Tanpa permintaan aktif: tampilkan tombol kecil hanya bila ada anggota
    // lain yang bisa diminta dan user boleh menulis transaksi.
    if (review == null) {
      if (!canTxn || uid == null || others.isEmpty) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: FtTapScale(
          onTap: () => _pickMember(context, ref, uid, others),
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: FtColors.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FtColors.line, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_outlined, size: 15, color: FtColors.ink2),
                const SizedBox(width: 6),
                Text(
                  'Minta cek anggota lain',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FtColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final byName = household.memberOf(review.by)?.displayName ?? 'Anggota';
    final toName = household.memberOf(review.to)?.displayName ?? 'anggota';
    final done = review.done;
    final tint = done ? FtColors.moss : FtColors.ochre;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.30), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_outline : Icons.flag_outlined,
            size: 18,
            color: tint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              done
                  ? 'Sudah dicek $toName. Beres.'
                  : '$byName minta $toName cek transaksi ini',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: FtColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (canTxn) ...[
            const SizedBox(width: 8),
            if (!done)
              TextButton(
                onPressed: () => _resolve(context, ref),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text(
                  'Tandai beres',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              )
            else
              FtTapScale(
                onTap: () => _clear(context, ref),
                child: Icon(Icons.close, size: 16, color: FtColors.ink3),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickMember(
    BuildContext context,
    WidgetRef ref,
    String uid,
    List<Member> others,
  ) async {
    final target = await showFtActionSheet<Member>(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 4, 6, 12),
              child: Eyebrow('Minta siapa untuk cek?'),
            ),
            for (final m in others)
              FtTapScale(
                onTap: () => Navigator.of(sheetCtx).pop(m),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: FtColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FtColors.line, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            parseColor(m.color).withValues(alpha: 0.18),
                        child: Text(
                          m.displayName.isEmpty
                              ? '?'
                              : m.displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: parseColor(m.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        m.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FtColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (target == null || !context.mounted) return;
    try {
      await ref.read(expenseSocialRepositoryProvider).requestReview(
            householdId: household.id,
            expenseId: expense.id,
            by: uid,
            to: target.userId,
          );
      FtHaptics.success();
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal minta cek');
      }
    }
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(expenseSocialRepositoryProvider).resolveReview(
            householdId: household.id,
            expenseId: expense.id,
          );
      FtHaptics.success();
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menandai beres');
      }
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(expenseSocialRepositoryProvider).clearReview(
            householdId: household.id,
            expenseId: expense.id,
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menghapus tanda');
      }
    }
  }
}
