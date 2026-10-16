import 'dart:async';

import 'package:financial_tracker/src/features/home/eling/eling_mood.dart';
import 'package:financial_tracker/src/features/home/eling/eling_scene.dart';
import 'package:financial_tracker/src/features/home/home_data_synced.dart';
import 'package:financial_tracker/src/features/home/widgets/home_hero_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness(
  int perDay, {
  bool reduce = false,
  Stream<bool>? synced,
  bool inputsReady = true,
}) {
  return ProviderScope(
    overrides: [
      homeDataSyncedProvider
          .overrideWith((ref) => synced ?? Stream.value(true)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: SingleChildScrollView(
            child: HomeHeroScene(
              perDay: perDay,
              remaining: 5800000,
              daysLeft: 14,
              hasBudget: true,
              mood: ElingMood.senang,
              daysElapsed: 16,
              cycleLength: 30,
              insightCandidate: null,
              startLabel: '30 Sep',
              paydayLabel: 'Gajian 30 Okt',
              inputsReady: inputsReady,
            ),
          ),
        ),
      ),
    ),
  );
}

bool _richTextHas(String needle) => find
    .byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains(needle))
    .evaluate()
    .isNotEmpty;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    ElingSession.entrancePlayed = false;
    ElingSession.settledOnce = false;
  });

  testWidgets('waits for server sync before showing the number',
      (tester) async {
    final synced = StreamController<bool>();
    addTearDown(synced.close);

    await tester.pumpWidget(_harness(414000, reduce: true, synced: synced.stream));
    await tester.pump();
    // Not synced yet: no number.
    expect(_richTextHas('414'), isFalse);

    // Server data arrives → the 700ms settle starts, still no number yet.
    synced.add(true);
    await tester.pump(); // stream event reaches the provider
    await tester.pump(); // the hero rebuilds with synced = true
    await tester.pump(const Duration(milliseconds: 300));
    expect(_richTextHas('414'), isFalse);

    // Past the settle window: the number shows.
    await tester.pump(const Duration(milliseconds: 500));
    expect(_richTextHas('414'), isTrue);
  });

  testWidgets('waits for the hero inputs to load before showing the number',
      (tester) async {
    // Synced from the server, but the late providers (cards, installments,
    // obligations, stable salary) haven't landed yet.
    await tester.pumpWidget(_harness(414000, reduce: true, inputsReady: false));
    await tester.pump(); // let the (synced) provider value reach the hero
    await tester.pump(const Duration(milliseconds: 800)); // past the settle
    expect(_richTextHas('414'), isFalse);

    // Inputs finish loading → the settle starts.
    await tester.pumpWidget(_harness(414000, reduce: true, inputsReady: true));
    await tester.pump(); // the hero rebuilds with inputsReady = true
    await tester.pump(const Duration(milliseconds: 300));
    expect(_richTextHas('414'), isFalse);

    // Past the settle window: the number shows.
    await tester.pump(const Duration(milliseconds: 500));
    expect(_richTextHas('414'), isTrue);
  });

  testWidgets('entrance waits until the inputs settle (debounced)',
      (tester) async {
    await tester.pumpWidget(_harness(100000));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(_harness(200000)); // change 1
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(_harness(300000)); // change 2, within 300ms

    // 600ms after the last change (< 700ms settle): nothing shown yet.
    await tester.pump(const Duration(milliseconds: 600));
    expect(_richTextHas('300'), isFalse);

    // Past the settle window: the number appears and counts up to 300 rb.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));
    expect(_richTextHas('300'), isTrue);
  });

  testWidgets('reduce motion: shows the number and mood bubble, tap swaps it',
      (tester) async {
    await tester.pumpWidget(_harness(414000, reduce: true));
    // Let the (already synced) provider value reach the hero first.
    await tester.pump();
    // Still debounced even under reduce motion — let the inputs settle.
    await tester.pump(const Duration(milliseconds: 750));

    // The big safe-to-spend number (shown instantly, no count-up).
    expect(_richTextHas('414'), isTrue);

    // Resting bubble shows the Senang mood line.
    expect(find.text('Hari ini masih aman.'), findsOneWidget);

    // Tapping Eling swaps the bubble to the tap line.
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(
      find.text('Hihi, geli! Hari ini masih aman, Rp414 rb lagi ya.'),
      findsOneWidget,
    );

    // Let the 1.5s revert timer fire so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Hari ini masih aman.'), findsOneWidget);
  });
}
