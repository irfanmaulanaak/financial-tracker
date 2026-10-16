import 'package:financial_tracker/src/core/layout_provider.dart';
import 'package:financial_tracker/src/core/theme_provider.dart';
import 'package:financial_tracker/src/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a container and lets the provider's initial (async) SharedPreferences
/// load settle before returning, so a later mutation in the same test never
/// races the notifier's own `build()`-triggered load.
Future<ProviderContainer> _settledContainer(
  void Function(ProviderContainer container) touch,
) async {
  final container = ProviderContainer();
  touch(container);
  await pumpEventQueue();
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('paletteProvider', () {
    test('defaults to daun when nothing stored', () async {
      final container = await _settledContainer((c) => c.read(paletteProvider));
      addTearDown(container.dispose);
      expect(container.read(paletteProvider), FtPalette.daun);
    });

    test('a saved palette (e.g. hangat) is kept', () async {
      SharedPreferences.setMockInitialValues({'ft_palette': 'hangat'});
      final container = await _settledContainer((c) => c.read(paletteProvider));
      addTearDown(container.dispose);
      expect(container.read(paletteProvider), FtPalette.hangat);
    });

    test('saves and reloads a chosen palette', () async {
      final container = await _settledContainer((c) => c.read(paletteProvider));
      addTearDown(container.dispose);
      await container.read(paletteProvider.notifier).setPalette(FtPalette.laut);
      expect(container.read(paletteProvider), FtPalette.laut);

      final reloaded = await _settledContainer((c) => c.read(paletteProvider));
      addTearDown(reloaded.dispose);
      expect(reloaded.read(paletteProvider), FtPalette.laut);
    });

    test('unknown stored value falls back to daun', () async {
      SharedPreferences.setMockInitialValues({'ft_palette': 'nonexistent'});
      final container = await _settledContainer((c) => c.read(paletteProvider));
      addTearDown(container.dispose);
      expect(container.read(paletteProvider), FtPalette.daun);
    });
  });

  group('bottomNavStyleProvider', () {
    test('defaults to fixed when nothing stored', () async {
      final container = await _settledContainer((c) => c.read(bottomNavStyleProvider));
      addTearDown(container.dispose);
      expect(container.read(bottomNavStyleProvider), FtNavStyle.fixed);
    });

    test('saves and reloads floating', () async {
      final container = await _settledContainer((c) => c.read(bottomNavStyleProvider));
      addTearDown(container.dispose);
      await container
          .read(bottomNavStyleProvider.notifier)
          .setStyle(FtNavStyle.floating);
      expect(container.read(bottomNavStyleProvider), FtNavStyle.floating);

      final reloaded = await _settledContainer((c) => c.read(bottomNavStyleProvider));
      addTearDown(reloaded.dispose);
      expect(reloaded.read(bottomNavStyleProvider), FtNavStyle.floating);
    });

    test('unknown stored value falls back to fixed', () async {
      SharedPreferences.setMockInitialValues({'nav_style': 'garbage'});
      final container = await _settledContainer((c) => c.read(bottomNavStyleProvider));
      addTearDown(container.dispose);
      expect(container.read(bottomNavStyleProvider), FtNavStyle.fixed);
    });
  });

  group('homeLayoutProvider', () {
    test('defaults to lengkap when nothing stored', () async {
      final container = await _settledContainer((c) => c.read(homeLayoutProvider));
      addTearDown(container.dispose);
      expect(container.read(homeLayoutProvider), FtHomeLayout.lengkap);
    });

    test('saves and reloads ringkas', () async {
      final container = await _settledContainer((c) => c.read(homeLayoutProvider));
      addTearDown(container.dispose);
      await container
          .read(homeLayoutProvider.notifier)
          .setLayout(FtHomeLayout.ringkas);
      expect(container.read(homeLayoutProvider), FtHomeLayout.ringkas);

      final reloaded = await _settledContainer((c) => c.read(homeLayoutProvider));
      addTearDown(reloaded.dispose);
      expect(reloaded.read(homeLayoutProvider), FtHomeLayout.ringkas);
    });

    test('unknown stored value falls back to lengkap', () async {
      SharedPreferences.setMockInitialValues({'home_layout': 'garbage'});
      final container = await _settledContainer((c) => c.read(homeLayoutProvider));
      addTearDown(container.dispose);
      expect(container.read(homeLayoutProvider), FtHomeLayout.lengkap);
    });
  });
}
