/// Local scheduled reminders (no server, no FCM): daily "catat hari ini",
/// credit-card due dates, and recurring-bill heads-ups.
///
/// Everything is opt-in from Pengaturan → Pengingat. Scheduling is
/// re-derived on app open (`reminderSchedulerProvider`) and whenever the
/// user changes a toggle — `cancelAll` + reschedule, idempotent via an
/// input signature.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'formatters.dart';
import 'reminder_times.dart';

class ReminderSettings {
  const ReminderSettings({
    this.daily = false,
    this.dailyHour = 20,
    this.dailyMinute = 0,
    this.cardDue = false,
    this.recurringBills = false,
  });

  final bool daily;
  final int dailyHour;
  final int dailyMinute;
  final bool cardDue;
  final bool recurringBills;

  bool get anyEnabled => daily || cardDue || recurringBills;

  ReminderSettings copyWith({
    bool? daily,
    int? dailyHour,
    int? dailyMinute,
    bool? cardDue,
    bool? recurringBills,
  }) =>
      ReminderSettings(
        daily: daily ?? this.daily,
        dailyHour: dailyHour ?? this.dailyHour,
        dailyMinute: dailyMinute ?? this.dailyMinute,
        cardDue: cardDue ?? this.cardDue,
        recurringBills: recurringBills ?? this.recurringBills,
      );
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  ReminderSettingsNotifier.new,
);

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  static const _kDaily = 'reminder_daily';
  static const _kDailyHour = 'reminder_daily_hour';
  static const _kDailyMinute = 'reminder_daily_minute';
  static const _kCardDue = 'reminder_card_due';
  static const _kRecurring = 'reminder_recurring';

  @override
  ReminderSettings build() {
    _load();
    return const ReminderSettings();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = ReminderSettings(
      daily: p.getBool(_kDaily) ?? false,
      dailyHour: p.getInt(_kDailyHour) ?? 20,
      dailyMinute: p.getInt(_kDailyMinute) ?? 0,
      cardDue: p.getBool(_kCardDue) ?? false,
      recurringBills: p.getBool(_kRecurring) ?? false,
    );
  }

  Future<void> update(ReminderSettings next) async {
    state = next;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDaily, next.daily);
    await p.setInt(_kDailyHour, next.dailyHour);
    await p.setInt(_kDailyMinute, next.dailyMinute);
    await p.setBool(_kCardDue, next.cardDue);
    await p.setBool(_kRecurring, next.recurringBills);
  }
}

/// A card with outstanding balance whose due date we should announce.
typedef CardDueInput = ({String label, int dueDay, int used});

/// An upcoming recurring bill (derived from recurring expense templates).
typedef BillInput = ({String title, DateTime nextDate, int amount});

class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  String _lastSignature = '';

  /// Local notifications run on Android/iOS only (web/PWA has no
  /// app-scheduled notifications without a server push).
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> _ensureInitialized() async {
    if (!supported) return false;
    if (_initialized) return true;
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Keep the default location rather than crash scheduling; times may
      // be off by the UTC offset in this (rare) case.
      debugPrint('reminders: timezone resolution failed: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
    return true;
  }

  /// Asks the OS for notification permission (Android 13+ runtime prompt,
  /// iOS standard prompt). Returns false when denied/unsupported.
  Future<bool> requestPermission() async {
    if (!await _ensureInitialized()) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Pengingat',
      channelDescription:
          'Pengingat catat harian, jatuh tempo kartu, dan tagihan rutin',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Cancels and re-registers everything based on current inputs. No-op
  /// when inputs haven't changed since the last call this session.
  Future<void> reschedule({
    required ReminderSettings settings,
    required List<CardDueInput> cards,
    required List<BillInput> bills,
    DateTime? now,
  }) async {
    if (!await _ensureInitialized()) return;
    final n = now ?? DateTime.now();
    final sig = [
      settings.daily,
      settings.dailyHour,
      settings.dailyMinute,
      settings.cardDue,
      settings.recurringBills,
      for (final c in cards) '${c.label}|${c.dueDay}|${c.used}',
      for (final b in bills) '${b.title}|${b.nextDate}|${b.amount}',
    ].join(';');
    if (sig == _lastSignature) return;
    _lastSignature = sig;

    await _plugin.cancelAll();
    if (!settings.anyEnabled) return;

    if (settings.daily) {
      final first = nextTimeOfDay(n, settings.dailyHour, settings.dailyMinute);
      await _zoned(
        id: 1,
        at: first,
        title: 'Sudah catat pengeluaran hari ini?',
        body: '30 detik saja — biar ringkasan keluarga tetap akurat.',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    if (settings.cardDue) {
      for (var i = 0; i < cards.length && i < 50; i++) {
        final c = cards[i];
        if (c.used <= 0) continue;
        final due = nextCardDueDate(c.dueDay, n);
        final before = reminderMoment(due, n, daysBefore: 3);
        if (before != null) {
          await _zoned(
            id: 100 + i,
            at: before,
            title: 'Tagihan kartu 3 hari lagi',
            body:
                '${c.label} jatuh tempo ${Dates.dayMonth(due)} · ${Money.format(c.used)}.',
          );
        }
        final onDay = reminderMoment(due, n);
        if (onDay != null) {
          await _zoned(
            id: 200 + i,
            at: onDay,
            title: 'Tagihan kartu hari ini',
            body: '${c.label} jatuh tempo hari ini · ${Money.format(c.used)}.',
          );
        }
      }
    }

    if (settings.recurringBills) {
      for (var i = 0; i < bills.length && i < 50; i++) {
        final b = bills[i];
        final at = reminderMoment(b.nextDate, n, daysBefore: 1);
        if (at == null) continue;
        await _zoned(
          id: 300 + i,
          at: at,
          title: 'Tagihan rutin besok',
          body:
              '${b.title} ±${Money.format(b.amount)} biasanya tanggal ${b.nextDate.day}.',
        );
      }
    }
  }

  Future<void> _zoned({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    DateTimeComponents? matchDateTimeComponents,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _details,
      // Inexact: reminder use-case tolerates a few minutes drift and we
      // skip the Android 12+ exact-alarm permission dance entirely.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});
