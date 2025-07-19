import '../providers/shoppinglist_firestore_provider.dart';
import '../models/shopping_list_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savourai/models/cookbook_model.dart';
import 'package:savourai/models/recipe_model.dart';
import 'package:savourai/widgets/recipe_card.dart';
import '../providers/saved_recipes_provider.dart';
import 'package:savourai/screens/recipe_detail.dart';

class CookbookDetailScreen extends ConsumerWidget {
  final Cookbook cookbook;
  final String userId;
  const CookbookDetailScreen({
    super.key,
    required this.cookbook,
    required this.userId,
  });

  Future<List<Recipe>> _fetchRecipes() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookbooks')
        .doc(cookbook.id)
        .collection('recipes')
        .get();
    return snap.docs.map((doc) => Recipe.fromJson(doc.data())).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cookbook.title),
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load recipes'));
          }
          final recipes = snapshot.data ?? [];
          if (recipes.isEmpty) {
            return const Center(child: Text('No recipes in this cookbook.'));
          }
          final savedIds = ref.watch(savedRecipeIdsProvider);
          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                final id =
                    (recipe as dynamic).id ?? recipe.title.hashCode.toString();
                final isFavorite = savedIds.contains(id);
                return Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(
                              recipe: recipe,
                              recipeId: id,
                              cookbookId: cookbook.id,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      child: RecipeCard(
                        recipe: recipe,
                        isFavorite: isFavorite,
                        onFavoriteTap: () async {
                          final savedIdsNotifier = ref.read(
                            savedRecipeIdsProvider.notifier,
                          );
                          final recipeRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('cookbooks')
                              .doc(cookbook.id)
                              .collection('recipes')
                              .doc(id);
                          if (isFavorite) {
                            await recipeRef.delete();
                            savedIdsNotifier.update((state) {
                              final newSet = Set<String>.from(state);
                              newSet.remove(id);
                              return newSet;
                            });
                          } else {
                            await recipeRef.set(recipe.toJson());
                            savedIdsNotifier.update((state) {
                              final newSet = Set<String>.from(state);
                              newSet.add(id);
                              return newSet;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () async {
                        // Add all ingredients to Firestore shopping list as a new list
                        final now = DateTime.now();
                        final shoppingListId =
                            '${id}_${now.millisecondsSinceEpoch}';
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
          );
        },
      ),
    );
  }
}
