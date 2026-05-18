import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/household/household_providers.dart';
import '../theme.dart';
import 'ft_breakpoints.dart';
import 'ft_haptics.dart';
import 'ft_motion.dart';

/// Bottom sheet primitive — warm cream surface, rounded top, grabber handle.
/// Animates in from below; backdrop dim layered above content.
/// Bottom sheet primitive — warm cream surface, rounded top, grabber handle.
/// Animates in from below; backdrop dim layered above content.
///
/// On `medium`+ breakpoints, automatically switches to a centered dialog
/// (max 560 dp) so wide-screen layouts don't show a sheet stretched across
/// 1920 px of empty space.
Future<T?> showFtActionSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  FtHaptics.select();
  if (context.isAtLeastMedium) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: FtColors.bg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: FtColors.line, width: 0.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
                  child: FtFadeUp(
                    duration: const Duration(milliseconds: 260),
                    distance: 8,
                    child: SingleChildScrollView(
                      child: builder(ctx),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (ctx) {
      final viewInsets = MediaQuery.viewInsetsOf(ctx);
      final padding = MediaQuery.paddingOf(ctx);
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: FtColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(top: 10, bottom: padding.bottom + 18),
          child: SafeArea(
            top: false,
            bottom: false,
            child: FtFadeUp(
              duration: const Duration(milliseconds: 260),
              distance: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Grabber(),
                  Flexible(child: builder(ctx)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: FtColors.lineStrong,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// "Catat aktivitas" chooser — Pengeluaran / Pemasukan / Sesuaikan Aset.
/// Mirrors `ActionChooserSheet` from `claude-design/screens-actions.jsx`.
///
/// Filters its options against the signed-in member's access tier:
/// - `view` accounts see no write options (sheet is blocked at the FAB
///   wrapper; this widget renders a hint just in case).
/// - `limited` accounts see expense + income only (no asset adjust).
/// - `full` accounts see everything.
class ActionChooserSheet extends ConsumerWidget {
  const ActionChooserSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showFtActionSheet<void>(
      context: context,
      builder: (_) => const ActionChooserSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canTxn = ref.watch(canRecordTxnProvider);
    final canFull = ref.watch(canWriteAllProvider);

    final actions = <_Action>[
      if (canTxn)
        _Action(
          label: 'Catat Pengeluaran',
          detail: 'Tunai · Debit · Kartu Kredit · Cicilan',
          icon: Icons.south_west_rounded,
          color: FtColors.clay,
          route: '/expenses/new',
        ),
      if (canTxn)
        _Action(
          label: 'Catat Pemasukan',
          detail: 'Gaji · Freelance · Lainnya',
          icon: Icons.north_east_rounded,
          color: FtColors.moss,
          route: '/incomes/new',
        ),
      if (canFull)
        _Action(
          label: 'Sesuaikan Aset',
          detail: 'Update saldo rekening atau tabungan',
          icon: Icons.tune_rounded,
          color: FtColors.sky,
          route: '/accounts',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 4, 6, 12),
            child: Eyebrow('Catat Aktivitas'),
          ),
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
              child: Text(
                'Akun ini hanya bisa melihat ringkasan. Hubungi pengelola rumah tangga untuk mengubah akses.',
                style: TextStyle(
                  color: FtColors.ink3,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          for (final a in actions) ...[
            _ActionTile(action: a),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Action {
  const _Action({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.route,
  });
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final String route;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.985,
      onTap: () {
        Navigator.of(context).pop();
        FtHaptics.tap();
        // Small delay so the sheet's dismiss animation finishes first.
        Future.delayed(const Duration(milliseconds: 60), () {
          if (context.mounted) context.push(action.route);
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: action.color.withValues(alpha: 0.24),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(action.icon, size: 20, color: action.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'Newsreader',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: FtColors.ink,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.detail,
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: FtColors.ink4,
            ),
          ],
        ),
      ),
    );
  }
}
