import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_lock.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../security/pin_sheets.dart';
import 'settings_row.dart';

/// Baris "Kunci aplikasi" (+ biometrik bila perangkat mendukung) di kartu
/// Akun & Keamanan. Default mati; PIN tersimpan ter-hash di
/// Keychain/Keystore. Disembunyikan di web.
class AppLockRows extends ConsumerWidget {
  const AppLockRows({super.key});

  Future<void> _toggleLock(
      BuildContext context, WidgetRef ref, bool turnOn) async {
    FtHaptics.select();
    final controller = ref.read(appLockProvider.notifier);
    if (turnOn) {
      final pin = await showPinSetupSheet(context);
      if (pin == null) return;
      await controller.enable(pin);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunci aplikasi aktif.')),
        );
      }
    } else {
      final ok = await showPinConfirmSheet(context);
      if (ok != true) return;
      await controller.disable();
    }
  }

  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool turnOn) async {
    FtHaptics.select();
    final controller = ref.read(appLockProvider.notifier);
    if (!turnOn) {
      await controller.setBiometric(false);
      return;
    }
    // Tes prompt dulu — kalau perangkat menolak/batal, jangan nyalakan.
    await controller.setBiometric(true);
    final ok = await controller.unlockWithBiometric();
    if (!ok) {
      await controller.setBiometric(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Biometrik tidak tersedia atau dibatalkan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppLockController.supported) return const SizedBox.shrink();
    final lock = ref.watch(appLockProvider);

    return Column(
      children: [
        Divider(height: 1, thickness: 0.5, color: FtColors.line),
        SettingsSwitchRow(
          label: 'Kunci aplikasi',
          detail: 'PIN 6 digit diminta setiap membuka app',
          value: lock.enabled,
          onChanged: (v) => _toggleLock(context, ref, v),
        ),
        if (lock.enabled)
          FutureBuilder<bool>(
            future:
                ref.read(appLockProvider.notifier).deviceSupportsAuth(),
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return Column(
                children: [
                  Divider(height: 1, thickness: 0.5, color: FtColors.line),
                  SettingsSwitchRow(
                    label: 'Buka dengan biometrik',
                    detail: 'Sidik jari / wajah, PIN tetap jadi cadangan',
                    value: lock.biometric,
                    onChanged: (v) => _toggleBiometric(context, ref, v),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
