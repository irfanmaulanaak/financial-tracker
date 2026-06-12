import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme_provider.dart';
import '../../theme.dart';
import '../../ui/ft_action_sheet.dart';
import '../../ui/ft_ui.dart';

/// Preview tema Liquid Glass — debug only, tanpa auth (`/dev/liquid`).
/// Berisi konten dummy untuk menguji kaca: kartu warna-warni yang discroll
/// di bawah nav, toggle liquid/gelap, dan sheet contoh.
class LiquidPreviewScreen extends ConsumerWidget {
  const LiquidPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liquid = ref.watch(liquidThemeProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      body: FtAppChrome(
        current: FtTab.home,
        showActionFab: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 140),
          children: [
            Text('Liquid Glass Lab',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            FtCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Kontrol'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Liquid Glass',
                            style: TextStyle(color: FtColors.ink)),
                      ),
                      Switch.adaptive(
                        value: liquid,
                        activeTrackColor: FtColors.clay,
                        onChanged: (v) => ref
                            .read(liquidThemeProvider.notifier)
                            .setLiquid(v),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Mode gelap',
                            style: TextStyle(color: FtColors.ink)),
                      ),
                      Switch.adaptive(
                        value: mode == ThemeMode.dark,
                        activeTrackColor: FtColors.clay,
                        onChanged: (v) => ref
                            .read(themeModeProvider.notifier)
                            .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => showFtActionSheet<void>(
                      context: context,
                      builder: (_) => const _DummySheet(),
                    ),
                    child: const Text('Buka sheet kaca'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 12; i++) ...[
              FtCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accent(i).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.auto_awesome, color: _accent(i)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Konten dummy ${i + 1}',
                              style: TextStyle(
                                  color: FtColors.ink,
                                  fontWeight: FontWeight.w600)),
                          Text('Scroll aku ke bawah nav kaca',
                              style: TextStyle(
                                  color: FtColors.ink3, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('Rp${(i + 1) * 25}rb',
                        style: TextStyle(color: _accent(i))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Color _accent(int i) => [
        FtColors.clay,
        FtColors.sky,
        FtColors.ochre,
        FtColors.sage,
        FtColors.plum,
      ][i % 5];
}

class _DummySheet extends StatelessWidget {
  const _DummySheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Sheet kaca'),
          const SizedBox(height: 10),
          Text(
            'Sheet ini memakai FtGlass dengan animateIn — blur dan tint '
            'naik saat muncul, wallpaper terlihat menekuk di tepinya.',
            style: TextStyle(color: FtColors.ink2, height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
