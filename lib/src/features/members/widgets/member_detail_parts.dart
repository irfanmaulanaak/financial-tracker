import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';
import '../../household/name_format.dart';

/// Hero section: large initials avatar + name + role + status pill.
class MemberHero extends StatelessWidget {
  const MemberHero({super.key, required this.member, required this.isMe});
  final Member member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(member.color);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initialsOf(member.displayName),
              style: const TextStyle(
                fontFamily: 'Newsreader',
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isMe
                ? '${prettyName(member.displayName)} · Anda'
                : prettyName(member.displayName),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 22, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                roleToString(member.role),
                style: TextStyle(color: FtColors.ink3, fontSize: 12),
              ),
              const SizedBox(width: 8),
              if (member.isCreator)
                _StatusPill(label: 'CREATOR', color: FtColors.clay)
              else
                _StatusPill(label: 'AKTIF', color: FtColors.moss),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
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

/// Contact info card with joined-date + role rows.
class MemberContactCard extends StatelessWidget {
  const MemberContactCard({super.key, required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Informasi Kontak'),
          const SizedBox(height: 8),
          FtCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Bergabung',
                  value: Dates.short(member.joinedAt),
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Peran',
                  value: roleToString(member.role),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: FtColors.ink3),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: FtColors.ink3, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Access tier card. When [canEdit] is true, renders an "Ubah" action.
class MemberAccessCard extends StatelessWidget {
  const MemberAccessCard({
    super.key,
    required this.member,
    required this.canEdit,
    required this.onTap,
  });

  final Member member;
  final bool canEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(member.color);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Tingkat Akses'),
          const SizedBox(height: 8),
          FtCard(
            margin: EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.shield_rounded, size: 16, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accessLevelLabel(member.accessLevel),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accessLevelDetail(member.accessLevel),
                        style: TextStyle(
                          color: FtColors.ink3,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  TextButton(
                    onPressed: onTap,
                    child: Text(
                      'Ubah',
                      style: TextStyle(
                        color: FtColors.clay,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Aktivitas Siklus Ini" — pengeluaran + jumlah tx for current cycle.
class MemberActivityCard extends StatelessWidget {
  const MemberActivityCard({
    super.key,
    required this.monthSpend,
    required this.txnCount,
    required this.onTapAll,
  });
  final int monthSpend;
  final int txnCount;
  final VoidCallback? onTapAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Aktivitas Siklus Ini'),
          const SizedBox(height: 8),
          FtCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'PENGELUARAN',
                        value: Money.format(monthSpend),
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'JUMLAH TRANSAKSI',
                        value: '$txnCount',
                        suffix: 'tx',
                      ),
                    ),
                  ],
                ),
                if (onTapAll != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: FtColors.line, width: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 14),
                    child: FtTapScale(
                      scale: 0.99,
                      onTap: onTapAll,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Lihat semua transaksi',
                              style: TextStyle(
                                color: FtColors.ink2,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 14, color: FtColors.ink4),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.suffix});
  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: FtColors.ink3,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'Newsreader',
              fontSize: 22,
              color: FtColors.ink,
              letterSpacing: -0.3,
            ),
            children: [
              if (suffix != null)
                TextSpan(
                  text: '  $suffix',
                  style: TextStyle(
                    fontFamily: null,
                    fontSize: 13,
                    color: FtColors.ink3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
