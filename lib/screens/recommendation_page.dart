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
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe['title']?.toString() ?? 'Recipe',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                if (recipe['category'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      label: Text(
                                        recipe['category'].toString(),
                                      ),
                                    ),
                                  ),
                                if (recipe['cuisine'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      label: Text(recipe['cuisine'].toString()),
                                    ),
                                  ),
                                if (recipe['difficulty'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      label: Text(
                                        'Difficulty: ${recipe['difficulty']}',
                                      ),
                                    ),
                                  ),
                                if (recipe['cooking_duration'] != null)
                                  Chip(
                                    label: Text(
                                      '⏱️ ${recipe['cooking_duration']} min',
                                    ),
                                  ),
                                if (recipe['servings'] != null)
                                  Chip(
                                    label: Text(
                                      'Servings: ${recipe['servings']}',
                                    ),
                                  ),
                              ],
                            ),
                            if (recipe['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  bottom: 8.0,
                                ),
                                child: Text(
                                  recipe['description'].toString(),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            if (recipe['nutrition'] != null &&
                                recipe['nutrition'] is Map)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    if (recipe['nutrition']['calories'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          'Calories: ${recipe['nutrition']['calories']}',
                                        ),
                                      ),
                                    if (recipe['nutrition']['protein'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          'Protein: ${recipe['nutrition']['protein']}g',
                                        ),
                                      ),
                                    if (recipe['nutrition']['carbs'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          'Carbs: ${recipe['nutrition']['carbs']}g',
                                        ),
                                      ),
                                    if (recipe['nutrition']['fat'] != null)
                                      Text(
                                        'Fat: ${recipe['nutrition']['fat']}g',
                                      ),
                                  ],
                                ),
                              ),
                            if (recipe['ingredients'] != null &&
                                recipe['ingredients'] is List)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ingredients:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ...List.from(recipe['ingredients']).map((
                                      ing,
                                    ) {
                                      if (ing is Map && ing['name'] != null) {
                                        final qty = ing['quantity'] != null
                                            ? ing['quantity'].toString()
                                            : '';
                                        final unit = ing['unit'] != null
                                            ? ing['unit'].toString()
                                            : '';
                                        return Text(
                                          '- ${ing['name']}: $qty $unit',
                                        );
                                      } else if (ing is String) {
                                        return Text('- $ing');
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    }).toList(),
                                  ],
                                ),
                              ),
                            if (recipe['instructions'] != null &&
                                recipe['instructions'] is List)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Instructions:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ...List.from(
                                      recipe['instructions'],
                                    ).asMap().entries.map((entry) {
                                      final idx = entry.key + 1;
                                      final step = entry.value;
                                      return Text('$idx. $step');
                                    }).toList(),
                                  ],
                                ),
                              ),
                            const Divider(height: 24, thickness: 1),
                            const Text(
                              'Raw JSON:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              width: double.infinity,
                              color: Colors.grey[100],
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                JsonEncoder.withIndent('  ').convert(recipe),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
