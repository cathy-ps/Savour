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
    // if (apiKey.isEmpty) {
    //   print(
    //     '[GeminiService] ERROR: API key is empty! Check your .env file and pubspec.yaml assets.',
    //   );
    // } else {
    //   print(
    //     '[GeminiService] Using API key: ${apiKey.substring(0, 4)}... (length: ${apiKey.length})',
    //   );
    // }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String?> generateRecipes(List<String> ingredients) async {
    final prompt =
        '''
You are a smart recipe generator for people with limited cooking experience and limited ingredients. Suggest at least 5 creative recipes that use ONLY these ingredients: ${ingredients.join(", ")}, plus common pantry items (salt, pepper, oil, water, sugar, basic spices). Do NOT include any other ingredients that require a store trip.

Return the recipes as a JSON array. Each recipe must be a JSON object with these fields:
- title (string)
- category (string, e.g. breakfast, lunch, dinner, snack, dessert)
- cuisine (string, e.g. Italian, Asian, American, etc.)
- difficulty (string: easy, medium, hard)
- cooking_duration (integer, in minutes)
- description (string, 1-2 sentences)
- servings (integer, default 1)
- ingredients (array of objects: { name, quantity, unit })
- instructions (array of strings, step-by-step)
- nutrition (object: { calories, protein, carbs, fat } per serving, all numbers)

Make sure the ingredient list and quantities are for 1 serving and scalable. Do not include any ingredients outside the provided list and common pantry items. Format the output as a valid JSON array, no extra text.
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
