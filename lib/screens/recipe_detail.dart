import 'package:shadcn_ui/shadcn_ui.dart';

import '../constant/colors.dart';
import '../providers/shoppinglist_firestore_provider.dart';
import '../models/shopping_list_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../providers/saved_recipes_provider.dart';
import '../providers/shoppinglist_providers.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final String? cookbookId;
  final String? userId;
  final Recipe? recipe; // If provided, use this instead of fetching
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.cookbookId,
    this.userId,
    this.recipe,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _recipe = widget.recipe;
      _loading = false;
    } else {
      _fetchRecipe();
    }
  }

  Future<void> _fetchRecipe() async {
    setState(() => _loading = true);
    try {
      if (widget.userId != null && widget.cookbookId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cookbooks')
            .doc(widget.cookbookId)
            .collection('recipes')
            .doc(widget.recipeId)
            .get();
        if (doc.exists) {
          _recipe = Recipe.fromJson(doc.data()!);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load recipe.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedIds = ref.watch(savedRecipeIdsProvider);
    final recipeKey = _recipe != null
        ? (_recipe!.id ?? _recipe!.title.hashCode.toString())
        : '';
    final isFavorite = _recipe != null && savedIds.contains(recipeKey);
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe?.title ?? 'Recipe'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: AppColors.white,
            ),
            onPressed: _recipe == null
                ? null
                : () async {
                    final id =
                        _recipe!.id ?? _recipe!.title.hashCode.toString();
                    final savedIdsNotifier = ref.read(
                      savedRecipeIdsProvider.notifier,
                    );
                    if (isFavorite) {
                      // Remove from Firestore if needed
                      if (widget.userId != null && widget.cookbookId != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .collection('cookbooks')
                            .doc(widget.cookbookId)
                            .collection('recipes')
                            .doc(id)
                            .delete();
                      }
                      savedIdsNotifier.update((state) {
                        final newSet = Set<String>.from(state);
                        newSet.remove(id);
                        return newSet;
                      });
                    } else {
                      // Save to Firestore if needed
                      if (widget.userId != null && widget.cookbookId != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .collection('cookbooks')
                            .doc(widget.cookbookId)
                            .collection('recipes')
                            .doc(id)
                            .set(_recipe!.toJson());
                      }
                      savedIdsNotifier.update((state) {
                        final newSet = Set<String>.from(state);
                        newSet.add(id);
                        return newSet;
                      });
                    }
                  },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            )
          : _recipe == null
          ? const Center(
              child: Text(
                'Recipe not found.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_recipe!.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          _recipe!.imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      _recipe!.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 18,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_recipe!.cookingDuration} min',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ingredients',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._recipe!.ingredients.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ing.name)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Instructions',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._recipe!.instructions.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Add to Shopping List'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              if (_recipe == null) return;
                              final now = DateTime.now();
                              final recipeId = _recipe!.id.isNotEmpty
                                  ? _recipe!.id
                                  : _recipe!.title.hashCode.toString();
                              final shoppingListId =
                                  '${recipeId}_${now.millisecondsSinceEpoch}';
                              final shoppingListIngredients = _recipe!
                                  .ingredients
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
                                name: _recipe!.title,
                                ingredients: shoppingListIngredients,
                                createdAt: now,
                                reminder: null,
                              );
                              await addShoppingList(shoppingList);
                              if (!mounted) return;
                              ShadToaster.of(context).show(
                                ShadToast(
                                  description: const Text(
                                    'Added to shopping list!',
                                  ),
                                  action: ShadButton.outline(
                                    child: const Text('View List'),
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pop(); // Close the toast if needed
                                      Navigator.pushNamed(
                                        context,
                                        '/shoppinglist',
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            // TODO: Implement offline download logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Recipe downloaded for offline use!',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
