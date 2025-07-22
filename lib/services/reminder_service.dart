import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showImmediateNotification(
  int notificationId,
  String message,
) async {
  print('[DEBUG] Showing immediate notification with ID: $notificationId');
  try {
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'SavourAI Test',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_id',
          'Reminders',
          channelDescription: 'Channel for reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
      ),
    );
    print('[DEBUG] Immediate notification sent successfully');
  } catch (e, stack) {
    print('[ERROR] Failed to show immediate notification: $e');
    print('[ERROR] Stack trace: $stack');
  }
}

Future<void> scheduleReminderNotification(
  int notificationId,
  DateTime scheduledTime,
  String message,
) async {
  print('[DEBUG] Attempting to schedule notification');
  print('[DEBUG] Current time: ${DateTime.now()}');
  print('[DEBUG] Scheduled time: $scheduledTime');
  print('[DEBUG] Time difference: ${scheduledTime.difference(DateTime.now())}');

  try {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );
    print('[DEBUG] Timezone adjusted time: $scheduledDate');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'SavourAI Reminder',
      message,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_id',
          'Reminders',
          channelDescription: 'Channel for reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    print(
      '[DEBUG] Notification scheduled successfully with platform-specific implementation',
    );
  } catch (e, stack) {
    print('[ERROR] Failed to schedule notification: $e');
    print('[ERROR] Stack trace: $stack');
    rethrow;
  }
}
