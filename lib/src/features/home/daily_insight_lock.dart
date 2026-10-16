import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locks the daily insight to one sentence per day so it doesn't flip around as
/// home data streams in (anti-chatty rule). Pulled out of `DailyInsightLine`
/// so the hero speech bubble and anything else can share the same locked text.
/// Keeps the original SharedPreferences keys.
final dailyInsightLockProvider =
    NotifierProvider<DailyInsightLock, String?>(DailyInsightLock.new);

class DailyInsightLock extends Notifier<String?> {
  static const _kDayKey = 'insight_day';
  static const _kTextKey = 'insight_text';

  @override
  String? build() {
    _load();
    return null;
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kDayKey) == _today()) {
      final stored = p.getString(_kTextKey);
      state = (stored == null || stored.isEmpty) ? null : stored;
    }
  }

  /// Locks today's insight to [candidate] the first time a non-null candidate
  /// shows up, then keeps it for the rest of the day. Safe to call repeatedly.
  Future<void> resolve(String? candidate) async {
    final p = await SharedPreferences.getInstance();
    final today = _today();
    if (p.getString(_kDayKey) == today) {
      // Today is already recorded; fill the text if it was empty and a
      // candidate just arrived.
      if (state == null && candidate != null) {
        await p.setString(_kTextKey, candidate);
        state = candidate;
      }
      return;
    }
    // New day: lock the current candidate (may be empty, filled in later).
    await p.setString(_kDayKey, today);
    await p.setString(_kTextKey, candidate ?? '');
    state = candidate;
  }
}
