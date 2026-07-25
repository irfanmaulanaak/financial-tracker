import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'notification_providers.dart';

/// Notifications feed — `claude-design/screens-extras.jsx > NotificationsScreen`.
/// In-app only (no push). Sources: budget over-warnings, CC due in ≤5 days,
/// goal milestones, recent member spend.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationsProvider);
    final fresh =
        feed.where((n) => n.group == NotificationGroup.fresh).toList();
    final week =
        feed.where((n) => n.group == NotificationGroup.thisWeek).toList();

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Notifikasi',
              trailing: feed.isEmpty
                  ? null
                  : _ClearButton(
                      onTap: () => _confirmClear(context, ref),
                    ),
            ),
            Expanded(
              child: FtRefreshable(
                onRefresh: () async {
                  ref.invalidate(currentHouseholdProvider);
                  ref.invalidate(notificationsProvider);
                  await ftRefreshDelay();
                },
                child: feed.isEmpty
                    ? ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.6,
                            child: _Empty(),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        children: [
                          if (fresh.isNotEmpty) _Group(label: 'Baru', items: fresh),
                          if (week.isNotEmpty)
                            _Group(label: 'Minggu ini', items: week),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bersihkan notifikasi?'),
        content: const Text(
          'Semua notifikasi saat ini akan disembunyikan. Notifikasi baru tetap muncul jika ada kejadian baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(clearNotificationsProvider)();
      FtHaptics.success();
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal membersihkan notifikasi');
      }
    }
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: FtColors.ink2,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: const Text(
        'Bersihkan',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 36, color: FtColors.ink4),
            const SizedBox(height: 10),
            Text(
              'Belum ada notifikasi',
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pemberitahuan anggaran, jatuh tempo kartu, dan aktivitas keluarga akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FtColors.ink3, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.items});
  final String label;
  final List<AppNotification> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
          child: Eyebrow(label),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _Item(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item});
  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(item.kind);
    return FtTapScale(
      scale: 0.99,
      onTap: item.route != null ? () => context.push(item.route!) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tone.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tone.color.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(tone.icon, size: 16, color: tone.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _ago(item.ts),
                        style: TextStyle(
                          fontSize: 10,
                          color: FtColors.ink4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.detail,
                    style: TextStyle(
                      fontSize: 11,
                      color: FtColors.ink3,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tone {
  const _Tone(this.color, this.icon);
  final Color color;
  final IconData icon;
}

_Tone _toneFor(NotificationKind kind) => switch (kind) {
      NotificationKind.overBudget =>
        _Tone(FtColors.danger, Icons.warning_amber_rounded),
      NotificationKind.dueSoon =>
        _Tone(FtColors.ochre, Icons.account_balance_rounded),
      NotificationKind.goalMilestone =>
        _Tone(FtColors.clay, Icons.flag_rounded),
      NotificationKind.memberSpend =>
        _Tone(FtColors.clay, Icons.shopping_bag_outlined),
      NotificationKind.investmentStale =>
        _Tone(FtColors.clay, Icons.trending_up_rounded),
    };

String _ago(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inMinutes < 1) return 'baru';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}j';
  if (diff.inDays < 7) return '${diff.inDays}h';
  return '${(diff.inDays / 7).floor()}m'; // weeks
}
