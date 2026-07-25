import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_lock.dart';
import '../../theme.dart';
import '../../ui/ft_action_sheet.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_keypad.dart';

/// Sheet setup PIN baru (masukkan → ulangi). Resolve dengan PIN final,
/// atau null bila dibatalkan.
Future<String?> showPinSetupSheet(BuildContext context) {
  return showFtActionSheet<String>(
    context: context,
    builder: (_) => const _PinSheet(mode: _PinSheetMode.setup),
  );
}

/// Sheet konfirmasi PIN yang sudah ada (untuk mematikan kunci).
/// Resolve true bila PIN benar; null bila dibatalkan.
Future<bool?> showPinConfirmSheet(BuildContext context) {
  return showFtActionSheet<bool>(
    context: context,
    builder: (_) => const _PinSheet(mode: _PinSheetMode.confirm),
  );
}

enum _PinSheetMode { setup, confirm }

class _PinSheet extends ConsumerStatefulWidget {
  const _PinSheet({required this.mode});

  final _PinSheetMode mode;

  @override
  ConsumerState<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends ConsumerState<_PinSheet> {
  String _pin = '';
  String? _firstPin; // setup: hasil tahap 1, menunggu konfirmasi
  bool _error = false;
  bool _checking = false;

  bool get _isRepeatStage => _firstPin != null;

  String get _title => switch (widget.mode) {
        _PinSheetMode.confirm => 'Masukkan PIN saat ini',
        _PinSheetMode.setup =>
          _isRepeatStage ? 'Ulangi PIN' : 'Buat PIN 6 digit',
      };

  String get _hint => switch (widget.mode) {
        _PinSheetMode.confirm => 'Untuk mematikan kunci aplikasi.',
        _PinSheetMode.setup => _isRepeatStage
            ? 'Masukkan PIN yang sama sekali lagi.'
            : 'PIN diminta setiap kali membuka aplikasi.',
      };

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

    switch (widget.mode) {
      case _PinSheetMode.setup:
        if (!_isRepeatStage) {
          setState(() {
            _firstPin = _pin;
            _pin = '';
          });
          return;
        }
        if (_pin == _firstPin) {
          FtHaptics.success();
          Navigator.of(context).pop(_pin);
        } else {
          FtHaptics.warning();
          setState(() {
            _firstPin = null;
            _pin = '';
            _error = true;
          });
        }
      case _PinSheetMode.confirm:
        _checking = true;
        final ok =
            await ref.read(appLockProvider.notifier).verifyPin(_pin);
        if (!mounted) return;
        _checking = false;
        if (ok) {
          Navigator.of(context).pop(true);
        } else {
          FtHaptics.warning();
          setState(() {
            _pin = '';
            _error = true;
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title,
            style: TextStyle(
              fontFamily: 'Newsreader',
              fontSize: 20,
              color: FtColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error
                ? (widget.mode == _PinSheetMode.confirm
                    ? 'PIN salah. Coba lagi.'
                    : 'PIN tidak sama. Mulai lagi.')
                : _hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _error ? FtColors.danger : FtColors.ink3,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < appLockPinLength; i++)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? (_error ? FtColors.danger : FtColors.ink)
                        : Colors.transparent,
                    border: Border.all(
                      color: _error ? FtColors.danger : FtColors.lineStrong,
                      width: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FtKeypad(pinMode: true, compact: true, onKey: _onKey),
        ],
      ),
    );
  }
}
