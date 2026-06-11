import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme_provider.dart';
import 'router.dart';
import 'theme.dart';

class FinancialTrackerApp extends ConsumerWidget {
  const FinancialTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // FtColors is consumed statically, so Theme's InheritedWidget alone
    // doesn't reach widgets that never look at it. Force a one-off rebuild of
    // the whole tree on every theme flip (also covers the async pref load at
    // startup when the stored theme is dark).
    ref.listen(themeModeProvider, (previous, next) {
      if (previous != next) ftRebuildAllWidgets();
    });

    return MaterialApp.router(
      title: 'FinSist',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Sync the static FtColors brightness to the live theme. Both
        // `theme:` and `darkTheme:` call `buildTheme()` at construction time
        // — the second call would otherwise leave `_brightness` stuck at
        // `dark` regardless of which theme is currently active.
        FtColors.setBrightness(Theme.of(context).brightness);
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
