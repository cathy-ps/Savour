import 'package:flutter/material.dart';
import 'package:savourai/constant/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savourai/widgets/custom_search_bar.dart';
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
import 'package:shadcn_ui/shadcn_ui.dart';

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
    final selectedCookbookId = await showDialog<String>(
      context: context,
      builder: (context) => CookbookSelectorDialog(
        cookbooks: _userCookbooks,
        //cookbookDocIds: _userCookbookDocIds,
      ),
    );

    if (selectedCookbookId == null || selectedCookbookId.trim().isEmpty) {
      debugPrint('No valid cookbook ID selected: "$selectedCookbookId"');
      return;
    }
    // print('userId: $_userId');
    // print('selectedCookbookId: $selectedCookbookId');
    // print('recipeId: $id');

    // Save the recipe to the selected cookbook's recipes subcollection in Firestore
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
  }

  void _searchRecipes() {
    ref.read(homeSearchProvider.notifier).searchRecipes(_searchController.text);
  }

  // void _testImmediateNotification() async {
  //   try {
  //     // Check notification permission first
  //     final status = await Permission.notification.status;
  //     print('[DEBUG] Notification permission status: $status');

  //     if (status.isDenied) {
  //       print('[DEBUG] Requesting notification permission...');
  //       final result = await Permission.notification.request();
  //       print('[DEBUG] Permission request result: $result');
  //       if (result.isDenied) {
  //         if (mounted) {
  //           final messenger = ShadToaster.maybeOf(context);
  //           if (messenger != null) {
  //             messenger.show(
  //               const ShadToast(
  //                 description: Text(
  //                   'Please enable notifications in settings to receive reminders.',
  //                 ),
  //               ),
  //             );
  //           }
  //         }
  //         return;
  //       }
  //     }

  //     // Try immediate notification first
  //     final int immediateId =
  //         DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
  //     print('[DEBUG] Trying immediate notification first...');
  //     await showImmediateNotification(
  //       immediateId,
  //       'This is an immediate test notification!',
  //     );

  //     // Then try scheduled notification
  //     final now = DateTime.now().add(
  //       const Duration(seconds: 10),
  //     ); // Increased to 10 seconds
  //     final int scheduledId = now.millisecondsSinceEpoch & 0x7FFFFFFF;

  //     print('[DEBUG] Then trying scheduled notification...');
  //     await scheduleReminderNotification(
  //       scheduledId,
  //       now,
  //       'This is a scheduled test notification!',
  //     );

  //     final messenger = ShadToaster.maybeOf(context);
  //     if (mounted && messenger != null) {
  //       messenger.show(
  //         const ShadToast(
  //           description: Text(
  //             'Test notifications sent - check your notification shade!',
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e, stackTrace) {
  //     print('[ERROR] Failed to send notifications: $e');
  //     print('[ERROR] Stack trace: $stackTrace');

  //     if (mounted) {
  //       final messenger = ShadToaster.maybeOf(context);
  //       if (messenger != null) {
  //         messenger.show(
  //           ShadToast(description: Text('Failed to send notifications: $e')),
  //         );
  //       }
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(homeSearchProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
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
            return SingleChildScrollView(
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
                                  'What ingredients do you have?',
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
                        const SizedBox(height: 20),
                        CustomSearchBar(
                          controller: _searchController,
                          hintText: 'e.g. eggs, rice, etc',
                          submitIcon: const Icon(
                            Icons.rocket_launch_outlined,
                            size: 24,
                          ),
                          onSubmit: _searchRecipes,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (searchState.loading)
                    const Center(child: CircularProgressIndicator()),
                  if (searchState.error != null)
                    Center(
                      child: Text(
                        searchState.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (searchState.rawResult != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,

                        //raw text for debugging purposes
                        // child: Container(
                        //   color: AppColors.card,
                        //   padding: const EdgeInsets.all(12),
                        //   child: Text(
                        //     searchState.rawResult!,
                        //     style: const TextStyle(
                        //       fontFamily: 'monospace',
                        //       fontSize: 13,
                        //       color: AppColors.text,
                        //     ),
                        //   ),
                        // ),
                      ),
                    ),
                  if (searchState.recipes.isNotEmpty)
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
                        itemCount: searchState.recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = searchState.recipes[index];
                          return InkWell(
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
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: _testImmediateNotification,
        //   tooltip: 'Test Notification',
        //   child: const Icon(Icons.notifications_active),
        // ),
      ),
    );
  }
}
