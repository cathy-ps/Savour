import 'package:flutter/cupertino.dart';
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
import '../screens/shoppinglist.dart';
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

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  Recipe? _recipe;
  bool _loading = true;
  String? _error;
  late TabController _tabController;
  int _servingCount = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.recipe != null) {
      _recipe = widget.recipe;
      _servingCount = _recipe?.servings ?? 1;
      _loading = false;
    } else {
      _fetchRecipe();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final selectedCookbookId = await CookbookSelectorDialog.show(
      context,
      cookbooks,
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

  Future<void> _addToShoppingList() async {
    if (_recipe == null) return;
    final now = DateTime.now();
    final recipeId = _recipe!.id.isNotEmpty
        ? _recipe!.id
        : _recipe!.title.hashCode.toString();
    final shoppingListId = '${recipeId}_${now.millisecondsSinceEpoch}';
    final shoppingListIngredients = _recipe!.ingredients
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
        description: const Text('Added to shopping list!'),
        action: ShadButton.outline(
          child: const Text('View List'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the toast
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShoppingListScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startCooking() {
    if (_recipe == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _StepByStepInstructionsSheet(
          instructions: _recipe!.instructions,
        );
      },
    );
  }

  // Builds the ingredients content for ShadTabs
  Widget _buildIngredientsContent() {
    // Try to parse quantity as num, fallback to string if not possible
    double ratio = (_recipe?.servings ?? 1) > 0
        ? _servingCount / (_recipe?.servings ?? 1)
        : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _recipe!.ingredients.map((ing) {
          String displayQty = ing.quantity;
          num? qtyNum = num.tryParse(ing.quantity);
          if (qtyNum != null) {
            displayQty = (qtyNum * ratio).toStringAsFixed(
              qtyNum is int ? 0 : 2,
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$displayQty ${ing.unit} ${ing.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Builds the instructions content for ShadTabs
  Widget _buildInstructionsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _recipe!.instructions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
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
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedIds = ref.watch(savedRecipeIdsProvider);
    final recipeKey = _recipe != null ? _recipe!.id : '';
    final isFavorite =
        _recipe != null &&
        (_recipe!.isFavorite || savedIds.contains(recipeKey));
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
                      setState(() {});
                    } else {
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
                        setState(() {});
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
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_recipe!.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: Image.network(
                            _recipe!.imageUrl,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),

                      Padding(
                        // Recipe title and metadata
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and metadata (two by two)
                            Text(
                              _recipe!.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                                bottom: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.timer,
                                          size: 18,
                                          color: AppColors.muted,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '${_recipe!.cookingDuration} min',
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_recipe!.difficulty.isNotEmpty)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.restaurant_menu,
                                            size: 18,
                                            color: AppColors.muted,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _recipe!.difficulty,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  if (_recipe!.category.isNotEmpty)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.category,
                                            size: 18,
                                            color: AppColors.muted,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _recipe!.category,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_recipe!.cuisine.isNotEmpty)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.public,
                                            size: 18,
                                            color: AppColors.muted,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _recipe!.cuisine,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Description section
                            if (_recipe!.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _recipe!.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.text,
                                  height: 1.5,
                                ),
                              ),
                            ],

                            // Nutrition section
                            if (_recipe!.nutrition.calories > 0) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Nutrition Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Serving size controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Serving Size:',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.minus,
                                      size: 18,
                                    ),
                                    onPressed: _servingCount > 1
                                        ? () => setState(() => _servingCount--)
                                        : null,
                                  ),
                                  Text(
                                    '$_servingCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.person_2,
                                    size: 18,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  const SizedBox(width: 5),
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.add,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _servingCount++),
                                  ),
                                ],
                              ),

                              // Nutrition info container
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildNutritionItem(
                                      'Calories',
                                      (_recipe!.nutrition.calories *
                                              (_recipe!.servings > 0
                                                  ? _servingCount /
                                                        _recipe!.servings
                                                  : 1))
                                          .toStringAsFixed(0),
                                    ),
                                    _buildNutritionItem(
                                      'Protein',
                                      '${(_recipe!.nutrition.protein * (_recipe!.servings > 0 ? _servingCount / _recipe!.servings : 1)).toStringAsFixed(1)}g',
                                    ),
                                    _buildNutritionItem(
                                      'Carbs',
                                      '${(_recipe!.nutrition.carbs * (_recipe!.servings > 0 ? _servingCount / _recipe!.servings : 1)).toStringAsFixed(1)}g',
                                    ),
                                    _buildNutritionItem(
                                      'Fat',
                                      '${(_recipe!.nutrition.fat * (_recipe!.servings > 0 ? _servingCount / _recipe!.servings : 1)).toStringAsFixed(1)}g',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 24),

                            // Ingredients and instructions tabs
                            ShadTabs<String>(
                              value: 'ingredients',
                              onChanged: (value) {
                                if (value == 'ingredients') {
                                  _tabController.animateTo(0);
                                } else if (value == 'instructions') {
                                  _tabController.animateTo(1);
                                }
                              },
                              tabBarConstraints: const BoxConstraints(
                                maxWidth: double.infinity,
                              ),
                              contentConstraints: const BoxConstraints(
                                maxWidth: double.infinity,
                              ),
                              tabs: [
                                ShadTab(
                                  value: 'ingredients',
                                  content: ShadCard(
                                    child: _buildIngredientsContent(),
                                  ),
                                  child: const Text('Ingredients'),
                                ),
                                ShadTab(
                                  value: 'instructions',
                                  content: ShadCard(
                                    child: _buildInstructionsContent(),
                                  ),
                                  child: const Text('Instructions'),
                                ),
                              ],
                            ),

                            if (_recipe!.videoUrl != null &&
                                _recipe!.videoUrl!.isNotEmpty) ...[
                              const SizedBox(height: 24),
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
                                  String videoUrl = _recipe!.videoUrl!;
                                  if (!videoUrl.startsWith('https://')) {
                                    videoUrl = 'https://$videoUrl';
                                  }
                                  if (videoUrl.startsWith('youtu.be/')) {
                                    videoUrl =
                                        'https://www.youtube.com/watch?v=${videoUrl.substring(9)}';
                                  } else if (videoUrl.startsWith(
                                    'youtube.com/watch',
                                  )) {
                                    videoUrl = 'https://www.$videoUrl';
                                  }

                                  final url = Uri.parse(videoUrl);
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
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.3,
                                      ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  // Bottom action buttons
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: _addToShoppingList,
                            icon: const Icon(
                              CupertinoIcons.shopping_cart,
                              size: 16,
                            ),
                            label: const Text('Add to List'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppColors.primary),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _startCooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Start Cooking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method to build nutrition info items
  Widget _buildNutritionItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
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
    return SingleChildScrollView(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle at top for dragging
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
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
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Text(
                widget.instructions[_currentStep],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _currentStep > 0
                    ? () => setState(() => _currentStep--)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
                child: const Text('Previous'),
              ),
              ElevatedButton(
                onPressed: _currentStep < widget.instructions.length - 1
                    ? () => setState(() => _currentStep++)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
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
