import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reminders.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_ui.dart';

/// Pengaturan → Pengingat. All reminders are local notifications on this
/// device only (opt-in, no server). Hidden on web where scheduled local
/// notifications aren't supported.
class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings next, {
    required bool turningOn,
  }) async {
    FtHaptics.select();
    if (turningOn) {
      final ok =
          await ref.read(reminderServiceProvider).requestPermission();
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Izin notifikasi ditolak. Aktifkan lewat pengaturan sistem.'),
            ),
          );
        }
        return;
      }
    }
    await ref.read(reminderSettingsProvider.notifier).update(next);
  }

  Future<void> _pickTime(
      BuildContext context, WidgetRef ref, ReminderSettings s) async {
    FtHaptics.select();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.dailyHour, minute: s.dailyMinute),
      helpText: 'Jam pengingat harian',
    );
    if (picked == null) return;
    await ref.read(reminderSettingsProvider.notifier).update(
          s.copyWith(dailyHour: picked.hour, dailyMinute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ReminderService.supported) return const SizedBox.shrink();
    final s = ref.watch(reminderSettingsProvider);
    final timeLabel =
        '${s.dailyHour.toString().padLeft(2, '0')}.${s.dailyMinute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: Eyebrow('Pengingat'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SwitchRow(
                label: 'Catat harian',
                detail: 'Pengingat jam $timeLabel bila hari ini belum catat',
                value: s.daily,
                onChanged: (v) => _toggle(
                  context,
                  ref,
                  s.copyWith(daily: v),
                  turningOn: v,
                ),
                trailing: s.daily
                    ? GestureDetector(
                        onTap: () => _pickTime(context, ref, s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: FtColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: FtColors.line, width: 0.5),
                          ),
                          child: Text(
                            timeLabel,
                            style: TextStyle(
                              color: FtColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              Divider(height: 1, thickness: 0.5, color: FtColors.line),
              _SwitchRow(
                label: 'Jatuh tempo kartu',
                detail: 'Diingatkan 3 hari sebelum & saat jatuh tempo',
                value: s.cardDue,
                onChanged: (v) => _toggle(
                  context,
                  ref,
                  s.copyWith(cardDue: v),
                  turningOn: v,
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: FtColors.line),
              _SwitchRow(
                label: 'Tagihan rutin',
                detail: 'Diingatkan sehari sebelum tagihan bulanan biasanya',
                value: s.recurringBills,
                onChanged: (v) => _toggle(
                  context,
                  ref,
                  s.copyWith(recurringBills: v),
                  turningOn: v,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Text(
                  'Pengingat bersifat lokal di perangkat ini — tidak ada data yang dikirim ke server.',
                  style: TextStyle(
                      color: FtColors.ink4, fontSize: 10.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 8),
          ],
          Switch.adaptive(
            value: value,
            activeTrackColor: FtColors.clay,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
