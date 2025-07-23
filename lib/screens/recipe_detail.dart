import 'package:shadcn_ui/shadcn_ui.dart';

import '../constant/colors.dart';
import '../providers/shoppinglist_firestore_provider.dart';
import '../models/shopping_list_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../providers/saved_recipes_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cookbook_model.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/cookbook_selector_dialog.dart';

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
  Future<void> _saveToCookbook(Recipe recipe) async {
    // Get userId
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('You must be logged in.')));
      return;
    }
    // Fetch cookbooks
    final cookbooksSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .get();
    final cookbooks = cookbooksSnap.docs
        .map((doc) => Cookbook.fromJson(doc.data(), doc.id))
        .toList();
    final docIds = cookbooksSnap.docs.map((doc) => doc.id).toList();
    if (cookbooks.isEmpty || docIds.isEmpty) {
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('No cookbooks available.')));
      return;
    }
    // Show selector dialog
    final selectedCookbookId = await showDialog<String>(
      context: context,
      builder: (context) => CookbookSelectorDialog(cookbooks: cookbooks),
    );
    if (selectedCookbookId == null || selectedCookbookId.trim().isEmpty) {
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('No cookbook selected.')));
      return;
    }
    // Save to Firestore
    final id = recipe.id;
    final recipeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc(selectedCookbookId)
        .collection('recipes')
        .doc(id);
    await recipeRef.set(recipe.toJson());
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast(
        description: const Text('Recipe saved to cookbook!'),
        action: ShadButton.outline(
          child: const Text('View Cookbook'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the toast if needed
            Navigator.pushNamed(
              context,
              '/cookbook_detail',
              arguments: selectedCookbookId,
            );
          },
        ),
      ),
    );
    // Optionally update favorite state here if needed
    final savedIdsNotifier = ref.read(savedRecipeIdsProvider.notifier);
    savedIdsNotifier.update((state) {
      final newSet = Set<String>.from(state);
      newSet.add(id);
      return newSet;
    });
  }

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
          _recipe = Recipe.fromJson(doc.data()!, doc.id);
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
    final recipeKey = _recipe != null ? _recipe!.id : '';
    // Always use provider for UI state, model field is for Firestore only
    final isFavorite = _recipe != null && savedIds.contains(recipeKey);
    return Scaffold(
      appBar: CustomAppBar(
        title: '',
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : AppColors.black,
            ),
            onPressed: _recipe == null
                ? null
                : () async {
                    final id = _recipe!.id;
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
                      setState(() {}); // Force UI update
                    } else {
                      // Prompt user to select cookbook and save
                      if (_recipe != null) {
                        final updatedRecipe = Recipe(
                          id: _recipe!.id,
                          title: _recipe!.title,
                          category: _recipe!.category,
                          cuisine: _recipe!.cuisine,
                          difficulty: _recipe!.difficulty,
                          cookingDuration: _recipe!.cookingDuration,
                          description: _recipe!.description,
                          servings: _recipe!.servings,
                          ingredients: _recipe!.ingredients,
                          instructions: _recipe!.instructions,
                          nutrition: _recipe!.nutrition,
                          imageUrl: _recipe!.imageUrl,
                          isFavorite: true,
                          videoUrl: _recipe!.videoUrl,
                        );
                        await _saveToCookbook(updatedRecipe);
                        setState(() {}); // Force UI update
                      }
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
                          icon: const Icon(Icons.menu_book),
                          label: const Text('Start Cooking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (_recipe == null) return;
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) {
                                return _StepByStepInstructionsSheet(
                                  instructions: _recipe!.instructions,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    // Video Tutorial Section
                    if (_recipe!.videoUrl != null &&
                        _recipe!.videoUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Video Tutorial',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(_recipe!.videoUrl!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.redAccent,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Watch on YouTube',
                                        style: TextStyle(
                                          color: Colors.redAccent[700],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.open_in_new,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                  ],
                                ),
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

// Step-by-step instructions bottom sheet
class _StepByStepInstructionsSheet extends StatefulWidget {
  final List<String> instructions;
  const _StepByStepInstructionsSheet({required this.instructions});

  @override
  State<_StepByStepInstructionsSheet> createState() =>
      _StepByStepInstructionsSheetState();
}

class _StepByStepInstructionsSheetState
    extends State<_StepByStepInstructionsSheet> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Step-by-Step Instructions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Step ${_currentStep + 1} of ${widget.instructions.length}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            widget.instructions[_currentStep],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _currentStep > 0
                    ? () => setState(() => _currentStep--)
                    : null,
                child: const Text('Previous'),
              ),
              ElevatedButton(
                onPressed: _currentStep < widget.instructions.length - 1
                    ? () => setState(() => _currentStep++)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
