import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../services/gemini_service.dart';
//import '../widgets/custom_header.dart';
import 'profile_page.dart';
//import 'recommendation_page.dart';
import 'dart:convert';
import '../widgets/recipe_card.dart';
import 'recipe_detail.dart';

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
  //String? _generatedText;
  List<Map<String, dynamic>> _recipes = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uid = FirebaseAuth.instance.currentUser?.uid;
      _username = FirebaseAuth.instance.currentUser?.displayName;
    });
  }

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
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(initialName: _username),
                    ),
                  );
                  if (result != null && result is String) {
                    setState(() {
                      _username = result;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          'https://www.pngitem.com/pimgs/m/515-5152287_default-profile-picture-circle-hd-png-download.png',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Hello, ${_username ?? 'Guest'}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () async {
                          final controller = TextEditingController(
                            text: _username,
                          );
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Enter your name'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Your name',
                                ),
                                onSubmitted: (value) {
                                  Navigator.of(context).pop(value.trim());
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final name = controller.text.trim();
                                    if (name.isNotEmpty) {
                                      Navigator.of(context).pop(name);
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (newName != null && newName.isNotEmpty) {
                            setState(() {
                              _username = newName;
                            });
                            await FirebaseAuth.instance.currentUser
                                ?.updateProfile(displayName: newName);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
                                  List<Map<String, dynamic>> recipes = [];
                                  if (response != null && response.isNotEmpty) {
                                    // Try to extract a JSON array from the response
                                    String jsonArray = response.trim();
                                    if (!jsonArray.startsWith('[') ||
                                        !jsonArray.endsWith(']')) {
                                      final start = jsonArray.indexOf('[');
                                      final end = jsonArray.lastIndexOf(']');
                                      if (start != -1 &&
                                          end != -1 &&
                                          end > start) {
                                        jsonArray = jsonArray.substring(
                                          start,
                                          end + 1,
                                        );
                                      }
                                    }
                                    try {
                                      final decoded = jsonArray.isNotEmpty
                                          ? jsonArray
                                          : '[]';
                                      final parsed = decoded.isNotEmpty
                                          ? (jsonDecode(decoded) as List)
                                                .map(
                                                  (e) =>
                                                      Map<String, dynamic>.from(
                                                        e,
                                                      ),
                                                )
                                                .toList()
                                          : <Map<String, dynamic>>[];
                                      recipes = parsed;
                                    } catch (_) {
                                      recipes = [];
                                    }
                                    setState(() {
                                      _isGenerating = false;
                                      _generatedText = response;
                                      _recipes = recipes;
                                    });
                                  } else {
                                    setState(() {
                                      _isGenerating = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                            ..._recipes.map((recipeMap) {
                              final recipe = Recipe.fromJson(recipeMap);
                              return FutureBuilder<bool>(
                                future: _isRecipeSaved(recipe),
                                builder: (context, snapshot) {
                                  final isSaved = snapshot.data ?? false;
                                  return RecipeCard(
                                    recipe: recipe,
                                    isSaved: isSaved,
                                    onSelect: (r) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RecipeDetail(
                                            recipe: r.toJson(),
                                            onBack: () =>
                                                Navigator.pop(context),
                                            isSaved: isSaved,
                                            onToggleSave: () =>
                                                _toggleSaveRecipe(r),
                                            onAddToShoppingList:
                                                () {}, // TODO: implement
                                            onDownload: null, // TODO: implement
                                          ),
                                        ),
                                      );
                                    },
                                    onToggleSave: (r) => _toggleSaveRecipe(r),
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
