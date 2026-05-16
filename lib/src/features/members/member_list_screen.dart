import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/household_repository.dart';
import '../household/name_format.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  String? _newInviteCode;
  bool _busy = false;

  Future<void> _createInvite(String householdId, String uid) async {
    setState(() => _busy = true);
    try {
      final code = await ref
          .read(householdRepositoryProvider)
          .createInvite(householdId: householdId, generatedBy: uid);
      setState(() => _newInviteCode = code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(String householdId, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari rumah tangga?'),
        content: const Text(
          'Kamu akan dikeluarkan dari rumah tangga ini. Data tetap ada untuk anggota lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(householdRepositoryProvider)
        .leave(householdId: householdId, userId: uid);
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const FtSubHeader(title: 'Anggota'),
            FtCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Rumah tangga'),
                  const SizedBox(height: 6),
                  Text(
                    household.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payday tanggal ${household.payday} • ${Money.format(household.monthlyBudgetTotal)} / siklus',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FtCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < household.members.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _MemberTile(
                      member: household.members[i],
                      isSelf: household.members[i].userId == user.uid,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_newInviteCode != null)
              _InviteCodeCard(
                code: _newInviteCode!,
                onClose: () => setState(() => _newInviteCode = null),
              )
            else
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _createInvite(household.id, user.uid),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Undang anggota baru'),
              ),
            const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _leave(household.id, user.uid),
            label: Text(
              'Keluar dari rumah tangga',
              style: TextStyle(color: FtColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isSelf});
  final Member member;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final pretty = prettyName(member.displayName);
    final initial = pretty.isNotEmpty ? pretty[0].toUpperCase() : '?';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _parseColor(member.color),
        child: Text(initial, style: const TextStyle(color: Colors.white)),
      ),
      title: Text(pretty + (isSelf ? ' (kamu)' : '')),
      subtitle: Text(roleToString(member.role)),
      trailing: member.isCreator
          ? const Chip(
              label: Text('Creator'),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code, required this.onClose});
  final String code;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      backgroundColor: const Color(0xFFE9D9C8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Kode undangan (sekali pakai)')),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          SelectableText(
            code,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: FtColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Kode disalin')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Salin'),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
