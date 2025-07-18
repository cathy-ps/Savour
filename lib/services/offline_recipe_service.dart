import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/recipe_card.dart';

class OfflineRecipeService {
  static const String _key = 'offline_recipes';

  Future<List<Recipe>> getOfflineRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) => Recipe.fromJson(jsonDecode(e))).toList();
  }

  Future<void> saveRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    final recipeJson = jsonEncode(recipe.toJson());
    if (!data.contains(recipeJson)) {
      data.add(recipeJson);
      await prefs.setStringList(_key, data);
    }
  }

  Future<void> removeRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    data.removeWhere(
      (e) => Recipe.fromJson(jsonDecode(e)).recipeName == recipe.recipeName,
    );
    await prefs.setStringList(_key, data);
  }

  Future<bool> isRecipeSaved(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.any(
      (e) => Recipe.fromJson(jsonDecode(e)).recipeName == recipe.recipeName,
    );
  }
}
