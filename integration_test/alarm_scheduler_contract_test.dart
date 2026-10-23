import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:visual_time_counter/core/platform/alarm/impl/local_notifications_alarm_scheduler.dart';

import '../test/contract/alarm_scheduler_contract.dart';

/// Runs the AlarmScheduler contract against the real
/// flutter_local_notifications implementation (Android only; the other
/// platforms are covered by the release checklist).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isAndroid) {
    test('AlarmScheduler contract (real)', () {}, skip: 'Android only');
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();

  setUpAll(plugin.cancelAll);
  tearDownAll(plugin.cancelAll);

  runAlarmSchedulerContract('LocalNotificationsAlarmScheduler', () async {
    final scheduler = LocalNotificationsAlarmScheduler(
      clock: const Clock(),
      plugin: plugin,
    );
    await scheduler.initialize();
    return (
      scheduler: scheduler,
      now: DateTime.now,
      pending: () async => [
        for (final request in await plugin.pendingNotificationRequests())
          (id: request.id, title: request.title ?? ''),
      ],
    );
  });
}
