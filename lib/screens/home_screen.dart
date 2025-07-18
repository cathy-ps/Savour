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
import '../widgets/save_to_cookbook_modal.dart';
import 'recipe_detail.dart';
import 'package:savourai/constant/AppColor.dart';

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

  // Cookbook modal state
  bool _showSaveModal = false;
  List<Cookbook> _cookbooks = [];
  Recipe? _pendingSaveRecipe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _uid = FirebaseAuth.instance.currentUser?.uid;
      _username = FirebaseAuth.instance.currentUser?.displayName;
      await _fetchCookbooks();
    });
  }

  Future<void> _fetchCookbooks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .get();
    if (!mounted) return;
    setState(() {
      _cookbooks = snap.docs.map((doc) {
        final data = doc.data();
        String displayName =
            (data['title']?.toString() ?? data['name']?.toString() ?? doc.id);
        // If Cookbook does not have a description field, remove it from constructor
        return Cookbook(id: doc.id, name: displayName);
      }).toList();
    });
  }

  void _showSaveToCookbook(Recipe recipe) async {
    await _fetchCookbooks();
    if (!mounted) return;
    setState(() {
      _pendingSaveRecipe = recipe;
      _showSaveModal = true;
    });
  }

  void _handleSaveToCookbook(String cookbookId) async {
    final user = FirebaseAuth.instance.currentUser;
    final recipe = _pendingSaveRecipe;
    if (user == null || recipe == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc(cookbookId)
        .collection('recipes')
        .doc(recipe.recipeName)
        .set(recipe.toJson());
    if (!mounted) return;
    setState(() {
      _showSaveModal = false;
      _pendingSaveRecipe = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recipe saved to cookbook!')));
  }

  void _handleCreateAndSaveCookbook(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    final recipe = _pendingSaveRecipe;
    if (user == null || recipe == null) return;
    final newDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .add({'name': name});
    await newDoc
        .collection('recipes')
        .doc(recipe.recipeName)
        .set(recipe.toJson());
    await _fetchCookbooks();
    if (!mounted) return;
    setState(() {
      _showSaveModal = false;
      _pendingSaveRecipe = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created "$name" and saved recipe!')),
    );
  }

  // This function is ambiguous: it checks if a recipe is saved directly in 'cookbook', which is not the correct structure.
  // You should update this to check inside a specific cookbook's 'recipes' subcollection if needed.
  Future<bool> _isRecipeSaved(Recipe recipe, {String? cookbookId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (cookbookId == null) return false; // Must specify which cookbook
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc(cookbookId)
        .collection('recipes')
        .doc(recipe.recipeName)
        .get();
    return doc.exists;
  }

  // This function is ambiguous: it saves/removes recipes directly in 'cookbooks', not in a cookbook's 'recipes' subcollection.
  // You should update this to specify a cookbookId and save/remove in the correct subcollection.
  Future<void> _toggleSaveRecipe(
    Recipe recipe, {
    required String cookbookId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc(cookbookId)
        .collection('recipes')
        .doc(recipe.recipeName);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set(recipe.toJson());
    }
    if (!mounted) return;
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
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
                          builder: (context) =>
                              ProfilePage(initialName: _username),
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
                        color: AppColor.secondary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(
                              'assets/images/avatar.png',
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
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
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
                        const SizedBox(height: 16),
                        if (_ingredientChips.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _ingredientChips
                                .map(
                                  (chip) => Chip(
                                    label: Text(chip),
                                    onDeleted: () {
                                      setState(() {
                                        _ingredientChips.remove(chip);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 16),
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
                                      print('Gemini API response:');
                                      print(response);
                                      List<Map<String, dynamic>> recipes = [];
                                      if (response != null &&
                                          response.isNotEmpty) {
                                        // Try to extract a JSON array from the response
                                        String jsonArray = response.trim();
                                        if (!jsonArray.startsWith('[') ||
                                            !jsonArray.endsWith(']')) {
                                          final start = jsonArray.indexOf('[');
                                          final end = jsonArray.lastIndexOf(
                                            ']',
                                          );
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
                                                          Map<
                                                            String,
                                                            dynamic
                                                          >.from(e),
                                                    )
                                                    .toList()
                                              : <Map<String, dynamic>>[];
                                          recipes = parsed;
                                        } catch (err) {
                                          print('JSON parsing error: $err');
                                          recipes = [];
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to parse recipes. Please try again or check the console for details.',
                                              ),
                                            ),
                                          );
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
                                                    _toggleSaveRecipe(
                                                      r,
                                                      cookbookId:
                                                          _cookbooks.isNotEmpty
                                                          ? _cookbooks.first.id
                                                          : '',
                                                    ),
                                                // onAddToShoppingList: () {},
                                                onDownload: null,
                                                // Pass modal integration to detail page later
                                              ),
                                            ),
                                          );
                                        },
                                        onToggleSave: (r) =>
                                            _showSaveToCookbook(r),
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
          // Show SaveToCookbookModal
          if (_showSaveModal && _pendingSaveRecipe != null)
            SaveToCookbookModal(
              isOpen: _showSaveModal,
              onClose: () => setState(() => _showSaveModal = false),
              cookbooks: _cookbooks,
              onSave: _handleSaveToCookbook,
              onCreateAndSave: _handleCreateAndSaveCookbook,
            ),
          // Modal overlay
          if (_showSaveModal && _pendingSaveRecipe != null)
            SaveToCookbookModal(
              isOpen: _showSaveModal,
              onClose: () => setState(() => _showSaveModal = false),
              cookbooks: _cookbooks,
              onSave: _handleSaveToCookbook,
              onCreateAndSave: _handleCreateAndSaveCookbook,
            ),
        ],
      ),
    );
  }
}
