import 'package:flutter/material.dart';
import 'package:savourai/widgets/custom_search_bar.dart';
import 'profile.dart';

import 'dart:convert';
import 'package:savourai/models/recipe_model.dart';
import 'package:savourai/services/gemini_service.dart';
import 'package:savourai/widgets/recipe_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savourai/widgets/cookbook_selector_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _recipes = [];
  bool _loading = false;
  String? _error;
  String? _rawResult;
  final GeminiService _geminiService = GeminiService();
  // Cookbook and favorite state
  List<String> _userCookbookIds = [];
  Map<String, List<String>> _cookbookRecipeIds =
      {}; // cookbookId -> List<recipeId>
  String? _userId; // Set this to the current user's ID

  @override
  void initState() {
    super.initState();
    _fetchUserCookbooks();
  }

  Future<void> _fetchUserCookbooks() async {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    final cookbooksSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('cookbooks')
        .get();
    setState(() {
      _userCookbookIds = cookbooksSnap.docs.map((doc) => doc.id).toList();
    });
    for (var doc in cookbooksSnap.docs) {
      final recipesSnap = await doc.reference.collection('recipes').get();
      _cookbookRecipeIds[doc.id] = recipesSnap.docs.map((r) => r.id).toList();
    }
  }

  String _getRecipeId(Recipe recipe) {
    // Use recipe.id if available, otherwise fallback to hashCode or title
    try {
      // ignore: invalid_use_of_protected_member
      return (recipe as dynamic).id ?? recipe.title.hashCode.toString();
    } catch (_) {
      return recipe.title.hashCode.toString();
    }
  }

  bool _isRecipeInAnyCookbook(Recipe recipe) {
    final id = _getRecipeId(recipe);
    return _cookbookRecipeIds.values.any((ids) => ids.contains(id));
  }

  Future<void> _onFavoriteTap(Recipe recipe) async {
    final id = _getRecipeId(recipe);
    // If recipe is already saved in any cookbook, unsave from all
    final savedCookbookIds = _cookbookRecipeIds.entries
        .where((entry) => entry.value.contains(id))
        .map((entry) => entry.key)
        .toList();
    if (savedCookbookIds.isNotEmpty) {
      // Remove from all cookbooks where it is saved
      for (final cookbookId in savedCookbookIds) {
        final recipeRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('cookbooks')
            .doc(cookbookId)
            .collection('recipes')
            .doc(id);
        await recipeRef.delete();
        setState(() {
          _cookbookRecipeIds[cookbookId]?.remove(id);
        });
      }
      return;
    }
    // Otherwise, prompt user to select a cookbook
    final selectedCookbookId = await showDialog<String>(
      context: context,
      builder: (context) => CookbookSelectorDialog(
        cookbookIds: _userCookbookIds,
        onCreateNew: () {
          // Optionally, add logic to create a new cookbook
        },
      ),
    );
    if (selectedCookbookId == null) return;
    final recipeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('cookbooks')
        .doc(selectedCookbookId)
        .collection('recipes')
        .doc(id);
    await recipeRef.set(recipe.toJson());
    setState(() {
      _cookbookRecipeIds[selectedCookbookId] ??= [];
      _cookbookRecipeIds[selectedCookbookId]!.add(id);
    });
  }

  Future<void> _searchRecipes() async {
    setState(() {
      _loading = true;
      _error = null;
      _recipes = [];
      _rawResult = null;
    });
    try {
      final ingredients = _searchController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final recipes = await _geminiService.generateRecipes(ingredients);
      setState(() {
        _recipes = recipes;
        _rawResult = recipes.isNotEmpty
            ? jsonEncode(recipes.map((e) => e.toJson()).toList())
            : null;
        _loading = false;
        if (recipes.isEmpty) {
          _error = 'No recipes generated.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load recipes.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Hello,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Good Morning',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomSearchBar(
                      controller: _searchController,
                      hintText: 'Enter your ingredients here',
                      submitIcon: const Icon(
                        Icons.rocket_launch_outlined,
                        color: Colors.white,
                      ),
                      onSubmit: _searchRecipes,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_error != null)
                Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_rawResult != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      color: Colors.black12,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _rawResult!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_recipes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        isFavorite: _isRecipeInAnyCookbook(recipe),
                        onFavoriteTap: () => _onFavoriteTap(recipe),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
