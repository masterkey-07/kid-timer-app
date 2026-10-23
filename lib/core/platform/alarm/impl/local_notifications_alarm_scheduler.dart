import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:visual_time_counter/core/platform/alarm/alarm_scheduler.dart';

/// Localized names of the Android notification channels.
typedef AlarmChannelNames = ({String timerEnd, String warning});

/// [AlarmScheduler] backed by `flutter_local_notifications` (Android, iOS,
/// macOS and, depending on spike T042, Windows; research R4).
///
/// Android uses `AndroidScheduleMode.alarmClock` (exempt from Doze) on a
/// `timer_end_<soundId>` channel per sound; Apple platforms use a
/// time-sensitive notification with the bundled sound and no foreground
/// presentation (the app rings by itself while open).
final class LocalNotificationsAlarmScheduler implements AlarmScheduler {
  /// Creates the scheduler; call [initialize] before using it.
  new({
    required this._clock,
    this._channelNames = const (timerEnd: 'Timer end', warning: 'Warnings'),
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// The group key travels in the payload so pending alarms can be grouped.
  static const _groupParameter = 'g';
  static const _warningChannelId = 'timer_warning';
  static const _windowsGuid = '3c6b2c4e-8f1a-4d7e-9b52-6a0e1f7d2c93';

  final Clock _clock;
  final AlarmChannelNames _channelNames;
  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  final _createdChannels = <String>{};

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  MacOSFlutterLocalNotificationsPlugin? get _macos => _plugin
      .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin
      >();

  /// Initializes the plugin without asking for permissions (the start
  /// preflight asks when needed).
  Future<void> initialize() async {
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
        windows: WindowsInitializationSettings(
          appName: 'Kid Timer',
          appUserModelId: 'io.github.masterkey07.visualtimecounter',
          guid: _windowsGuid,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(_withoutGroup(payload));
      },
    );
  }

  @override
  Future<AlarmCapabilities> capabilities() async {
    final android = _android;
    if (android != null) {
      final canBeExact = await android.canScheduleExactNotifications() ?? false;
      final enabled = await android.areNotificationsEnabled() ?? false;
      return AlarmCapabilities(
        scheduling: canBeExact
            ? SchedulingSupport.native
            : SchedulingSupport.inexactOnly,
        // Android cannot tell "never asked" from "denied"; asking again
        // reveals it (the system answers at once after two denials).
        notifications: enabled
            ? PermissionState.granted
            : PermissionState.notDetermined,
        exactAlarm: canBeExact
            ? PermissionState.granted
            : PermissionState.denied,
      );
    }

    final darwinOptions =
        await _ios?.checkPermissions() ?? await _macos?.checkPermissions();
    return AlarmCapabilities(
      scheduling: SchedulingSupport.native,
      notifications: switch (darwinOptions) {
        null => PermissionState.notApplicable,
        final options when options.isEnabled => PermissionState.granted,
        _ => PermissionState.notDetermined,
      },
      exactAlarm: PermissionState.notApplicable,
    );
  }

  @override
  Future<PermissionState> requestNotificationPermission() async {
    final bool? granted;
    if (_android case final android?) {
      granted = await android.requestNotificationsPermission();
    } else if (_ios case final ios?) {
      granted = await ios.requestPermissions(alert: true, sound: true);
    } else if (_macos case final macos?) {
      granted = await macos.requestPermissions(alert: true, sound: true);
    } else {
      return PermissionState.notApplicable;
    }
    return granted ?? false ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<bool> openExactAlarmSettings() async =>
      await _android?.requestExactAlarmsPermission() ?? false;

  @override
  Future<ScheduleResult> schedule(AlarmRequest request) async {
    if (!request.fireAtUtc.isAfter(_clock.now().toUtc())) {
      return const Failed(ScheduleFailure.pastTime);
    }

    try {
      final capabilities = await this.capabilities();
      if (capabilities.notifications == PermissionState.denied) {
        return const Failed(ScheduleFailure.permissionDenied);
      }
      if (await _pendingInGroup(request) >= AlarmScheduler.maxPendingPerGroup) {
        return const Failed(ScheduleFailure.tooManyPending);
      }

      final isExact = capabilities.scheduling == SchedulingSupport.native;
      await _plugin.zonedSchedule(
        id: request.id,
        title: request.title,
        body: request.body,
        payload: _withGroup(request.payload, request.groupKey),
        scheduledDate: tz.TZDateTime.from(request.fireAtUtc, tz.UTC),
        notificationDetails: await _detailsFor(request),
        androidScheduleMode: isExact
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return Scheduled(isExact: isExact);
    } on PlatformException catch (error) {
      debugPrint('Alarm scheduling failed: $error');
      return const Failed(ScheduleFailure.platformError);
    }
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelGroup(String groupKey) async {
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (_groupOf(pending.payload) == groupKey) {
        await _plugin.cancel(id: pending.id);
      }
    }
  }

  @override
  Stream<String> get notificationTaps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;
    if (!(details?.didNotificationLaunchApp ?? false) || payload == null) {
      return null;
    }
    return _withoutGroup(payload);
  }

  Future<int> _pendingInGroup(AlarmRequest request) async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending
        .where(
          (other) =>
              other.id != request.id &&
              _groupOf(other.payload) == request.groupKey,
        )
        .length;
  }

  Future<NotificationDetails> _detailsFor(AlarmRequest request) async {
    final isWarning = request.kind == AlarmKind.warning;
    final channelId = isWarning
        ? _warningChannelId
        : 'timer_end_${request.sound.value}';
    final channelName = isWarning
        ? _channelNames.warning
        : _channelNames.timerEnd;
    final importance = isWarning
        ? Importance.defaultImportance
        : Importance.max;
    final sound = request.sound.isAudible
        ? RawResourceAndroidNotificationSound(request.sound.value)
        : null;

    await _ensureAndroidChannel(
      AndroidNotificationChannel(
        channelId,
        channelName,
        importance: importance,
        playSound: request.sound.isAudible,
        sound: sound,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    final darwin = DarwinNotificationDetails(
      // The open app rings by itself; the notification is only for when it
      // is in the background (single ring, research R4).
      presentAlert: false,
      presentBanner: false,
      presentList: false,
      presentSound: false,
      sound: request.sound.isAudible ? '${request.sound.value}.wav' : null,
      interruptionLevel: isWarning
          ? InterruptionLevel.active
          : InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: isWarning ? Priority.defaultPriority : Priority.max,
        playSound: request.sound.isAudible,
        sound: sound,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: darwin,
      macOS: darwin,
      windows: const WindowsNotificationDetails(),
    );
  }

  Future<void> _ensureAndroidChannel(AndroidNotificationChannel channel) async {
    final android = _android;
    if (android == null || _createdChannels.contains(channel.id)) return;
    await android.createNotificationChannel(channel);
    _createdChannels.add(channel.id);
  }

  static String _withGroup(String payload, String groupKey) {
    final uri = Uri.parse(payload);
    return uri
        .replace(
          queryParameters: {...uri.queryParameters, _groupParameter: groupKey},
        )
        .toString();
  }

  static String? _groupOf(String? payload) => payload == null
      ? null
      : Uri.tryParse(payload)?.queryParameters[_groupParameter];

  static String _withoutGroup(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri == null || !uri.queryParameters.containsKey(_groupParameter)) {
      return payload;
    }
    final query = {...uri.queryParameters}..remove(_groupParameter);
    return uri
        .replace(queryParameters: query.isEmpty ? null : query)
        .toString()
        .replaceFirst(RegExp(r'\?$'), '');
  }
}
