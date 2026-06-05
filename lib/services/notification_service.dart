import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/player_profile.dart';
import 'player_service.dart';

class NotificationWindow {
  const NotificationWindow({required this.startHour, required this.endHour});

  final int startHour;
  final int endHour;

  NotificationWindow copyWith({int? startHour, int? endHour}) =>
      NotificationWindow(
        startHour: startHour ?? this.startHour,
        endHour: endHour ?? this.endHour,
      );
}

class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static const int _petCareNotificationId = 2101;
  static const int _petCareLastChanceNotificationId = 2102;
  static const int _petCareThreshold = 19;
  static const String _startHourKey = 'pet_notification_start_hour_v1';
  static const String _endHourKey = 'pet_notification_end_hour_v1';
  static const String _permissionGrantedKey =
      'pet_notification_permission_granted_v1';
  static const Duration _lastChanceOffset = Duration(minutes: 5);
  static const Duration _pluginTimeout = Duration(seconds: 2);
  static const NotificationWindow defaultWindow = NotificationWindow(
    startHour: 16,
    endHour: 20,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final PlayerService _playerService = PlayerService();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    tz.initializeTimeZones();
    await _setLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    try {
      await _plugin.initialize(settings).timeout(_pluginTimeout);
    } catch (_) {
      // Widget tests and unsupported platforms do not register the plugin.
    }
  }

  Future<NotificationWindow> loadWindow() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationWindow(
      startHour: _validHour(prefs.getInt(_startHourKey)) ??
          defaultWindow.startHour,
      endHour: _validHour(prefs.getInt(_endHourKey)) ?? defaultWindow.endHour,
    );
  }

  Future<void> saveWindow(NotificationWindow window) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startHourKey, window.startHour.clamp(0, 23).toInt());
    await prefs.setInt(_endHourKey, window.endHour.clamp(0, 23).toInt());
    await scheduleForCurrentPlayer();
  }

  Future<bool> notificationsAllowed() async {
    if (kIsWeb) return false;
    try {
      await initialize().timeout(_pluginTimeout);
    } catch (_) {
      return false;
    }
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidEnabled =
          await android?.areNotificationsEnabled().timeout(_pluginTimeout);
      if (androidEnabled != null) return androidEnabled;
    } catch (_) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionGrantedKey) ?? false;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();
    try {
      var granted = true;
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await android
          ?.requestNotificationsPermission()
          .timeout(_pluginTimeout);
      if (androidGranted != null) granted = granted && androidGranted;

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await ios
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(_pluginTimeout);
      if (iosGranted != null) granted = granted && iosGranted;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionGrantedKey, granted);
      await scheduleForCurrentPlayer();
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPermissionsIfNeeded() async {
    if (!await notificationsAllowed()) {
      await requestPermissions();
    }
  }

  Future<void> scheduleForCurrentPlayer() async {
    final player = await _playerService.loadCurrent();
    if (player == null) {
      await cancelPetCareReminder();
      return;
    }
    await scheduleForPlayer(player);
  }

  Future<void> scheduleForPlayer(PlayerProfile player) async {
    await initialize();
    await cancelPetCareReminder();
    final currentPlayer = await _playerService.loadCurrent();
    if (currentPlayer == null ||
        currentPlayer.name != player.name ||
        !currentPlayer.hasPet ||
        !await notificationsAllowed()) {
      return;
    }

    final window = await loadWindow();
    final now = DateTime.now();
    final thresholdAt = currentPlayer.nextPetCareBelow(
      threshold: _petCareThreshold,
      now: now,
    );
    if (thresholdAt == null) return;

    final firstTriggerAt = _nextTimeInWindow(
      thresholdAt.isAfter(now)
          ? thresholdAt
          : now.add(const Duration(minutes: 1)),
      window,
    );

    await _schedulePetCareNotification(
      id: _petCareNotificationId,
      player: currentPlayer,
      triggerAt: firstTriggerAt,
    );

    final lastChanceAt = _nextLastChanceInWindow(
      now.add(const Duration(minutes: 1)),
      window,
    );
    if (lastChanceAt == null || _isSameMinute(firstTriggerAt, lastChanceAt)) {
      return;
    }

    await _schedulePetCareNotification(
      id: _petCareLastChanceNotificationId,
      player: currentPlayer,
      triggerAt: lastChanceAt,
    );
  }

  Future<void> _schedulePetCareNotification({
    required int id,
    required PlayerProfile player,
    required DateTime triggerAt,
  }) async {
    final strings = AppStrings(Locale(player.languageCode));
    final triggerCare = player.petCare(now: triggerAt);
    final mood = triggerCare.mood;
    if (mood == PetMood.happy) return;
    final scheduled = tz.TZDateTime.from(triggerAt, tz.local);

    try {
      await _plugin.zonedSchedule(
        id,
        strings.petNotificationTitle,
        strings.petNotificationBody(mood, player.name),
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pet_care',
            'Pet care',
            channelDescription: 'Pet food and fun reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on MissingPluginException {
      // The app can still run in tests and unsupported environments.
    }
  }

  Future<void> cancelPetCareReminder() async {
    try {
      await _plugin.cancel(_petCareNotificationId);
      await _plugin.cancel(_petCareLastChanceNotificationId);
    } on MissingPluginException {
      // Ignore in widget tests and unsupported platforms.
    }
  }

  Future<void> _setLocalTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  DateTime _nextTimeInWindow(DateTime candidate, NotificationWindow window) {
    final start = window.startHour.clamp(0, 23);
    final end = window.endHour.clamp(0, 23);
    var next = candidate;
    for (var i = 0; i < 3; i++) {
      if (_isInWindow(next, start, end)) return next;
      final startToday = DateTime(next.year, next.month, next.day, start);
      if (_isBeforeWindow(next, start, end)) return startToday;
      next = startToday.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime? _nextLastChanceInWindow(
    DateTime after,
    NotificationWindow window,
  ) {
    final start = window.startHour.clamp(0, 23);
    final end = window.endHour.clamp(0, 23);
    if (start == end) return null;

    final today = DateTime(after.year, after.month, after.day);
    for (var i = 0; i < 4; i++) {
      final day = today.add(Duration(days: i));
      final endBoundary = DateTime(day.year, day.month, day.day, end);
      final lastChance = endBoundary.subtract(_lastChanceOffset);
      if (!lastChance.isBefore(after) && _isInWindow(lastChance, start, end)) {
        return lastChance;
      }
    }
    return null;
  }

  bool _isSameMinute(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day &&
      first.hour == second.hour &&
      first.minute == second.minute;

  bool _isInWindow(DateTime value, int start, int end) {
    if (start == end) return true;
    if (start < end) return value.hour >= start && value.hour < end;
    return value.hour >= start || value.hour < end;
  }

  bool _isBeforeWindow(DateTime value, int start, int end) {
    if (start == end) return false;
    if (start < end) return value.hour < start;
    return value.hour >= end && value.hour < start;
  }

  int? _validHour(int? value) {
    if (value == null || value < 0 || value > 23) return null;
    return value;
  }
}
