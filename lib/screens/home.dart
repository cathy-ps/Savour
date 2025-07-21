import 'package:flutter/material.dart';
import 'package:savourai/constant/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savourai/widgets/custom_search_bar.dart';
import 'profile.dart';

import 'dart:convert';
import 'package:savourai/models/recipe_model.dart';
import 'package:savourai/services/gemini_service.dart';
import 'package:savourai/widgets/recipe_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savourai/widgets/cookbook_selector_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/shoppinglist_firestore_provider.dart';
import '../models/shopping_list_model.dart';
import '../providers/saved_recipes_provider.dart';
import 'package:savourai/screens/recipe_detail.dart';
import '../models/cookbook_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _recipes = [];
  bool _loading = false;
  String? _error;
  String? _rawResult;
  final GeminiService _geminiService = GeminiService();
  // Cookbook and favorite state
  List<Cookbook> _userCookbooks = [];
  final Map<String, List<String>> _cookbookRecipeIds =
      {}; // cookbookId -> List<recipeId>
  String? _userId; // Set this to the current user's ID

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@')[0];
    }
    return '';
  }

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
    final cookbooks = cookbooksSnap.docs
        .map((doc) => Cookbook.fromJson(doc.data(), doc.id))
        .toList();
    setState(() {
      _userCookbooks = cookbooks;
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

  bool _isRecipeSavedGlobally(Recipe recipe) {
    final id = _getRecipeId(recipe);
    final savedIds = ref.watch(savedRecipeIdsProvider);
    return savedIds.contains(id);
  }

  Future<void> _onFavoriteTap(Recipe recipe) async {
    final id = _getRecipeId(recipe);
    final savedIds = ref.read(savedRecipeIdsProvider.notifier);
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
      // Update global saved state
      savedIds.update((state) {
        final newSet = Set<String>.from(state);
        newSet.remove(id);
        return newSet;
      });
      return;
    }
    // Otherwise, prompt user to select a cookbook
    final selectedCookbookId = await showDialog<String>(
      context: context,
      builder: (context) => CookbookSelectorDialog(
        cookbooks: _userCookbooks,
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
    // Update global saved state
    savedIds.update((state) {
      final newSet = Set<String>.from(state);
      newSet.add(id);
      return newSet;
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
      backgroundColor: AppColors.background,
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
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
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
                          children: [
                            Text(
                              '${_getGreeting()}, ${_getUserName()}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'What ingredients do you have?',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.person_outline,
                            color: AppColors.white,
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
                      hintText: 'e.g. eggs, rice, etc',
                      submitIcon: const Icon(
                        Icons.rocket_launch_outlined,
                        color: AppColors.white,
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
                    style: const TextStyle(color: AppColors.error),
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
                      color: AppColors.card,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _rawResult!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: AppColors.text,
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
                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(
                                    recipe: recipe,
                                    recipeId: _getRecipeId(recipe),
                                  ),
                                ),
                              );
                            },
                            child: RecipeCard(
                              recipe: recipe,
                              isFavorite: _isRecipeSavedGlobally(recipe),
                              onFavoriteTap: () => _onFavoriteTap(recipe),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: () async {
                              // Add all ingredients to Firestore shopping list as a new list
                              final now = DateTime.now();
                              final recipeId = _getRecipeId(recipe);
                              final shoppingListId =
                                  '${recipeId}_${now.millisecondsSinceEpoch}';
                              final shoppingListIngredients = recipe.ingredients
                                  .map(
                                    (ing) => ShoppingListIngredient(
                                      id: UniqueKey().toString(),
                                      name: ing.name,
                                      quantity: ing.quantity,
                                      unit: ing.unit,
                                    ),
                                  )
                                  .toList();
                              final shoppingList = ShoppingList(
                                id: shoppingListId,
                                name: recipe.title,
                                ingredients: shoppingListIngredients,
                                createdAt: now,
                                reminder: null,
                              );
                              await addShoppingList(shoppingList);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to shopping list!'),
                                ),
                              );
                            },
                            child: const Text('Add to Shopping List'),
                          ),
                        ],
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
