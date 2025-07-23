import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:savourai/constant/colors.dart';
import 'firebase_options.dart';
import 'screens/auth/welcome.dart';

import 'root.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Call during app initialization to ensure notifications are ready to use.
Future<void> initNotifications() async {
  // Create the notification channel for Android
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  // final bool? channelExists = await androidImplementation
  //     ?.areNotificationsEnabled();
  // print('[DEBUG] Notifications enabled: $channelExists');

  // Create a notification channel for reminders
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel_id',
    'Reminders',
    description: 'Channel for reminder notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  await androidImplementation?.createNotificationChannel(channel);
  print('[DEBUG] Notification channel created');

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('[DEBUG] Notification clicked: ${response.payload}');
    },
  );
  print('[DEBUG] Notifications initialized');

  // Test if notifications are working
  final bool? enabled = await androidImplementation?.areNotificationsEnabled();
  print('[DEBUG] Notifications enabled after initialization: $enabled');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Load environment variables
  await dotenv.load(fileName: 'assets/.env');

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

  // Initialize notifications
  await initNotifications();

  // Request notification permission for Android 13+
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authStateProvider);
        return ShadApp(
          title: 'SavourAI',
          theme: ShadThemeData(
            brightness: Brightness.light,
            colorScheme: const ShadZincColorScheme.light(
              primary: AppColors.primary,
              background: Colors.white, // Optionally override background
            ),

            // Use Google Fonts for text styles - Poppins
            textTheme: ShadTextTheme(family: 'Poppins'),
            primaryButtonTheme: const ShadButtonTheme(
              backgroundColor: AppColors.primary,
            ),
          ),

          debugShowCheckedModeBanner: false,
          home: authState.when(
            data: (user) => user == null ? WelcomePage() : RootNavigation(),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          ),
        );
      },
    );
  }
}
