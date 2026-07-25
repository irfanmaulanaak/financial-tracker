import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_lock.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_keypad.dart';
import '../auth/auth_repository.dart';

/// Layar kunci full-screen — dirender di atas seluruh app oleh AppLockGate.
/// PIN 6 digit; bila biometrik aktif, prompt otomatis saat tampil.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _error = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(appLockProvider);
      if (s.biometric) {
        // ignore: discarded_futures
        ref.read(appLockProvider.notifier).unlockWithBiometric();
      }
    });
  }

  Future<void> _onKey(String? key) async {
    if (_checking) return;
    setState(() {
      _error = false;
      if (key == null) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < appLockPinLength) {
        _pin += key;
      }
    });
    if (_pin.length < appLockPinLength) return;

    _checking = true;
    final ok = await ref.read(appLockProvider.notifier).verifyPin(_pin);
    if (!mounted) return;
    _checking = false;
    if (!ok) {
      FtHaptics.warning();
      setState(() {
        _pin = '';
        _error = true;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar akun?'),
        content: const Text(
            'Lupa PIN? Keluar akan menghapus kunci aplikasi di perangkat ini. '
            'Masuk lagi membutuhkan email/akun Google seperti biasa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(appLockProvider.notifier).disable();
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final biometric = ref.watch(appLockProvider.select((s) => s.biometric));
    return Material(
      color: FtColors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'FinSist',
                style: TextStyle(
                  fontFamily: 'Newsreader',
                  fontSize: 28,
                  color: FtColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error ? 'PIN salah. Coba lagi.' : 'Masukkan PIN',
                style: TextStyle(
                  color: _error ? FtColors.danger : FtColors.ink3,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              _PinDots(filled: _pin.length, error: _error),
              const Spacer(),
              FtKeypad(pinMode: true, onKey: _onKey),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Keluar akun',
                      style: TextStyle(color: FtColors.ink3, fontSize: 12),
                    ),
                  ),
                  if (biometric)
                    IconButton(
                      onPressed: () => ref
                          .read(appLockProvider.notifier)
                          .unlockWithBiometric(),
                      icon: Icon(Icons.fingerprint_rounded,
                          size: 28, color: FtColors.ink),
                      tooltip: 'Buka dengan biometrik',
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.error});

  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < appLockPinLength; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled
                  ? (error ? FtColors.danger : FtColors.ink)
                  : Colors.transparent,
              border: Border.all(
                color: error ? FtColors.danger : FtColors.lineStrong,
                width: 1,
              ),
            ),
          ),
      ],
    );
  }
}
