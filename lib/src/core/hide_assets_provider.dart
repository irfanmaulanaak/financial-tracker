import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Shared preference for masking asset balances on the asset hero cards
/// (Home Layout A, Home Layout B, Accounts). Default is hidden so balances
/// are private on first launch; user can reveal via the eye toggle.
final hideAssetsProvider = NotifierProvider<HideAssetsNotifier, bool>(
  HideAssetsNotifier.new,
);

class HideAssetsNotifier extends Notifier<bool> {
  static const _key = 'hide_assets';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_key);
    if (v != null) state = v;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

/// Small eye icon button used inside asset hero cards. Tap flips the
/// shared [hideAssetsProvider]; icon mirrors current state.
class HideAssetsEye extends ConsumerWidget {
  const HideAssetsEye({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    return InkResponse(
      onTap: () => ref.read(hideAssetsProvider.notifier).toggle(),
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: size,
          color: FtColors.ink3,
        ),
      ),
    );
  }
}

