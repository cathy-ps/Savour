import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class GeminiTestScreen extends StatefulWidget {
  const GeminiTestScreen({Key? key}) : super(key: key);

  @override
  State<GeminiTestScreen> createState() => _GeminiTestScreenState();
}

class _GeminiTestScreenState extends State<GeminiTestScreen> {
  String? _result;
  bool _loading = false;

  Future<void> _runGemini() async {
    setState(() => _loading = true);
    final gemini = GeminiService();
    final response = await gemini.generateText(
      "Explain how AI works in a few words",
    );
    setState(() {
      _result = response;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _runGemini,
              child: const Text('Test Gemini'),
            ),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (_result != null && !_loading)
              Text(_result!, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
