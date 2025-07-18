import 'package:flutter/material.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:convert';

class RecommendationPage extends StatelessWidget {
  final List<String> ingredients;
  final String? generatedText;
  const RecommendationPage({
    super.key,
    required this.ingredients,
    this.generatedText,
  });

  Future<bool> _isRecipeSaved(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbook')
        .doc(recipe.recipeName)
        .get();
    return doc.exists;
  }

  Future<void> _toggleSaveRecipe(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbook')
        .doc(recipe.recipeName);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set(recipe.toJson());
    }
  }

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
            ? ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, idx) {
                  final recipeMap = recipes![idx];
                  final recipe = Recipe.fromJson(recipeMap);
                  return FutureBuilder<bool>(
                    future: _isRecipeSaved(recipe),
                    builder: (context, snapshot) {
                      final isSaved = snapshot.data ?? false;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.95, end: 1),
                        duration: Duration(milliseconds: 500 + idx * 80),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: RecipeCard(
                          recipe: recipe,
                          isSaved: isSaved,
                          onSelect: (r) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: RecipeDetail(
                                            recipe: r.toJson(),
                                            onBack: () =>
                                                Navigator.pop(context),
                                            isSaved: isSaved,
                                            onToggleSave: () async {
                                              await _toggleSaveRecipe(r);
                                              (context as Element)
                                                  .markNeedsBuild();
                                            },
                                            onAddToShoppingList:
                                                () {}, // TODO: implement
                                            onDownload: null, // TODO: implement
                                          ),
                                        ),
                                transitionDuration: Duration(milliseconds: 400),
                              ),
                            );
                          },
                          onToggleSave: (r) async {
                            await _toggleSaveRecipe(r);
                            (context as Element).markNeedsBuild();
                          },
                        ),
                      );
                    },
                  );
                },
              )
            : Center(child: Text(error ?? 'No recipes found.')),
      ),
    );
  }
}
