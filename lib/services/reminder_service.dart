import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> scheduleReminderNotification(
  DateTime scheduledTime,
  String message,
) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0, // Notification ID
    'SavourAI Reminder',
    message,
    tz.TZDateTime.from(scheduledTime, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel_id',
        'Reminders',
        channelDescription: 'Channel for reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    // One-time notification, no date interpretation or repeat needed
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}
