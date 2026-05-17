import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';
import '../../household/name_format.dart';

/// Members section card from `claude-design/screens-household.jsx`.
/// Lists family members with role + access tier, badges for creator and
/// pending invites (future), plus the inline "Undang Anggota" CTA.
///
/// Tapping a member row pushes `/members/<uid>`.
class MembersSection extends StatelessWidget {
  const MembersSection({
    super.key,
    required this.household,
    required this.currentUid,
    required this.onInvite,
  });

  final Household household;
  final String currentUid;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Eyebrow('Anggota Keluarga'),
          ),
          FtCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < household.members.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MemberRow(
                    member: household.members[i],
                    isMe: household.members[i].userId == currentUid,
                    onTap: () =>
                        context.push('/members/${household.members[i].userId}'),
                  ),
                ],
                const Divider(height: 1),
                _InviteCta(onTap: onInvite),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Anggota dengan akses penuh dapat mencatat pengeluaran, melihat saldo, dan menerima notifikasi anggaran bersama.',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onTap,
  });
  final Member member;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.99,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: parseColor(member.color),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initialsOf(member.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isMe
                              ? '${prettyName(member.displayName)} · Saya'
                              : prettyName(member.displayName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${roleToString(member.role)} · ${accessLevelLabel(member.accessLevel)}',
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (member.isCreator) ...[
              const SizedBox(width: 8),
              _Badge(
                label: 'CREATOR',
                color: FtColors.clay,
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded,
                size: 16, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InviteCta extends StatelessWidget {
  const _InviteCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FtColors.clay.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: FtColors.clay, width: 0.5),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add_rounded, size: 18, color: FtColors.clay),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Undang Anggota Keluarga',
                style: TextStyle(
                  color: FtColors.clay,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
