import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reminders.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_ui.dart';
import 'settings_row.dart';

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
              SettingsSwitchRow(
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
              SettingsSwitchRow(
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
              SettingsSwitchRow(
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
              Divider(height: 1, thickness: 0.5, color: FtColors.line),
              SettingsSwitchRow(
                label: 'Rekap mingguan',
                detail: 'Sekali tiap Minggu sore. Ajakan lihat ringkasan',
                value: s.weeklyRecap,
                onChanged: (v) => _toggle(
                  context,
                  ref,
                  s.copyWith(weeklyRecap: v),
                  turningOn: v,
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: FtColors.line),
              SettingsSwitchRow(
                label: 'Money date akhir siklus',
                detail: 'Ajakan review bareng 2 hari sebelum gajian',
                value: s.moneyDate,
                onChanged: (v) => _toggle(
                  context,
                  ref,
                  s.copyWith(moneyDate: v),
                  turningOn: v,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Text(
                  'Pengingat bersifat lokal di perangkat ini. Tidak ada data yang dikirim ke server.',
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
