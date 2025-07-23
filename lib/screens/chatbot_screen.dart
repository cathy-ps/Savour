import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savourai/widgets/custom_app_bar.dart';
import '../providers/home_search_provider.dart';
import '../widgets/recipe_card_for_bot.dart';
import 'recipe_detail.dart';
import '../services/gemini_service.dart';
import '../models/recipe_model.dart';
import '../models/cookbook_model.dart';
import 'package:savourai/constant/colors.dart';
import '../providers/chatbot_provider.dart';
import '../providers/saved_recipes_provider.dart';
import '../providers/cookbook_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/cookbook_selector_dialog.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Cookbook and favorite state
  List<Cookbook> _userCookbooks = [];
  List<String> _userCookbookDocIds = [];
  final Map<String, List<String>> _cookbookRecipeIds = {};
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserCookbooks();
    // Add welcome/instruction message at the start of the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatbot = ref.read(chatbotProvider.notifier);
      if (chatbot.state.messages.isEmpty) {
        chatbot.addMessage(
          "👋 Hey! I’m your SavourAI Assistant.\n\nNo clue what to cook? Got some random stuff or leftovers? Just type in your ingredients (like “chicken, rice, peas”) or ask me anything: cooking tips, ingredient swaps, recipe how-tos, whatever.\n\nLet’s make something tasty and clear out that fridge!",
          false,
        );
      }
    });
  }

  Future<void> _fetchUserCookbooks() async {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) return;

    try {
      // Fetch cookbooks
      final cookbooksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('cookbooks')
          .get();

      final cookbooks = cookbooksSnap.docs
          .map((doc) => Cookbook.fromJson(doc.data(), doc.id))
          .toList();

      final docIds = cookbooksSnap.docs.map((doc) => doc.id).toList();

      // Fetch recipe IDs for each cookbook
      final Map<String, List<String>> cookbookRecipeIds = {};
      for (var doc in cookbooksSnap.docs) {
        final recipesSnap = await doc.reference.collection('recipes').get();
        cookbookRecipeIds[doc.id] = recipesSnap.docs.map((r) => r.id).toList();
      }

      // Update local state
      setState(() {
        _userCookbooks = cookbooks;
        _userCookbookDocIds = docIds;
        _cookbookRecipeIds.addAll(cookbookRecipeIds);
      });

      // Update providers
      ref.read(userCookbooksProvider.notifier).state = cookbooks;
      ref.read(userCookbookDocIdsProvider.notifier).state = docIds;
      ref.read(cookbookRecipeIdsProvider.notifier).state = cookbookRecipeIds;

      // Update saved recipe IDs
      final allSavedIds = <String>{};
      for (final ids in cookbookRecipeIds.values) {
        allSavedIds.addAll(ids);
      }
      ref.read(savedRecipeIdsProvider.notifier).state = allSavedIds;
    } catch (e) {
      debugPrint('Error fetching cookbooks: $e');
    }
  }

  String _getRecipeId(Recipe recipe) {
    if (recipe.id.isNotEmpty) return recipe.id;
    if (recipe.title.isNotEmpty) return recipe.title.hashCode.toString();
    return UniqueKey().toString();
  }

  bool _isRecipeSaved(Recipe recipe) {
    final id = _getRecipeId(recipe);
    final savedIds = ref.watch(savedRecipeIdsProvider);
    return savedIds.contains(id);
  }

  Future<void> _onFavoriteTap(Recipe recipe) async {
    if (_userId == null) {
      ShadToaster.maybeOf(context)?.show(
        const ShadToast(
          description: Text('You must be logged in to save recipes'),
        ),
      );
      return;
    }

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
          ShadToaster.maybeOf(context)?.show(
            ShadToast(
              description: Text('Recipe removed from ${cookbook.title}'),
            ),
          );
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
      ShadToaster.maybeOf(
        context,
      )?.show(const ShadToast(description: Text('No cookbooks available')));
      return;
    }

    // Show the selector dialog
    final selectedCookbookId = await showDialog<String>(
      context: context,
      builder: (context) => CookbookSelectorDialog(cookbooks: _userCookbooks),
    );

    if (selectedCookbookId == null || selectedCookbookId.trim().isEmpty) {
      return;
    }

    // Save the recipe to the selected cookbook
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

    // Show toast notification
    final cookbookIdx = _userCookbookDocIds.indexOf(selectedCookbookId);
    if (cookbookIdx != -1) {
      final cookbook = _userCookbooks[cookbookIdx];
      ShadToaster.maybeOf(context)?.show(
        ShadToast(description: Text('Recipe added to ${cookbook.title}')),
      );
    }
  }

  void _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    final chatbot = ref.read(chatbotProvider.notifier);
    chatbot.addMessage(text, true);
    chatbot.setLoading(true);
    _controller.clear();

    // Scroll to bottom
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Simple check: if user input contains commas, treat as ingredients
    if (text.contains(',')) {
      await ref.read(homeSearchProvider.notifier).searchRecipes(text);
      final recipes = ref.read(homeSearchProvider).recipes;
      chatbot.setLastRecipes(recipes);
      chatbot.addMessage(
        recipes.isNotEmpty
            ? 'Here are some recipes you can make!'
            : 'Sorry, I could not find any recipes.',
        false,
      );
    } else {
      // Otherwise, treat as a question for GeminiService
      final gemini = GeminiService();
      try {
        final response = await gemini.getCookingTipOrAnswer(text);
        chatbot.addMessage(response, false);
      } catch (e) {
        chatbot.addMessage(
          'Sorry, I encountered an error processing your request.',
          false,
        );
        debugPrint('Error in Gemini service: $e');
      }
    }

    chatbot.setLoading(false);

    // Scroll to bottom again after new content
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatbotProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'SavourAI Assistant',
        backgroundColor: AppColors.primary,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final msg = state.messages[index];
                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: AppColors.text, fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
          // Recipe suggestions section - fixed at bottom above input
          if (state.lastRecipes.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: AppColors.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                    child: Text(
                      'Recipe Suggestions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: state.lastRecipes.length,
                      itemBuilder: (context, i) {
                        final recipe = state.lastRecipes[i];
                        final isSaved = _isRecipeSaved(recipe);
                        return SizedBox(
                          width: 150,
                          child: RecipeCardForBot(
                            recipe: recipe,
                            imageUrl: recipe.imageUrl,
                            isFavorite: isSaved,
                            onFavoriteTap: () => _onFavoriteTap(recipe),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(
                                    recipe: recipe,
                                    recipeId: recipe.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (state.isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null, // Allow multiple lines
                    minLines: 1, // Start with one line
                    textInputAction: TextInputAction.newline, // Allow new lines
                    keyboardType:
                        TextInputType.multiline, // Enable multiline input
                    decoration: InputDecoration(
                      hintText: 'Type something...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.primary),
                  onPressed: () => _handleSend(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
