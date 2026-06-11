import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';
import '../onboarding_state.dart';

/// Kartu "Mulai dari sini" di home — 4 langkah pertama memakai FinSist
/// (pola checklist Monarch). Status dihitung dari data nyata; hanya
/// langkah "lihat budget" yang ditandai manual saat di-tap. Tampil hanya
/// saat [onboardingProvider] aktif (user baru, atau dibuka dari menu).
class OnboardingChecklist extends ConsumerWidget {
  const OnboardingChecklist({
    super.key,
    required this.household,
    required this.hasExpense,
  });

  final Household household;
  final bool hasExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onb = ref.watch(onboardingProvider);
    if (!onb.checklistActive) return const SizedBox.shrink();

    final hasAccount = household.cashAccounts.isNotEmpty ||
        household.savingsAccounts.isNotEmpty;
    final hasPartner = household.members.length > 1;

    final steps = <_Step>[
      _Step(
        label: 'Tambah rekening pertama',
        detail: 'Biar saldo ikut terpotong saat mencatat',
        icon: Icons.account_balance_wallet_outlined,
        done: hasAccount,
        onTap: () => context.push('/accounts'),
      ),
      _Step(
        label: 'Catat pengeluaran pertama',
        detail: 'Coba catat jajan terakhirmu hari ini',
        icon: Icons.edit_outlined,
        done: hasExpense,
        onTap: () => context.push('/expenses/new'),
      ),
      _Step(
        label: 'Kenali budget kategori',
        detail: 'Lihat sisa amplop tiap kategori',
        icon: Icons.pie_chart_outline,
        done: onb.budgetChecked,
        onTap: () {
          // ignore: discarded_futures
          ref.read(onboardingProvider.notifier).markBudgetChecked();
          context.push('/spend');
        },
      ),
      _Step(
        label: 'Undang pasangan',
        detail: 'Catat bareng dengan kode undangan',
        icon: Icons.group_add_outlined,
        done: hasPartner,
        onTap: () => context.push('/members'),
      ),
    ];
    final doneCount = steps.where((s) => s.done).length;
    final allDone = doneCount == steps.length;

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Eyebrow('Mulai Dari Sini')),
              Text(
                '$doneCount/${steps.length}',
                style: TextStyle(
                  color: FtColors.ink3,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              FtTapScale(
                scale: 0.9,
                onTap: () {
                  FtHaptics.select();
                  // ignore: discarded_futures
                  ref.read(onboardingProvider.notifier).dismissChecklist();
                },
                child: Icon(Icons.close_rounded,
                    size: 16, color: FtColors.ink3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FtProgressBar(
            value: doneCount,
            max: steps.length,
            color: FtColors.moss,
            height: 4,
          ),
          const SizedBox(height: 12),
          if (allDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Semua beres — kamu siap pakai FinSist. Buka lagi kapan '
                'saja dari menu \u22ef \u2192 Panduan Mulai.',
                style: TextStyle(
                    color: FtColors.ink2, fontSize: 12, height: 1.5),
              ),
            )
          else
            for (final s in steps) _StepRow(step: s),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.label,
    required this.detail,
    required this.icon,
    required this.done,
    required this.onTap,
  });
  final String label;
  final String detail;
  final IconData icon;
  final bool done;
  final VoidCallback onTap;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.985,
      onTap: step.done ? null : step.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: step.done
                    ? FtColors.moss.withValues(alpha: 0.12)
                    : FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: step.done
                      ? FtColors.moss.withValues(alpha: 0.3)
                      : FtColors.line,
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                step.done ? Icons.check_rounded : step.icon,
                size: 15,
                color: step.done ? FtColors.moss : FtColors.ink2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      color: step.done ? FtColors.ink3 : FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration:
                          step.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (!step.done) ...[
                    const SizedBox(height: 1),
                    Text(
                      step.detail,
                      style: TextStyle(color: FtColors.ink3, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (!step.done)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}
