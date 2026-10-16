import 'dart:async';

import 'package:financial_tracker/src/features/home/home_data_synced.dart';
import 'package:flutter_test/flutter_test.dart';

/// A short wait to let queued stream events flush (acts as our "fake time").
Future<void> _tick([int ms = 10]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('stays false while every snapshot is cache-only', () async {
    final a = StreamController<bool>();
    final b = StreamController<bool>();
    final c = StreamController<bool>();
    final out = <bool>[];
    final sub = homeSyncedStream(
      [a.stream, b.stream, c.stream],
      fallback: const Duration(seconds: 10),
    ).listen(out.add);

    a.add(false);
    b.add(false);
    c.add(false);
    await _tick();

    expect(out, [false]); // initial false only; never flips on cache snapshots
    await sub.cancel();
    await a.close();
    await b.close();
    await c.close();
  });

  test('becomes true once each query delivers a server snapshot', () async {
    final a = StreamController<bool>();
    final b = StreamController<bool>();
    final c = StreamController<bool>();
    final out = <bool>[];
    final sub = homeSyncedStream(
      [a.stream, b.stream, c.stream],
      fallback: const Duration(seconds: 10),
    ).listen(out.add);

    a.add(true); // one query synced — not enough
    b.add(false); // a cache snapshot in between is ignored
    await _tick();
    expect(out.last, isFalse);

    b.add(true);
    c.add(true);
    await _tick();
    expect(out.last, isTrue);

    await sub.cancel();
    await a.close();
    await b.close();
    await c.close();
  });

  test('falls back to true after the timeout', () async {
    final a = StreamController<bool>();
    final out = <bool>[];
    final sub = homeSyncedStream(
      [a.stream],
      fallback: const Duration(milliseconds: 30),
    ).listen(out.add);

    await _tick(5);
    expect(out, [false]);

    await _tick(40); // past the fallback
    expect(out.last, isTrue);

    await sub.cancel();
    await a.close();
  });
}
