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

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        // Status-bar safe; matches design's 54px on iOS frame.
        topInset > 0 ? topInset + 10 : 24,
        18,
        22,
      ),
      // Only what's needed every time: avatar + who's greeted, and the two
      // actions (notifications, menu). The member chip and "Pasang" install
      // action moved into the ⋯ menu — six things in one row was crowded and
      // squeezed the name into an ellipsis on narrow phones.
      child: Row(
        children: [
          _ProfileAvatar(displayName: displayName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink3,
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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: FtColors.ink,
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: FtColors.tileFor(FtColors.catFood),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(displayName),
        style: TextStyle(
          fontFeatures: const [FontFeature.tabularFigures()],
          fontSize: 14,
          color: FtColors.ink,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w800,
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
