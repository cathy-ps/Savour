import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/models/recipe_model.dart';

// Helper to fetch a food image from Pexels API
Future<String?> fetchPexelsImage(String query, String apiKey) async {
  final url = Uri.parse(
    'https://api.pexels.com/v1/search?query=$query&per_page=1',
  );
  final response = await http.get(url, headers: {'Authorization': apiKey});
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['photos'] != null && data['photos'].isNotEmpty) {
      return data['photos'][0]['src']['medium']; // or 'large', 'original', etc.
    }
  }
  return null; // fallback if no image found
}

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
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String?> generateRecipes(
    List<String> ingredients, {
    String? cuisine,
    String? dietaryNotes,
  }) async {
    final prompt =
        '''
You are a recipe generator. Based on the following criteria, generate a random number of recipes, between 3 and 10.
- Must-have ingredients: ${ingredients.isNotEmpty ? ingredients.join(', ') : 'any common pantry items'}.

For each recipe, provide all the requested details. Be creative and make the recipes sound delicious.
If the ingredients are sparse, feel free to supplement with common pantry staples.
Ensure the instructions are clear and easy to follow.

IMPORTANT: Output ONLY a valid JSON array of objects, with no markdown, no explanation, no bullet points, no code block, and no extra text. Each recipe object must have these fields (all keys and string values in double quotes):
- "title": string
- "category": string
- "cuisine": string
- "difficulty": string (easy, medium, hard)
- "cooking_duration": integer (in minutes)
- "description": string
- "servings": integer (default 1)
- "ingredients": array of objects { "name": string, "quantity": string, "unit": string }
- "instructions": array of strings
- "nutrition": object { "calories": number, "protein": number, "carbs": number, "fat": number }

Do not include any text, markdown, bullet points, code block, or explanation before or after the JSON array. Only output the JSON array. If you cannot comply, return an empty JSON array: [].
''';
    //         '''
    // You are a smart recipe generator for people with limited cooking experience and limited ingredients. Suggest at least 5 creative recipes that use ONLY these ingredients: ${ingredients.join(", ")}, plus common pantry items (salt, pepper, oil, water, sugar, basic spices). Do NOT include any other ingredients that require a store trip.

    // Return the recipes as a JSON array. Each recipe must be a JSON object with these fields:
    // - title (string)
    // - category (string, e.g. breakfast, lunch, dinner, snack, dessert)
    // - cuisine (string, e.g. Italian, Asian, American, etc.)
    // - difficulty (string: easy, medium, hard)
    // - cooking_duration (integer, in minutes)
    // - description (string, 1-2 sentences)
    // - servings (integer, default 1)
    // - ingredients (array of objects: { name, quantity, unit })
    // - instructions (array of strings, step-by-step)
    // - nutrition (object: { calories, protein, carbs, fat } per serving, all numbers)

    // Make sure the ingredient list and quantities are for 1 serving and scalable. Do not include any ingredients outside the provided list and common pantry items. Format the output as a valid JSON array, no extra text.
    // ''';
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

  Future<List<Recipe>> generateRecipesWithImages({
    required List<String> ingredients,
    String? cuisine,
    String? dietaryNotes,
    required String apiKey,
  }) async {
    final prompt =
        '''
You are a recipe generator. Based on the following criteria, generate a random number of recipes, between 3 and 10.
- Must-have ingredients: ${ingredients.isNotEmpty ? ingredients.join(', ') : 'any common pantry items'}.
- Cuisine style: ${cuisine ?? 'any'}.
- Dietary considerations: ${dietaryNotes ?? 'none'}.

For each recipe, provide all the requested details. Be creative and make the recipes sound delicious.
If the ingredients are sparse, feel free to supplement with common pantry staples.
Ensure the instructions are clear and easy to follow.

Do not include any text, markdown, or explanation before or after the JSON array. Only output the JSON array.
''';

    // Call Gemini API (text generation)
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    );
    final headers = {
      'Content-Type': 'application/json',
      'X-goog-api-key': apiKey,
    };
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode != 200)
      throw Exception('Failed to generate recipes');
    final text =
        jsonDecode(
              response.body,
            )['candidates'][0]['content']['parts'][0]['text']
            as String;

    // Extract the first valid JSON array from the response
    String? jsonArray;
    final arrayStart = text.indexOf('[');
    final arrayEnd = text.lastIndexOf(']');
    if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
      jsonArray = text.substring(arrayStart, arrayEnd + 1);
    } else {
      jsonArray = '[]';
    }

    // Parse recipes
    List<dynamic> jsonList = jsonDecode(jsonArray);
    List<Recipe> recipes = jsonList.map((e) => Recipe.fromJson(e)).toList();

    // Optionally: Generate images for each recipe (using a separate image model API)
    // This part is pseudo-code, as Gemini image API is not public in Dart/Flutter.
    // You can use a placeholder or your own image generation API.
    // Fetch a Pexels image for each recipe (sequentially)
    // for (final recipe in recipes) {
    //   final imageUrl = await fetchPexelsImage(recipe.recipeName, apiKey);
    //   recipe.imageUrl =
    //       imageUrl ??
    //       'https://placehold.co/500x500/f97316/white?text=${Uri.encodeComponent(recipe.recipeName)}';
    // }

    return recipes;
  }
}
