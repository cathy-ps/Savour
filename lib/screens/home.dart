import 'package:flutter/material.dart';
import 'package:savourai/constant/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'settings.dart';

import 'package:savourai/models/recipe_model.dart';
import 'package:savourai/models/cookbook_model.dart';
import 'package:savourai/widgets/recipe_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savourai/widgets/cookbook_selector_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_profile_provider.dart';

import '../providers/saved_recipes_provider.dart';
import '../providers/home_search_provider.dart';
import 'package:savourai/screens/recipe_detail.dart';
import '../providers/shoppinglist_firestore_provider.dart';
import '../widgets/reminder_card.dart';
import '../services/gemini_service.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import 'chatbot_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Cookbook and favorite state
  List<Cookbook> _userCookbooks = [];
  List<String> _userCookbookDocIds = [];
  final Map<String, List<String>> _cookbookRecipeIds = {};
  String? _userId;
  List<Recipe> _suggestedRecipes = [];
  List<Recipe> _recentSavedRecipes = [];
  bool _loadingSuggestions = false;
  String _suggestionsError = '';

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

  @override
  void initState() {
    super.initState();
    _fetchUserCookbooks();
    _fetchRecentSavedRecipes();
    // Using Gemini API for suggestions based on dietary preferences
    _fetchGeminiSuggestions();
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
    final docIds = cookbooksSnap.docs.map((doc) => doc.id).toList();
    setState(() {
      _userCookbooks = cookbooks;
      _userCookbookDocIds = docIds;
    });
    for (var doc in cookbooksSnap.docs) {
      final recipesSnap = await doc.reference.collection('recipes').get();
      _cookbookRecipeIds[doc.id] = recipesSnap.docs.map((r) => r.id).toList();
    }
  }

  Future<void> _fetchGeminiSuggestions() async {
    if (_loadingSuggestions) return;

    setState(() {
      _loadingSuggestions = true;
      _suggestionsError = '';
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _loadingSuggestions = false;
          _suggestionsError = 'User not logged in';
        });
        return;
      }

      // Get user's dietary preferences
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _loadingSuggestions = false;
        });
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        setState(() {
          _loadingSuggestions = false;
        });
        return;
      }

      final dietaryPreferences = List<String>.from(
        userData['dietaryPreferences'] ?? [],
      );

      // Use Gemini to get personalized suggestions
      final geminiService = GeminiService();
      final suggestions = await geminiService.getDietaryPreferenceRecipes(
        dietaryPreferences,
      );

      setState(() {
        _suggestedRecipes = suggestions;
        _loadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _loadingSuggestions = false;
        _suggestionsError = 'Error fetching suggestions: $e';
      });
      debugPrint('Error fetching Gemini suggestions: $e');
    }
  }

  Future<void> _fetchRecentSavedRecipes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Get all cookbooks
      final cookbooksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cookbooks')
          .get();

      List<Recipe> allSavedRecipes = [];

      // Get recipes from each cookbook
      for (final cookbookDoc in cookbooksSnap.docs) {
        final recipesSnap = await cookbookDoc.reference
            .collection('recipes')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        final recipes = recipesSnap.docs
            .map((doc) => Recipe.fromJson(doc.data(), doc.id))
            .toList();

        allSavedRecipes.addAll(recipes);
      }

      // Sort by created date
      allSavedRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Take most recent recipes
      final recentRecipes = allSavedRecipes.take(10).toList();

      setState(() {
        _recentSavedRecipes = recentRecipes;
      });
    } catch (e) {
      debugPrint('Error fetching recent saved recipes: $e');
    }
  }

  String _getRecipeId(Recipe recipe) {
    if (recipe.id.isNotEmpty) return recipe.id;
    if (recipe.title.isNotEmpty) return recipe.title.hashCode.toString();
    return UniqueKey().toString();
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
        // Show toast for removal
        final cookbookIdx = _userCookbookDocIds.indexOf(cookbookId);
        if (cookbookIdx != -1) {
          final cookbook = _userCookbooks[cookbookIdx];
          final messenger = ShadToaster.maybeOf(context);
          if (messenger != null) {
            messenger.show(
              ShadToast(
                description: Text(
                  'This recipe has been removed from ${cookbook.title}',
                ),
              ),
            );
          }
        }
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
    if (_userCookbooks.isEmpty || _userCookbookDocIds.isEmpty) {
      debugPrint('No cookbooks available for selection.');
      return;
    }
    // Show the selector dialog and get the selected cookbook's docId
    final selectedCookbookId = await CookbookSelectorDialog.show(
      context,
      _userCookbooks,
    );

    if (selectedCookbookId == null || selectedCookbookId.trim().isEmpty) {
      debugPrint('No valid cookbook ID selected: "$selectedCookbookId"');
      return;
    }
    // print('userId: $_userId');
    // print('selectedCookbookId: $selectedCookbookId');
    // print('recipeId: $id');

    // Create a copy of the recipe with current timestamp
    final recipeWithTimestamp = Recipe(
      id: recipe.id,
      title: recipe.title,
      category: recipe.category,
      cuisine: recipe.cuisine,
      difficulty: recipe.difficulty,
      cookingDuration: recipe.cookingDuration,
      description: recipe.description,
      servings: recipe.servings,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      nutrition: recipe.nutrition,
      imageUrl: recipe.imageUrl,
      isFavorite: true,
      videoUrl: recipe.videoUrl,
      createdAt: DateTime.now(), // Set the current timestamp
    );

    // Save the recipe to the selected cookbook's recipes subcollection in Firestore
    final recipeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('cookbooks')
        .doc(selectedCookbookId)
        .collection('recipes')
        .doc(id);

    await recipeRef.set(recipeWithTimestamp.toJson());
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

    // Show a toast/snackbar to notify user
    final cookbookIdx = _userCookbookDocIds.indexOf(selectedCookbookId);
    if (cookbookIdx != -1) {
      final cookbook = _userCookbooks[cookbookIdx];
      final messenger = ShadToaster.maybeOf(context);
      if (messenger != null) {
        messenger.show(
          ShadToast(
            description: Text(
              'This recipe has been added to ${cookbook.title}',
            ),
          ),
        );
      }
    }

    // Refresh the recent recipes list to include the newly saved recipe
    _fetchRecentSavedRecipes();
  }

  void _searchRecipes() {
    ref.read(homeSearchProvider.notifier).searchRecipes(_searchController.text);
  }

  Widget _buildHorizontalRecipeList(
    List<Recipe> recipes,
    String title, {
    String? emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: recipes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      emptyMessage ?? 'No recipes available',
                      style: const TextStyle(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 16),
                      child: InkWell(
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
                          imageUrl: recipe.imageUrl,
                          isFavorite:
                              recipe.isFavorite ||
                              _isRecipeSavedGlobally(recipe),
                          onFavoriteTap: () => _onFavoriteTap(recipe),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(homeSearchProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: userProfileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error loading user: $e')),
          data: (user) {
            final userName = (user?.name.isNotEmpty ?? false)
                ? user!.name
                : (user?.email.isNotEmpty ?? false)
                ? user!.email.split('@')[0]
                : '';
            return RefreshIndicator(
              onRefresh: () async {
                // Refresh all data when user pulls down
                await Future.wait([
                  _fetchUserCookbooks(),
                  _fetchGeminiSuggestions(),
                  _fetchRecentSavedRecipes(),
                ]);
              },
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
                                    '${_getGreeting()}, $userName',
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'What would you like today?',
                                    style: TextStyle(
                                      color: AppColors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsScreen(),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  radius: 24,
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Comment out the search bar
                          // const SizedBox(height: 20),
                          // CustomSearchBar(
                          //   controller: _searchController,
                          //   hintText: 'e.g. eggs, rice, etc',
                          //   submitIcon: const Icon(
                          //     Icons.rocket_launch_outlined,
                          //     size: 24,
                          //   ),
                          //   onSubmit: _searchRecipes,
                          // ),
                        ],
                      ),
                    ),

                    // Reminders Section
                    shoppingListsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, st) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error loading reminders: $e'),
                        ),
                      ),
                      data: (shoppingLists) {
                        // Debug the shopping lists
                        print('Shopping lists count: ${shoppingLists.length}');
                        shoppingLists.forEach((list) {
                          print(
                            'List ${list.id}: ${list.name}, Reminder: ${list.reminder}',
                          );
                        });

                        final listsWithReminders = shoppingLists
                            .where((list) => list.reminder != null)
                            .toList();

                        print(
                          'Lists with reminders: ${listsWithReminders.length}',
                        );

                        if (listsWithReminders.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              // child: Text(
                              //   'Reminders',
                              //   style: TextStyle(
                              //     fontSize: 20,
                              //     fontWeight: FontWeight.bold,
                              //     color: AppColors.text,
                              //   ),
                              // ),
                            ),
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: listsWithReminders.length,
                                itemBuilder: (context, index) {
                                  return ReminderCard(
                                    shoppingList: listsWithReminders[index],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    // Suggestions section based on dietary preferences
                    _loadingSuggestions
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _suggestionsError.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Error: $_suggestionsError',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          )
                        : _buildHorizontalRecipeList(
                            _suggestedRecipes,
                            'Suggestions for You',
                            emptyMessage:
                                'No suggestions available. Please set your dietary preferences in settings.',
                          ),

                    const SizedBox(height: 16),

                    // Recently saved recipes section
                    _buildHorizontalRecipeList(
                      _recentSavedRecipes,
                      'Your Recent Recipes',
                      emptyMessage:
                          'No saved recipes found. Try searching for some recipes and save them to your cookbooks!',
                    ),

                    const SizedBox(height: 24),

                    // If search is active, show search results (commented out recipes)
                    if (searchState.loading)
                      const Center(child: CircularProgressIndicator()),
                    if (searchState.error != null)
                      Center(
                        child: Text(
                          searchState.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    // Comment out search results
                    // if (searchState.recipes.isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 12,
                    //       vertical: 8,
                    //     ),
                    //     child: GridView.builder(
                    //       shrinkWrap: true,
                    //       physics: const NeverScrollableScrollPhysics(),
                    //       gridDelegate:
                    //           const SliverGridDelegateWithFixedCrossAxisCount(
                    //             crossAxisCount: 2,
                    //             crossAxisSpacing: 12,
                    //             mainAxisSpacing: 12,
                    //             childAspectRatio: 0.7,
                    //           ),
                    //       itemCount: searchState.recipes.length,
                    //       itemBuilder: (context, index) {
                    //         final recipe = searchState.recipes[index];
                    //         return InkWell(
                    //           borderRadius: BorderRadius.circular(16),
                    //           onTap: () {
                    //             Navigator.of(context).push(
                    //               MaterialPageRoute(
                    //                 builder: (context) => RecipeDetailScreen(
                    //                   recipe: recipe,
                    //                   recipeId: _getRecipeId(recipe),
                    //                 ),
                    //               ),
                    //             );
                    //           },
                    //           child: RecipeCard(
                    //             recipe: recipe,
                    //             imageUrl: recipe.imageUrl,
                    //             isFavorite:
                    //                 recipe.isFavorite ||
                    //                 _isRecipeSavedGlobally(recipe),
                    //             onFavoriteTap: () => _onFavoriteTap(recipe),
                    //           ),
                    //         );
                    //       },
                    //     ),
                    //   ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        backgroundColor: AppColors.transparent,
        child: Lottie.asset(
          'assets/images/chatbot.json',
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}
