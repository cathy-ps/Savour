import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../services/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class HomeSearchState {
  final List<Recipe> recipes;
  final bool loading;
  final String? error;
  final String? rawResult;

  HomeSearchState({
    required this.recipes,
    required this.loading,
    this.error,
    this.rawResult,
  });

  HomeSearchState copyWith({
    List<Recipe>? recipes,
    bool? loading,
    String? error,
    String? rawResult,
  }) {
    return HomeSearchState(
      recipes: recipes ?? this.recipes,
      loading: loading ?? this.loading,
      error: error,
      rawResult: rawResult,
    );
  }

  factory HomeSearchState.initial() => HomeSearchState(
    recipes: [],
    loading: false,
    error: null,
    rawResult: null,
  );
}

class HomeSearchNotifier extends StateNotifier<HomeSearchState> {
  final GeminiService _geminiService;
  HomeSearchNotifier(this._geminiService) : super(HomeSearchState.initial());

  Future<void> searchRecipes(String input) async {
    state = state.copyWith(
      loading: true,
      error: null,
      recipes: [],
      rawResult: null,
    );
    try {
      final ingredients = input
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final youtubeApiKey = dotenv.env['youtube_api_key'];
      final recipes = await _geminiService.generateRecipes(
        ingredients,
        youtubeApiKey: youtubeApiKey,
      );
      state = state.copyWith(
        recipes: recipes,
        rawResult: recipes.isNotEmpty
            ? jsonEncode(recipes.map((e) => e.toJson()).toList())
            : null,
        loading: false,
        error: recipes.isEmpty ? 'No recipes generated.' : null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load recipes.', loading: false);
    }
  }

  void clear() {
    state = HomeSearchState.initial();
  }
}

final homeSearchProvider =
    StateNotifierProvider<HomeSearchNotifier, HomeSearchState>((ref) {
      return HomeSearchNotifier(GeminiService());
    });
