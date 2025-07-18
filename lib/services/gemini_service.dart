import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  Future<String?> generateText(String prompt) async {
    try {
      final content = Content.text(prompt);
      final response = await _model.generateContent([content]);
      return response.text;
    } catch (e, st) {
      print('[GeminiService] Error: $e');
      return null;
    }
  }

  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['api_key'] ?? '';
    if (apiKey.isEmpty) {
      print(
        '[GeminiService] ERROR: API key is empty! Check your .env file and pubspec.yaml assets.',
      );
    } else {
      print(
        '[GeminiService] Using API key: ${apiKey.substring(0, 4)}... (length: ${apiKey.length})',
      );
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String?> generateRecipes(List<String> ingredients) async {
    final prompt =
        '''
You are a recipe generator. Given a list of ingredients, generate 3 unique, creative, and realistic recipes. Each recipe should be structured as a JSON object with the following fields: title, description, ingredients (array), steps (array), cooking_duration (minutes), difficulty, category, cuisine. Return a JSON array of recipes. Use only the provided ingredients, but you may assume basic pantry items (salt, pepper, oil, water) are available.

Ingredients: ${ingredients.join(", ")}
''';
    try {
      final content = Content.text(prompt);
      final response = await _model.generateContent([content]);
      return response.text;
    } catch (e, st) {
      print('[GeminiService] Error during recipe generation: $e');
      print('[GeminiService] Stacktrace: $st');
      if (dotenv.env['api_key'] == null || dotenv.env['api_key']!.isEmpty) {
        print('[GeminiService] API key is missing or empty in .env!');
      }
      return null;
    }
  }
}
