import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/providers.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';
import '../../household/household_providers.dart';
import '../expense.dart';
import '../expense_social.dart';

const _reactionEmojis = ['👍', '❤️', '😂', '😮', '🙏'];

/// Reaksi emoji + komentar untuk satu pengeluaran — dipakai di
/// [ExpenseDetailSheet]. Reaksi live dari doc pengeluaran; komentar live
/// dari subcollection `comments`.
class ExpenseSocialSection extends ConsumerStatefulWidget {
  const ExpenseSocialSection({
    super.key,
    required this.expense,
    required this.household,
  });

  final Expense expense;
  final Household household;

  @override
  ConsumerState<ExpenseSocialSection> createState() =>
      _ExpenseSocialSectionState();
}

class _ExpenseSocialSectionState extends ConsumerState<ExpenseSocialSection> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String get _hid => widget.household.id;
  String get _eid => widget.expense.id;

  Future<void> _react(String emoji, String? mine) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    FtHaptics.select();
    try {
      await ref.read(expenseSocialRepositoryProvider).toggleReaction(
            householdId: _hid,
            expenseId: _eid,
            uid: uid,
            emoji: emoji,
            current: mine,
          );
    } catch (e) {
      if (mounted) showFtErrorSnack(context, e, prefix: 'Gagal bereaksi');
    }
  }

  Future<void> _send() async {
    final uid = ref.read(authStateProvider).value?.uid;
    final text = _input.text.trim();
    if (uid == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(expenseSocialRepositoryProvider).addComment(
            householdId: _hid,
            expenseId: _eid,
            authorId: uid,
            text: text,
          );
      _input.clear();
      FtHaptics.success();
    } catch (e) {
      if (mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal mengirim komentar');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(ExpenseComment c) async {
    try {
      await ref.read(expenseSocialRepositoryProvider).deleteComment(
            householdId: _hid,
            expenseId: _eid,
            commentId: c.id,
          );
    } catch (e) {
      if (mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menghapus komentar');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final canTxn = ref.watch(canRecordTxnProvider);
    final live = ref
        .watch(expenseLiveProvider((hid: _hid, eid: _eid)))
        .value;
    final reactions = live?.reactions ?? widget.expense.reactions;
    final mine = uid == null ? null : reactions[uid];
    final counts = <String, int>{};
    for (final e in reactions.values) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final comments = ref
            .watch(expenseCommentsProvider((hid: _hid, eid: _eid)))
            .value ??
        const <ExpenseComment>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Reaksi & Komentar'),
        const SizedBox(height: 8),
        FtCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final emoji in _reactionEmojis) ...[
                    _ReactionChip(
                      emoji: emoji,
                      count: counts[emoji] ?? 0,
                      selected: mine == emoji,
                      enabled: canTxn,
                      onTap: () => _react(emoji, mine),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
              if (comments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(height: 0.5, color: FtColors.line),
                const SizedBox(height: 4),
                for (final c in comments)
                  _CommentRow(
                    comment: c,
                    author: widget.household.memberOf(c.authorId),
                    mine: c.authorId == uid,
                    onDelete: () => _delete(c),
                  ),
              ],
              if (canTxn) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLength: 280,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Tulis komentar…',
                          isDense: true,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: _sending ? FtColors.ink3 : FtColors.clay,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? FtColors.clay.withValues(alpha: 0.14)
              : FtColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? FtColors.clay : FtColors.line,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? FtColors.clay : FtColors.ink2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.author,
    required this.mine,
    required this.onDelete,
  });

  final ExpenseComment comment;
  final Member? author;
  final bool mine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author?.displayName ?? 'Anggota',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: author != null
                            ? parseColor(author!.color)
                            : FtColors.ink2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Dates.short(comment.createdAt),
                      style: TextStyle(fontSize: 10, color: FtColors.ink3),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: FtColors.ink,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (mine)
            FtTapScale(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.close, size: 14, color: FtColors.ink3),
              ),
            ),
        ],
      ),
    );
  }
}
