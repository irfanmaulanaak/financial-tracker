import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../home/widgets/home_formatters.dart';
import '../home/widgets/recent_list.dart';
import '../household/household.dart';
import '../household/name_format.dart';

/// "Aktivitas" below the calendar on `/spend` — transactions of the selected
/// cycle, newest first. A top-right filter narrows to one spender; the list
/// pages in batches of [_pageSize]. Rows open the expense detail sheet.
class SpendActivityList extends StatefulWidget {
  const SpendActivityList({
    super.key,
    required this.expenses,
    required this.household,
  });

  /// Already filtered to the cycle picked in the period chips.
  final List<Expense> expenses;
  final Household household;

  @override
  State<SpendActivityList> createState() => _SpendActivityListState();
}

class _SpendActivityListState extends State<SpendActivityList> {
  static const _pageSize = 8;

  /// `null` = all members.
  String? _filterMemberId;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) return const SizedBox.shrink();

    final filtered = [
      for (final e in widget.expenses)
        if (_filterMemberId == null || e.spentBy == _filterMemberId) e,
    ]..sort((a, b) => b.date.compareTo(a.date));

    final totalPages = math.max(1, (filtered.length / _pageSize).ceil());
    // Cycle/filter changes can shrink the list — clamp so we never strand the
    // user on an empty page.
    final page = _page.clamp(0, totalPages - 1);
    final start = page * _pageSize;
    final pageItems = filtered.sublist(
      start,
      math.min(start + _pageSize, filtered.length),
    );

    final selectedMember = _filterMemberId == null
        ? null
        : widget.household.memberOf(_filterMemberId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Eyebrow('Aktivitas · ${filtered.length} transaksi'),
              ),
              _MemberFilter(
                members: widget.household.members,
                selected: selectedMember,
                onPick: (id) => setState(() {
                  _filterMemberId = id;
                  _page = 0;
                }),
              ),
            ],
          ),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
          padding: EdgeInsets.zero,
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    'Tidak ada transaksi untuk anggota ini.',
                    style: TextStyle(color: FtColors.ink3, fontSize: 12),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < pageItems.length; i++)
                      ExpenseActivityRow(
                        expense: pageItems[i],
                        category: widget.household
                            .categoryOf(pageItems[i].categoryId),
                        spender:
                            widget.household.memberOf(pageItems[i].spentBy),
                        showTopBorder: i > 0,
                      ),
                  ],
                ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: _Pager(
              page: page,
              totalPages: totalPages,
              onPrev: page > 0 ? () => setState(() => _page = page - 1) : null,
              onNext: page < totalPages - 1
                  ? () => setState(() => _page = page + 1)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Top-right "filter by spender" pill → popup menu of "Semua" + each member.
class _MemberFilter extends StatelessWidget {
  const _MemberFilter({
    required this.members,
    required this.selected,
    required this.onPick,
  });

  final List<Member> members;
  final Member? selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    final label =
        selected == null ? 'Semua' : prettyName(selected!.displayName);
    final color = selected == null ? null : parseColor(selected!.color);
    return PopupMenuButton<String>(
      tooltip: 'Saring per anggota',
      position: PopupMenuPosition.under,
      onSelected: (v) => onPick(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        _item('', 'Semua Anggota', null, selected == null),
        for (final m in members)
          _item(m.userId, prettyName(m.displayName), parseColor(m.color),
              selected?.userId == m.userId),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(Icons.people_alt_rounded, size: 13, color: FtColors.ink3),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: FtColors.ink3),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(
      String value, String label, Color? dot, bool active) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          if (dot != null)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.people_alt_rounded,
                  size: 14, color: FtColors.ink3),
            ),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          if (active)
            Icon(Icons.check_rounded, size: 16, color: FtColors.ink),
        ],
      ),
    );
  }
}

/// Prev/next + "Hal x dari y" pager for the activity list.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PagerButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: FtFadeUp(
            key: ValueKey(page),
            duration: const Duration(milliseconds: 200),
            distance: 3,
            child: Text(
              'Hal ${page + 1} dari $totalPages',
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        _PagerButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return FtTapScale(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: FtColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? FtColors.ink2 : FtColors.ink4,
        ),
      ),
    );
  }
}
