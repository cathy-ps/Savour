import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savourai/models/recipe_model.dart';

import '../services/gemini_service.dart';
import '../services/pexels_service.dart';

class RecipeState {
  final List<Recipe> suggestions;
  final List<Recipe> recentSaved;
  final Map<String, List<Recipe>> cookbookRecipes;
  final bool loadingSuggestions;
  final String suggestionsError;
  final bool loadingRecent;
  final String recentError;

  RecipeState({
    this.suggestions = const [],
    this.recentSaved = const [],
    this.cookbookRecipes = const {},
    this.loadingSuggestions = false,
    this.suggestionsError = '',
    this.loadingRecent = false,
    this.recentError = '',
  });

  RecipeState copyWith({
    List<Recipe>? suggestions,
    List<Recipe>? recentSaved,
    Map<String, List<Recipe>>? cookbookRecipes,
    bool? loadingSuggestions,
    String? suggestionsError,
    bool? loadingRecent,
    String? recentError,
  }) {
    return RecipeState(
      suggestions: suggestions ?? this.suggestions,
      recentSaved: recentSaved ?? this.recentSaved,
      cookbookRecipes: cookbookRecipes ?? this.cookbookRecipes,
      loadingSuggestions: loadingSuggestions ?? this.loadingSuggestions,
      suggestionsError: suggestionsError ?? this.suggestionsError,
      loadingRecent: loadingRecent ?? this.loadingRecent,
      recentError: recentError ?? this.recentError,
    );
  }
}

class RecipeNotifier extends StateNotifier<RecipeState> {
  RecipeNotifier() : super(RecipeState());

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> fetchSuggestions(List<String> dietaryPreferences) async {
    if (state.loadingSuggestions) return;
    state = state.copyWith(loadingSuggestions: true, suggestionsError: '');
    try {
      final geminiService = GeminiService();
      final googleImageApiKey = dotenv.env['custom_api_key'] ?? '';
      geminiService.setPexelsService(PexelsService());
      if (googleImageApiKey.isNotEmpty) {
        geminiService.setGoogleImageApiKey(googleImageApiKey);
      }
      final suggestions = await geminiService.getDietaryPreferenceRecipes(
        dietaryPreferences,
      );
      state = state.copyWith(
        suggestions: suggestions,
        loadingSuggestions: false,
      );
    } catch (e) {
      state = state.copyWith(
        loadingSuggestions: false,
        suggestionsError: 'Error fetching suggestions: $e',
      );
    }
  }

  Future<void> fetchRecentSaved() async {
    if (_userId == null) return;
    state = state.copyWith(loadingRecent: true, recentError: '');
    try {
      final cookbooksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('cookbooks')
          .get();
      List<Recipe> allSavedRecipes = [];
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
      allSavedRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentRecipes = allSavedRecipes.take(10).toList();
      final recentRecipesWithFavorite = recentRecipes
          .map(
            (recipe) =>
                recipe.isFavorite ? recipe : recipe.copyWith(isFavorite: true),
          )
          .toList();
      state = state.copyWith(
        recentSaved: recentRecipesWithFavorite,
        loadingRecent: false,
      );
    } catch (e) {
      state = state.copyWith(
        loadingRecent: false,
        recentError: 'Error fetching recent saved: $e',
      );
    }
  }

  Future<void> fetchCookbookRecipes(String cookbookId) async {
    if (_userId == null) return;
    try {
      final recipesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('cookbooks')
          .doc(cookbookId)
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .get();
      final recipes = recipesSnap.docs
          .map((doc) => Recipe.fromJson(doc.data(), doc.id))
          .toList();
      final updated = Map<String, List<Recipe>>.from(state.cookbookRecipes);
      updated[cookbookId] = recipes;
      state = state.copyWith(cookbookRecipes: updated);
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<Recipe?> fetchRecipeById(String cookbookId, String recipeId) async {
    if (_userId == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('cookbooks')
          .doc(cookbookId)
          .collection('recipes')
          .doc(recipeId)
          .get();
      if (doc.exists) {
        return Recipe.fromJson(doc.data()!, doc.id);
      }
    } catch (e) {}
    return null;
  }

  Future<void> saveRecipeToCookbook(Recipe recipe, String cookbookId) async {
    if (_userId == null) return;
    final recipeWithTimestamp = recipe.copyWith(
      isFavorite: true,
      createdAt: DateTime.now(),
    );
    final recipeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('cookbooks')
        .doc(cookbookId)
        .collection('recipes')
        .doc(recipe.id);
    await recipeRef.set(recipeWithTimestamp.toJson());
    await fetchCookbookRecipes(cookbookId);
    await fetchRecentSaved();
  }

  Future<void> unsaveRecipeFromAllCookbooks(String recipeId) async {
    if (_userId == null) return;
    final cookbooksSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('cookbooks')
        .get();
    for (final cookbookDoc in cookbooksSnap.docs) {
      final recipeRef = cookbookDoc.reference
          .collection('recipes')
          .doc(recipeId);
      final doc = await recipeRef.get();
      if (doc.exists) {
        await recipeRef.delete();
        await fetchCookbookRecipes(cookbookDoc.id);
      }
    }
    await fetchRecentSaved();
  }

  Future<void> refreshAll(List<String> dietaryPreferences) async {
    await Future.wait([
      fetchSuggestions(dietaryPreferences),
      fetchRecentSaved(),
    ]);
  }
}

final recipeProvider = StateNotifierProvider<RecipeNotifier, RecipeState>(
  (ref) => RecipeNotifier(),
);
