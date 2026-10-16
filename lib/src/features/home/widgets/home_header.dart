import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/pwa_install.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_motion.dart';
import '../../household/household.dart';
import '../../household/name_format.dart';
import 'home_formatters.dart';
import 'home_header_ios_install_sheet.dart';

/// Greeting by time of day (DESIGN.md section 8): pagi before 11:00, siang
/// before 15:00, sore before 18:00, malam after. Pure for testability.
String greetingForHour(int hour) {
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.household,
    required this.displayName,
    required this.onSelected,
  });

  final Household household;
  final String displayName;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        // Status-bar safe; matches design's 54px on iOS frame.
        topInset > 0 ? topInset + 10 : 24,
        18,
        18,
      ),
      child: Row(
        children: [
          _MemberAvatars(members: household.members),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greetingForHour(DateTime.now().hour),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    // On the hero color — use onHero, not the page inks.
                    color: FtColors.onHero.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shortName(displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: FtColors.onHero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BellButton(),
          const SizedBox(width: 8),
          _OverflowMenu(onSelected: onSelected),
        ],
      ),
    );
  }
}

/// Overlapping member avatars (DESIGN.md section 8), using each member's own
/// color and initial. Caps at 3 circles so the row never crowds.
class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.members});
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();
    if (shown.isEmpty) return const SizedBox(width: 34, height: 34);
    return SizedBox(
      height: 34,
      width: 34.0 + (shown.length - 1) * 25,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 25.0,
              child: _Avatar(member: shown[i]),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final initial =
        initialsOf(member.displayName).characters.first.toUpperCase();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: parseColor(member.color),
        shape: BoxShape.circle,
        // Border matches the hero background the header now sits on, so the
        // overlapping avatars read as cut-outs.
        border: Border.all(color: FtColors.hero, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.92,
      onTap: () => context.push('/notifications'),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: FtColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.notifications_none_rounded,
          color: FtColors.ink2,
          size: 18,
        ),
      ),
    );
  }
}

/// Profile / overflow menu. Items kept short — most actions moved to bottom nav
/// or the central "+" chooser.
/// Also surfaces the PWA "Pasang" install action (web-only, when the browser
/// supports it) — moved here from a header pill so the header row only ever
/// shows the avatar/name plus these two buttons.
class _OverflowMenu extends StatefulWidget {
  const _OverflowMenu({required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  State<_OverflowMenu> createState() => _OverflowMenuState();
}

class _OverflowMenuState extends State<_OverflowMenu> {
  bool _canPrompt = false;
  bool _needsIos = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _refresh();
    // beforeinstallprompt fires async after page load — re-check a few
    // times during the first ~6 seconds so the item appears once Chrome
    // decides the site is installable.
    _poll = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (!mounted || t.tick > 4) {
        t.cancel();
        return;
      }
      _refresh();
    });
  }

  void _refresh() {
    final canPrompt = PwaInstall.canPrompt;
    final needsIos = PwaInstall.needsIosInstructions;
    if (canPrompt != _canPrompt || needsIos != _needsIos) {
      setState(() {
        _canPrompt = canPrompt;
        _needsIos = needsIos;
      });
    }
  }

  Future<void> _install() async {
    if (_canPrompt) {
      await PwaInstall.prompt();
      _refresh();
    } else if (_needsIos) {
      await showIosInstructions(context);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canInstall = _canPrompt || _needsIos;
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      iconSize: 20,
      splashRadius: 22,
      offset: const Offset(0, 46),
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: FtColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.more_horiz_rounded,
          color: FtColors.ink2,
          size: 18,
        ),
      ),
      onOpened: FtHaptics.select,
      onSelected: (v) {
        if (v == 'install') {
          _install();
        } else {
          widget.onSelected(v);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: FtColors.surface,
      itemBuilder: (_) => [
        if (canInstall)
          const PopupMenuItem(
            value: 'install',
            child: _MenuRow(
                icon: Icons.install_mobile_rounded, label: 'Pasang app'),
          ),
        const PopupMenuItem(
          value: 'insights',
          child: _MenuRow(
              icon: Icons.insights_rounded, label: 'Kesehatan Finansial'),
        ),
        PopupMenuItem(
          value: 'recap',
          child: _MenuRow(
              icon: Icons.auto_stories_rounded, label: 'Rekap Siklus'),
        ),
        PopupMenuItem(
          value: 'categories',
          child: _MenuRow(icon: Icons.category_rounded, label: 'Kategori'),
        ),
        PopupMenuItem(
          value: 'subscriptions',
          child: _MenuRow(
              icon: Icons.event_repeat_rounded, label: 'Langganan & Rutin'),
        ),
        PopupMenuItem(
          value: 'calendar',
          child: _MenuRow(
              icon: Icons.calendar_month_rounded, label: 'Kalender Tagihan'),
        ),
        PopupMenuItem(
          value: 'debts',
          child: _MenuRow(
              icon: Icons.handshake_outlined, label: 'Utang & Piutang'),
        ),
        PopupMenuItem(
          value: 'obligations',
          child: _MenuRow(
              icon: Icons.payments_outlined, label: 'Cicilan Tetap'),
        ),
        PopupMenuItem(
          value: 'members',
          child: _MenuRow(icon: Icons.group_rounded, label: 'Anggota'),
        ),
        PopupMenuItem(
          value: 'export',
          child: _MenuRow(icon: Icons.ios_share_rounded, label: 'Ekspor data'),
        ),
        PopupMenuItem(
          value: 'settings',
          child: _MenuRow(icon: Icons.settings_rounded, label: 'Pengaturan'),
        ),
        PopupMenuItem(
          value: 'onboarding',
          child: _MenuRow(icon: Icons.flag_outlined, label: 'Panduan Mulai'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: _MenuRow(
            icon: Icons.logout_rounded,
            label: 'Keluar akun',
            danger: true,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? FtColors.danger : FtColors.ink2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 13),
        ),
      ],
    );
  }
}
