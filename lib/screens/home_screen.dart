import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GenerativeModel _model;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: const String.fromEnvironment('api_key'),
    );
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not signed in, navigate to WelcomeScreen
      final uid = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
      if (uid != null) {
        setState(() {
          _uid = uid;
        });
      }
    } else {
      setState(() {
        _uid = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savour')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _uid == null
                  ? const CircularProgressIndicator()
                  : Text('Welcome to Savour!\nUID: \\n$_uid'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}
