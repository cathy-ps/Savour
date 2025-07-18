import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class CookbookScreen extends StatefulWidget {
  const CookbookScreen({super.key});

  @override
  State<CookbookScreen> createState() => _CookbookScreenState();
}

class _CookbookScreenState extends State<CookbookScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _aiResponse;
  bool _loading = false;

  Future<void> _sendPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _loading = true;
      _aiResponse = null;
    });
    final gemini = GeminiService();
    final response = await gemini.generateText(prompt);
    setState(() {
      _aiResponse = response;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cookbook')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Your Cookbook', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 24),
            if (_aiResponse != null && _aiResponse!.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _aiResponse!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask Gemini (e.g. Write me a song about pasta)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _sendPrompt,
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
