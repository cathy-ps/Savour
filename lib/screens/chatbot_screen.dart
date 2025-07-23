import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_search_provider.dart';
import '../widgets/recipe_card_for_bot.dart';
import 'recipe_detail.dart';
import '../services/gemini_service.dart';
import '../models/recipe_model.dart';
import '../models/cookbook_model.dart';
import 'package:savourai/constant/colors.dart';
import '../providers/chatbot_provider.dart';
import '../providers/saved_recipes_provider.dart';
import '../utils/favorite_handler.dart';
import '../providers/cookbook_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUserCookbooks();
  }

  Future<void> _fetchUserCookbooks() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Fetch cookbooks
      final cookbooksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
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

      // Update providers
      ref.read(userCookbooksProvider.notifier).state = cookbooks;
      ref.read(userCookbookDocIdsProvider.notifier).state = docIds;
      ref.read(cookbookRecipeIdsProvider.notifier).state = cookbookRecipeIds;
    } catch (e) {
      debugPrint('Error fetching cookbooks: $e');
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
    final savedRecipeIds = ref.watch(savedRecipeIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SavourAI Assistant'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount:
                  state.messages.length +
                  (state.lastRecipes.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < state.messages.length) {
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
                } else {
                  // Recipe suggestions section
                  return Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    color: AppColors.secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12.0,
                            bottom: 8.0,
                          ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            itemCount: state.lastRecipes.length,
                            itemBuilder: (context, i) {
                              final recipe = state.lastRecipes[i];
                              return SizedBox(
                                width: 150,
                                child: RecipeCardForBot(
                                  recipe: recipe,
                                  imageUrl: recipe.imageUrl,
                                  isFavorite: savedRecipeIds.contains(
                                    recipe.id,
                                  ),
                                  onFavoriteTap: () async {
                                    await handleFavoriteTap(
                                      context: context,
                                      ref: ref,
                                      recipe: recipe,
                                      userId: ref.read(userIdProvider) ?? '',
                                      cookbookRecipeIds: ref.read(
                                        cookbookRecipeIdsProvider,
                                      ),
                                      userCookbooks: ref.read(
                                        userCookbooksProvider,
                                      ),
                                      userCookbookDocIds: ref.read(
                                        userCookbookDocIdsProvider,
                                      ),
                                    );
                                  },
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecipeDetailScreen(
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
                  );
                }
              },
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText:
                          'Type ingredients (comma separated) or ask a question...',
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
                    ),
                    onSubmitted: _handleSend,
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
