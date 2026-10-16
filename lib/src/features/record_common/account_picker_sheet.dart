import 'package:flutter/material.dart';

import '../../theme.dart';
import '../accounts/account.dart';
import 'account_picker.dart';

/// Sub-account filter pills shown inside the dropdown sheet. `all` includes
/// savings; `bank` keeps savings + cash-bank rows; `ewallet` keeps only
/// cash-ewallet rows. Used only when `enableSubKindFilter` is true.
enum RecordAccountSubFilter { all, bank, ewallet }

/// Bottom sheet listing every account with optional Semua / Bank / E-wallet
/// filter pills. Pops with the selected account id.
class AccountSelectorSheet extends StatefulWidget {
  const AccountSelectorSheet({
    super.key,
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
  State<AccountSelectorSheet> createState() => _AccountSelectorSheetState();
}

class _AccountSelectorSheetState extends State<AccountSelectorSheet> {
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
