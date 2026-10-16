import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout_provider.dart';
import '../../../core/theme_provider.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import 'settings_row.dart';

/// "Tampilan" section: Mode, Warna, Menu bawah, Beranda, Liquid Glass.
/// Every option is opt-in — the defaults match the original look exactly.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(paletteProvider);
    final navStyle = ref.watch(bottomNavStyleProvider);
    final homeLayout = ref.watch(homeLayoutProvider);
    final liquid = ref.watch(liquidThemeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: Eyebrow('Tampilan'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsSegmentedRow<ThemeMode>(
                label: 'Mode',
                options: const [
                  ('Terang', ThemeMode.light),
                  ('Gelap', ThemeMode.dark),
                ],
                value: themeMode == ThemeMode.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
                onChanged: (v) =>
                    ref.read(themeModeProvider.notifier).setTheme(v),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Warna',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final p in FtPalette.values)
                          _PaletteSwatch(
                            palette: p,
                            active: p == palette,
                            onTap: () => ref
                                .read(paletteProvider.notifier)
                                .setPalette(p),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SettingsSegmentedRow<FtNavStyle>(
                label: 'Menu bawah',
                options: const [
                  ('Melayang', FtNavStyle.floating),
                  ('Menempel', FtNavStyle.fixed),
                ],
                value: navStyle,
                onChanged: (v) =>
                    ref.read(bottomNavStyleProvider.notifier).setStyle(v),
              ),
              const Divider(height: 1),
              SettingsSegmentedRow<FtHomeLayout>(
                label: 'Beranda',
                options: const [
                  ('Lengkap', FtHomeLayout.lengkap),
                  ('Ringkas', FtHomeLayout.ringkas),
                ],
                value: homeLayout,
                hint: 'Ringkas hanya menampilkan aman dibelanjakan dan hal '
                    'yang perlu perhatian.',
                onChanged: (v) =>
                    ref.read(homeLayoutProvider.notifier).setLayout(v),
              ),
              const Divider(height: 1),
              SettingsSwitchRow(
                label: 'Liquid Glass',
                detail: 'Tampilan kaca + background hidup (eksperimen)',
                value: liquid,
                trailing: const _BetaBadge(),
                onChanged: (v) =>
                    ref.read(liquidThemeProvider.notifier).setLiquid(v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.active,
    required this.onTap,
  });

  final FtPalette palette;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = FtColors.previewSwatch(palette);
    return FtTapScale(
      scale: 0.95,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: preview.accent,
              border: Border.all(
                color: active ? FtColors.ink : FtColors.line,
                width: active ? 2.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: active
                ? Icon(Icons.check_rounded, size: 18, color: preview.onAccent)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            palette.label,
            style: TextStyle(
              fontSize: 11,
              color: active ? FtColors.ink : FtColors.ink3,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: FtColors.clay.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: FtColors.clay.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        'BETA',
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
          color: FtColors.clay,
        ),
      ),
    );
  }
}
