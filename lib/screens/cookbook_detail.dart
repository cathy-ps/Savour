import 'package:flutter/material.dart';

import '../constant/colors.dart';
import '../providers/shoppinglist_firestore_provider.dart';
import '../models/shopping_list_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savourai/models/cookbook_model.dart';
import '../providers/cookbooks_provider.dart';
import 'package:savourai/models/recipe_model.dart';
import 'package:savourai/widgets/recipe_card.dart';
import '../providers/saved_recipes_provider.dart';
import '../utils/favorite_handler.dart';
import 'package:savourai/screens/recipe_detail.dart';
import 'package:savourai/widgets/custom_app_bar.dart';

class CookbookDetailScreen extends ConsumerWidget {
  final Cookbook cookbook;
  final String userId;
  final String cookbookDocId;
  const CookbookDetailScreen({
    super.key,
    required this.cookbook,
    required this.userId,
    required this.cookbookDocId,
  });

  Future<List<Recipe>> _fetchRecipes() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookbooks')
        .doc(cookbookDocId)
        .collection('recipes')
        .get();
    return snap.docs.map((doc) => Recipe.fromJson(doc.data(), doc.id)).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(
        title: cookbook.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Cookbook',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Cookbook'),
                  content: const Text(
                    'Are you sure you want to delete this cookbook? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final notifier = ref.read(cookbookActionsProvider.notifier);
                await notifier.deleteCookbook(cookbookDocId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cookbook deleted.')),
                  );
                }
              }
            },
          ),
        ],
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
                              cookbookId: cookbookDocId,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      child: RecipeCard(
                        recipe: recipe,
                        isFavorite:
                            recipe.isFavorite ||
                            true, // Always red heart for recipes in this cookbook
                        onFavoriteTap: () async {
                          await handleFavoriteTap(
                            context: context,
                            ref: ref,
                            recipe: recipe,
                            userId: userId,
                            cookbookRecipeIds: {
                              cookbookDocId: [id],
                            },
                            userCookbooks: [cookbook],
                            userCookbookDocIds: [cookbookDocId],
                            showSelector: false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // Add all ingredients to Firestore shopping list as a new list
                        final now = DateTime.now();
                        final shoppingListId =
                            '${id}_${now.millisecondsSinceEpoch}';
                        final shoppingListIngredients = recipe.ingredients
                            .map(
                              (ing) => ShoppingListIngredient(
                                id: '${ing.name}-${ing.quantity}-${ing.unit}',
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
