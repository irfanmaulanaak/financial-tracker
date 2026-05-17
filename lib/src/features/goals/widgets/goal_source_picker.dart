import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';

/// Cash-account picker rendered as a stack of selectable rows on the
/// add-goal screen. The selected row tints with [tone]. Caller passes
/// `household.cashAccounts` (typed `Account` from
/// `lib/.../accounts/account.dart`); using `dynamic` here keeps the goal
/// feature free of an accounts-feature import.
class GoalSourceAccounts extends StatelessWidget {
  const GoalSourceAccounts({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.tone,
    required this.onSelect,
  });

  final List<dynamic> accounts;
  final String? selectedId;
  final Color tone;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FtColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Text(
          'Belum ada rekening tunai. Tambahkan lewat Aset → Tunai dulu.',
          style: TextStyle(color: FtColors.ink3, fontSize: 12),
        ),
      );
    }
    return Column(
      children: [
        for (final a in accounts) ...[
          _AccountRow(
            id: a.id as String,
            label: a.label as String,
            hint: (a.hint as String?) ?? '',
            value: (a.value as int),
            tone: tone,
            active: selectedId == a.id,
            onTap: () => onSelect(a.id as String),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.id,
    required this.label,
    required this.hint,
    required this.value,
    required this.tone,
    required this.active,
    required this.onTap,
  });
  final String id;
  final String label;
  final String hint;
  final int value;
  final Color tone;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? tone.withValues(alpha: 0.10) : FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? tone : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_outlined,
                size: 16, color: active ? tone : FtColors.ink2),
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
                  if (hint.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: FtColors.ink3, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              Money.format(value),
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auto-debit row with a label, helper text, and a sliding toggle.
class GoalAutoDebitToggle extends StatelessWidget {
  const GoalAutoDebitToggle({
    super.key,
    required this.value,
    required this.tone,
    required this.onChange,
  });
  final bool value;
  final Color tone;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 16,
              color: value ? tone : FtColors.ink3,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-debit setiap tanggal 1',
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Setoran rutin dipotong otomatis dari rekening sumber',
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? tone : FtColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
