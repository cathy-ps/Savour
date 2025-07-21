import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/welcome.dart';
import 'root.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: 'assets/.env');
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
          darkTheme: ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: const ShadSlateColorScheme.dark(),
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
