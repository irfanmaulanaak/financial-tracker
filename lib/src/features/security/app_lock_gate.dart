import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_lock.dart';
import '../../theme.dart';
import 'lock_screen.dart';

/// Membungkus seluruh app (dipasang di MaterialApp.builder):
/// - sebelum settings terbaca → layar polos (hindari flash konten saat
///   cold start dengan kunci aktif)
/// - terkunci → LockScreen menutupi semua route
/// - app masuk background → kunci ulang (bila fitur aktif)
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(appLockProvider.notifier).lockFromLifecycle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    if (!lock.loaded) {
      return ColoredBox(color: FtColors.bg);
    }
    return Stack(
      children: [
        widget.child,
        if (lock.locked) const LockScreen(),
      ],
    );
  }
}
