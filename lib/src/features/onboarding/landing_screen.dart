import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: FtPageContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: 'Keluar',
                  onPressed: () async {
                    try {
                      await ref.read(authRepositoryProvider).signOut();
                    } catch (e) {
                      if (context.mounted) {
                        showFtErrorSnack(context, e, prefix: 'Gagal keluar');
                      }
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                ),
              ),
              const Spacer(),
              FtCard(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: FtColors.clay.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: FtColors.lineStrong,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 32,
                        color: FtColors.clay,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selamat datang!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat rumah tangga baru, atau gabung dengan kode undangan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: FtColors.ink3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/onboard/create'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Buat rumah tangga'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/onboard/join'),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Gabung dengan kode'),
              ),
              const Spacer(),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
