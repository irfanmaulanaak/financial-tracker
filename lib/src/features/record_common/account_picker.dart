import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_motion.dart';

/// Account row used by both `record_income_screen` (destination) and
/// `record_expense_screen` (source). Each entry is a tuple of id + label +
/// hint (e.g. `Tunai · Rp1.000.000`).
class RecordAccountChoice {
  const RecordAccountChoice({
    required this.id,
    required this.label,
    required this.hint,
  });
  final String id;
  final String label;
  final String hint;
}

/// Renders a vertical list of selectable account rows. Selected row is
/// tinted with [accent]. Empty list shows an inline note nudging the user
/// to add an account first.
class RecordAccountPicker extends StatelessWidget {
  const RecordAccountPicker({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.accent,
    required this.onSelect,
    this.emptyNote = 'Belum ada akun. Tambah dari menu Aset.',
  });

  final List<RecordAccountChoice> accounts;
  final String? selectedId;
  final Color accent;
  final ValueChanged<String> onSelect;
  final String emptyNote;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          emptyNote,
          style: TextStyle(color: FtColors.danger, fontSize: 12),
        ),
      );
    }
    return Column(
      children: [
        for (final a in accounts) ...[
          _AccountRow(
            label: a.label,
            hint: a.hint,
            accent: accent,
            selected: selectedId == a.id,
            onTap: () => onSelect(a.id),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.hint,
    required this.accent,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String hint;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.985,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : FtColors.surface,
          border: Border.all(
            color: selected ? accent : FtColors.line,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? accent : FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? accent : FtColors.line,
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.account_balance_outlined,
                size: 14,
                color: selected ? Colors.white : FtColors.ink2,
              ),
            ),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check, size: 16, color: accent),
          ],
        ),
      ),
    );
  }
}

/// Helper that builds a [RecordAccountChoice] list combining cash + savings
/// accounts with a localized hint per row.
List<RecordAccountChoice> recordAccountChoices({
  required Iterable<dynamic> cashAccounts,
  required Iterable<dynamic> savingsAccounts,
}) {
  return [
    for (final a in cashAccounts)
      RecordAccountChoice(
        id: a.id as String,
        label: a.label as String,
        hint: 'Tunai · ${Money.format(a.value as int)}',
      ),
    for (final a in savingsAccounts)
      RecordAccountChoice(
        id: a.id as String,
        label: a.label as String,
        hint: 'Tabungan · ${Money.format(a.value as int)}',
      ),
  ];
}
