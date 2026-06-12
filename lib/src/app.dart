import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme_provider.dart';
import 'features/security/app_lock_gate.dart';
import 'router.dart';
import 'theme.dart';
import 'ui/ft_liquid_background.dart';

/// Brightness terakhir yang diterapkan ke statics `FtColors` — pendeteksi
/// perubahan yang datang tanpa lewat toggle (mis. OS flip saat ThemeMode.system).
Brightness? _appliedBrightness;

class FinancialTrackerApp extends ConsumerWidget {
  const FinancialTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final liquid = ref.watch(liquidThemeProvider);

    // FtColors is consumed statically, so Theme's InheritedWidget alone
    // doesn't reach widgets that never look at it. Force a one-off rebuild of
    // the whole tree on every theme flip (also covers the async pref load at
    // startup when the stored theme is dark).
    ref.listen(themeModeProvider, (previous, next) {
      if (previous != next) ftRebuildAllWidgets();
    });
    ref.listen(liquidThemeProvider, (previous, next) {
      if (previous != next) ftRebuildAllWidgets();
    });

    return MaterialApp.router(
      title: 'FinSist',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, liquid: liquid),
      darkTheme: buildTheme(Brightness.dark, liquid: liquid),
      themeMode: themeMode,
      // Tanpa ini MaterialApp meng-crossfade tema 200ms: di frame pertama
      // `Theme.of(...).brightness` masih nilai LAMA, padahal rebuild global
      // dari listener di atas terjadi di frame itu juga → seluruh app
      // tergambar dengan warna lama dan baru benar setelah "refresh".
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Sync statics FtColors ke brightness TARGET (resolusi themeMode),
        // bukan `Theme.of(context)` yang bisa tertinggal saat transisi.
        // Kedua `buildTheme()` di atas juga meninggalkan statics di `dark`
        // setiap build, jadi selalu di-assert ulang di sini.
        final resolved = switch (themeMode) {
          ThemeMode.dark => Brightness.dark,
          ThemeMode.light => Brightness.light,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        if (_appliedBrightness != null && _appliedBrightness != resolved) {
          // Flip yang tidak lewat listener themeModeProvider (mis. OS ganti
          // gelap saat mode system) — jadwalkan repaint global setelah frame
          // ini supaya konsumen statics tidak menampilkan warna basi.
          WidgetsBinding.instance
              .addPostFrameCallback((_) => ftRebuildAllWidgets());
        }
        _appliedBrightness = resolved;
        FtColors.setBrightness(resolved);
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          // Liquid beta: background blob global di belakang seluruh Navigator
          // (scaffold transparan saat liquid). No-op saat liquid OFF.
          child: FtLiquidBackground(
            child: AppLockGate(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
