import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../household/household.dart';
import '../../investments/investment.dart';
import '../goal.dart';

/// Pilihan sumber dana goal. `type`/`id` null = manual (setoran).
class GoalFundingChoice {
  final String? type;
  final String? id;
  const GoalFundingChoice.manual()
      : type = null,
        id = null;
  const GoalFundingChoice.linked(String this.type, String this.id);
}

typedef GoalFundingAsset = ({String label, int value, bool missing});

/// Info aset sumber dana sebuah goal. Null = goal manual. `missing` true
/// bila asetnya sudah dihapus (nilai dianggap 0).
GoalFundingAsset? goalFundingAssetOf({
  required Goal goal,
  required Household household,
  required List<Investment> investments,
}) {
  if (!goal.isLinked) return null;
  if (goal.fundingType == 'savings') {
    final acc = household.accountOf(goal.fundingId!);
    if (acc == null) {
      return (label: 'Aset tidak ditemukan', value: 0, missing: true);
    }
    return (label: acc.label, value: acc.value, missing: false);
  }
  for (final inv in investments) {
    if (inv.id == goal.fundingId) {
      return (label: inv.label, value: inv.currentValue, missing: false);
    }
  }
  return (label: 'Aset tidak ditemukan', value: 0, missing: true);
}

/// Bottom sheet pemilih sumber dana: Manual, rekening tabungan, atau
/// posisi investasi. Mengembalikan null bila dibatalkan.
Future<GoalFundingChoice?> showGoalFundingSheet(
  BuildContext context, {
  required Household household,
  required List<Investment> investments,
  String? currentKey,
}) {
  return showModalBottomSheet<GoalFundingChoice>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final maxH = MediaQuery.of(sheetCtx).size.height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Text('Sumber Dana',
                  style: Theme.of(sheetCtx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Tujuan yang terhubung ke aset mengikuti nilai aset itu. '
                'Dibagi proporsional bila dipakai beberapa tujuan.',
                style: TextStyle(color: FtColors.ink3, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: 'Manual (setoran)',
                sub: 'Catat setoran sendiri ke tujuan ini',
                selected: currentKey == null,
                onTap: () =>
                    Navigator.pop(sheetCtx, const GoalFundingChoice.manual()),
              ),
              if (household.savingsAccounts.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionLabel('Tabungan'),
                for (final a in household.savingsAccounts)
                  _OptionTile(
                    icon: Icons.savings_outlined,
                    label: a.label,
                    sub: Money.format(a.value),
                    selected: currentKey == 'savings:${a.id}',
                    onTap: () => Navigator.pop(
                        sheetCtx, GoalFundingChoice.linked('savings', a.id)),
                  ),
              ],
              if (investments.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionLabel('Investasi'),
                for (final inv in investments)
                  _OptionTile(
                    icon: Icons.trending_up,
                    label: inv.label,
                    sub: Money.format(inv.currentValue),
                    selected: currentKey == 'investment:${inv.id}',
                    onTap: () => Navigator.pop(sheetCtx,
                        GoalFundingChoice.linked('investment', inv.id)),
                  ),
              ],
              if (household.savingsAccounts.isEmpty &&
                  investments.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Belum ada rekening tabungan atau investasi. Tambahkan '
                  'dulu di menu Aset untuk menghubungkan tujuan.',
                  style: TextStyle(color: FtColors.ink3, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: FtColors.ink3,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? FtColors.clay.withValues(alpha: 0.08) : FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? FtColors.clay : FtColors.line,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? FtColors.clay : FtColors.ink2),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 18, color: FtColors.clay),
          ],
        ),
      ),
    );
  }
}
