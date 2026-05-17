import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense_providers.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/household_repository.dart';
import '../household/name_format.dart';
import 'widgets/access_picker_sheet.dart';
import 'widgets/member_detail_parts.dart';

/// Member detail — `claude-design/screens-profile.jsx > MemberDetailScreen`.
/// Shows member hero, contact info, access tier, this-cycle activity stats.
/// Creator-only destructive action: remove member.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final member = household.memberOf(memberId);
    if (member == null) return const _NotFoundView();

    final isMe = member.userId == user.uid;
    final iAmCreator = household.creatorId == user.uid;
    final cycleExpenses = ref.watch(cycleExpensesProvider).value ?? const [];
    final myExpenses = cycleExpenses.where((e) => e.spentBy == member.userId);
    final monthSpend =
        myExpenses.fold<int>(0, (a, e) => a + e.amount.toInt());
    final txnCount = myExpenses.length;

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const FtSubHeader(title: 'Detail Anggota'),
            MemberHero(member: member, isMe: isMe),
            MemberContactCard(member: member),
            MemberAccessCard(
              member: member,
              canEdit: iAmCreator && !isMe,
              onTap: () => _changeAccess(context, ref, household, member),
            ),
            MemberActivityCard(
              monthSpend: monthSpend,
              txnCount: txnCount,
              onTapAll: isMe ? null : () => context.push('/expenses'),
            ),
            const SizedBox(height: 14),
            if (isMe)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => context.push('/profile/edit'),
                  child: const Text('Edit Profil Saya'),
                ),
              ),
            if (!isMe && iAmCreator)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: OutlinedButton(
                  onPressed: () => _confirmRemove(
                    context,
                    ref,
                    household.id,
                    user.uid,
                    member,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FtColors.danger,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Keluarkan dari keluarga'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAccess(
    BuildContext context,
    WidgetRef ref,
    Household household,
    Member member,
  ) async {
    final picked =
        await AccessPickerSheet.show(context, current: member.accessLevel);
    if (picked == null || picked == member.accessLevel) return;
    try {
      await ref.read(householdRepositoryProvider).updateMemberAccess(
            householdId: household.id,
            actorUid: household.creatorId,
            memberUid: member.userId,
            accessLevel: picked,
          );
      FtHaptics.success();
    } catch (e) {
      FtHaptics.error();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    String actorUid,
    Member member,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Keluarkan ${prettyName(member.displayName)}?'),
        content: Text(
          '${prettyName(member.displayName)} akan kehilangan akses ke seluruh data. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FtColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, keluarkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(householdRepositoryProvider).removeMember(
            householdId: householdId,
            actorUid: actorUid,
            memberUid: member.userId,
          );
      FtHaptics.success();
      if (context.mounted) context.pop();
    } catch (e) {
      FtHaptics.error();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const FtSubHeader(title: 'Anggota tidak ditemukan'),
            const Spacer(),
            Center(
              child: Text(
                'Anggota sudah keluar atau telah dihapus.',
                style: TextStyle(color: FtColors.ink3, fontSize: 12),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
