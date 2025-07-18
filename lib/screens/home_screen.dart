import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../services/gemini_service.dart';
import '../widgets/custom_header.dart';
import 'profile_page.dart';
import 'recommendation_page.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  final List<String> _ingredientChips = [];
  final GeminiService _geminiService = GeminiService();
  String? _uid;
  String? _username;
  String? _generatedText;
  List<Map<String, dynamic>> _recipes = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
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
          _username = null;
        });
      }
    } else {
      setState(() {
        _uid = user.uid;
        _username = user.displayName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _uid == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomHeader(
                    title: _username != null && _username!.isNotEmpty
                        ? 'Welcome to Savour, $_username!'
                        : 'Welcome to Savour',
                    subtitle: 'Your personal recipe assistant',
                    actionIcon: Icons.person_outline,
                    onActionPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage(initialName: _username),
                        ),
                      );
                      setState(() {
                        _username =
                            FirebaseAuth.instance.currentUser?.displayName;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'What can you cook with what you have?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your leftover or available ingredients and discover new recipes!',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ingredientChips
                              .map(
                                (ingredient) => Chip(
                                  label: Text(ingredient),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    setState(() {
                                      _ingredientChips.remove(ingredient);
                                    });
                                  },
                                  backgroundColor: Colors.green.shade50,
                                  labelStyle: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ingredientsController,
                          decoration: InputDecoration(
                            hintText: 'e.g. eggs, tomato, cheese',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final text = _ingredientsController.text.trim();
                                if (text.isNotEmpty) {
                                  setState(() {
                                    _ingredientChips.addAll(
                                      text
                                          .split(',')
                                          .map((e) => e.trim())
                                          .where(
                                            (e) =>
                                                e.isNotEmpty &&
                                                !_ingredientChips.contains(e),
                                          ),
                                    );
                                    _ingredientsController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              setState(() {
                                _ingredientChips.addAll(
                                  text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where(
                                        (e) =>
                                            e.isNotEmpty &&
                                            !_ingredientChips.contains(e),
                                      ),
                                );
                                _ingredientsController.clear();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _ingredientChips.isEmpty
                                ? null
                                : () async {
                                    setState(() {
                                      _isGenerating = true;
                                      _generatedText = null;
                                    });
                                    try {
                                      final response = await _geminiService
                                          .generateRecipes(_ingredientChips);
                                      setState(() {
                                        _isGenerating = false;
                                      });
                                      if (response != null &&
                                          response.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RecommendationPage(
                                                  ingredients:
                                                      List<String>.from(
                                                        _ingredientChips,
                                                      ),
                                                  generatedText: response,
                                                ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to generate recipes. Please try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() {
                                        _isGenerating = false;
                                      });
                                      // ignore: avoid_print
                                      print('Recipe generation error: $e');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to generate recipes. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Generate Recipes'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isGenerating)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (!_isGenerating && _recipes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Generated Recipes:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._recipes.map(
                                  (recipe) => Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe['title'] ?? 'No Title',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (recipe['description'] !=
                                              null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              recipe['description'],
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                          if (recipe['ingredients'] != null &&
                                              recipe['ingredients']
                                                  is List) ...[
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Ingredients:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...List.from(recipe['ingredients'])
                                                .map((ing) => Text('- $ing'))
                                                .toList(),
                                          ],
                                          if (recipe['steps'] != null &&
                                              recipe['steps'] is List) ...[
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Steps:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...List.from(recipe['steps'])
                                                .map((step) => Text('- $step'))
                                                .toList(),
                                          ],
                                          if (recipe['cooking_duration'] !=
                                              null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Cooking Time: ${recipe['cooking_duration']} min',
                                            ),
                                          ],
                                          if (recipe['difficulty'] != null) ...[
                                            Text(
                                              'Difficulty: ${recipe['difficulty']}',
                                            ),
                                          ],
                                          if (recipe['category'] != null) ...[
                                            Text(
                                              'Category: ${recipe['category']}',
                                            ),
                                          ],
                                          if (recipe['cuisine'] != null) ...[
                                            Text(
                                              'Cuisine: ${recipe['cuisine']}',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
