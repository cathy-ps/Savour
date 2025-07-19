import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';

// Holds the list of generated recipes
final recipeListProvider = StateProvider<List<Recipe>>((ref) => []);

// Holds the set of favorite recipe IDs
final favoriteRecipeIdsProvider = StateProvider<Set<String>>((ref) => {});
