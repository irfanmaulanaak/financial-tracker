import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_motion.dart';
import '../accounts/account.dart';

/// Sub-account filter pills shown inside the dropdown sheet. `all` includes
/// savings; `bank` keeps savings + cash-bank rows; `ewallet` keeps only
/// cash-ewallet rows. Used only when `enableSubKindFilter` is true.
enum RecordAccountSubFilter { all, bank, ewallet }

/// Account row used by both `record_income_screen` (destination) and
/// `record_expense_screen` (source). Each entry is a tuple of id + label +
/// hint (e.g. `Tunai · Rp1.000.000`).
class RecordAccountChoice {
  const RecordAccountChoice({
    required this.id,
    required this.label,
    required this.hint,
    this.subKind = AccountSubKind.bank,
  });
  final String id;
  final String label;
  final String hint;

  /// For cash accounts, mirrors `Account.subKind`. Savings accounts pass
  /// through as `bank` since they're bank-issued products.
  final AccountSubKind subKind;
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
  required Iterable<Account> cashAccounts,
  required Iterable<Account> savingsAccounts,
}) {
  return [
    for (final a in cashAccounts)
      RecordAccountChoice(
        id: a.id,
        label: a.label,
        hint: 'Tunai · ${Money.format(a.value)}',
        subKind: a.subKind,
      ),
    for (final a in savingsAccounts)
      RecordAccountChoice(
        id: a.id,
        label: a.label,
        hint: 'Tabungan · ${Money.format(a.value)}',
      ),
  ];
}

/// Compact tap-to-open account selector. Shows the currently selected
/// account inline; tapping opens a bottom sheet listing every account.
/// Set [enableSubKindFilter] to surface Semua / Bank / E-wallet pills
/// inside the sheet (used by the transfer screen).
class RecordAccountDropdownField extends StatelessWidget {
  const RecordAccountDropdownField({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.accent,
    required this.onSelect,
    required this.sheetTitle,
    this.placeholder = 'Pilih rekening',
    this.emptyNote = 'Belum ada akun. Tambah dari menu Aset.',
    this.enableSubKindFilter = false,
  });

  final List<RecordAccountChoice> accounts;
  final String? selectedId;
  final Color accent;
  final ValueChanged<String> onSelect;
  final String sheetTitle;
  final String placeholder;
  final String emptyNote;
  final bool enableSubKindFilter;

  RecordAccountChoice? get _selected {
    if (selectedId == null) return null;
    for (final a in accounts) {
      if (a.id == selectedId) return a;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    FtHaptics.tap();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FtColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AccountSelectorSheet(
        title: sheetTitle,
        accounts: accounts,
        selectedId: selectedId,
        accent: accent,
        enableSubKindFilter: enableSubKindFilter,
        emptyNote: emptyNote,
      ),
    );
    if (picked != null && picked != selectedId) onSelect(picked);
  }

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
    final sel = _selected;
    final hasSelection = sel != null;
    return FtTapScale(
      scale: 0.985,
      haptic: false,
      onTap: () => _open(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasSelection ? accent.withValues(alpha: 0.08) : FtColors.surface,
          border: Border.all(
            color: hasSelection ? accent : FtColors.line,
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
                color: hasSelection ? accent : FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasSelection ? accent : FtColors.line,
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.account_balance_outlined,
                size: 14,
                color: hasSelection ? Colors.white : FtColors.ink2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelection ? sel.label : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasSelection ? FtColors.ink : FtColors.ink3,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasSelection) ...[
                    const SizedBox(height: 2),
                    Text(
                      sel.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: FtColors.ink3,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSelectorSheet extends StatefulWidget {
  const _AccountSelectorSheet({
    required this.title,
    required this.accounts,
    required this.selectedId,
    required this.accent,
    required this.enableSubKindFilter,
    required this.emptyNote,
  });

  final String title;
  final List<RecordAccountChoice> accounts;
  final String? selectedId;
  final Color accent;
  final bool enableSubKindFilter;
  final String emptyNote;

  @override
  State<_AccountSelectorSheet> createState() => _AccountSelectorSheetState();
}

class _AccountSelectorSheetState extends State<_AccountSelectorSheet> {
  RecordAccountSubFilter _filter = RecordAccountSubFilter.all;

  List<RecordAccountChoice> get _filtered {
    switch (_filter) {
      case RecordAccountSubFilter.all:
        return widget.accounts;
      case RecordAccountSubFilter.bank:
        return widget.accounts
            .where((c) => c.subKind == AccountSubKind.bank)
            .toList();
      case RecordAccountSubFilter.ewallet:
        return widget.accounts
            .where((c) => c.subKind == AccountSubKind.ewallet)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FtColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      letterSpacing: -0.2,
                    ),
              ),
              if (widget.enableSubKindFilter) ...[
                const SizedBox(height: 12),
                SegmentedButton<RecordAccountSubFilter>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                        value: RecordAccountSubFilter.all, label: Text('Semua')),
                    ButtonSegment(
                        value: RecordAccountSubFilter.bank, label: Text('Bank')),
                    ButtonSegment(
                        value: RecordAccountSubFilter.ewallet,
                        label: Text('E-wallet')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) =>
                      setState(() => _filter = s.first),
                ),
              ],
              const SizedBox(height: 12),
              Flexible(
                child: visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          widget.emptyNote,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: FtColors.ink3, fontSize: 12),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: RecordAccountPicker(
                          accounts: visible,
                          selectedId: widget.selectedId,
                          accent: widget.accent,
                          onSelect: (id) => Navigator.pop(context, id),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
