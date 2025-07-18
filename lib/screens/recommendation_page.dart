import 'package:flutter/material.dart';

import 'dart:convert';

class RecommendationPage extends StatelessWidget {
  final List<String> ingredients;
  final String? generatedText;
  const RecommendationPage({
    super.key,
    required this.ingredients,
    this.generatedText,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>>? recipes;
    String? error;
    if (generatedText != null && generatedText!.isNotEmpty) {
      try {
        // Try to parse as JSON
        final decoded = json.decode(generatedText!);
        if (decoded is List) {
          recipes = List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded['recipes'] is List) {
          recipes = List<Map<String, dynamic>>.from(decoded['recipes']);
        }
      } catch (_) {
        // Fallback: try to parse as Markdown (very basic)
        final lines = generatedText!.split('\n');
        final List<Map<String, dynamic>> parsed = [];
        Map<String, dynamic> current = {};
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          if (line.startsWith('- title:')) {
            if (current.isNotEmpty) parsed.add(current);
            current = {'title': line.replaceFirst('- title:', '').trim()};
          } else if (line.contains(':')) {
            final idx = line.indexOf(':');
            final key = line.substring(0, idx).trim().replaceAll('-', '');
            final value = line.substring(idx + 1).trim();
            current[key] = value;
          }
        }
        if (current.isNotEmpty) parsed.add(current);
        if (parsed.isNotEmpty) recipes = parsed;
      }
    } else {
      error = 'No recipes found.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Recipes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: (recipes != null && recipes.isNotEmpty)
            ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 16,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, idx) {
                  final recipe = recipes![idx];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe['title']?.toString() ?? 'Recipe',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (recipe['calories'] != null)
                                Text('Calories: ${recipe['calories']}'),
                              if (recipe['description'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    recipe['description'].toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              if (recipe['cooking_duration'] != null)
                                Text('⏱️ ${recipe['cooking_duration']} min'),
                              if (recipe['difficulty'] != null)
                                Text('Difficulty: ${recipe['difficulty']}'),
                              if (recipe['category'] != null)
                                Text('Category: ${recipe['category']}'),
                              if (recipe['cuisine'] != null)
                                Text('Cuisine: ${recipe['cuisine']}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                child: Text(
                  error ?? (generatedText ?? 'No recipes found.'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
      ),
    );
  }
}
