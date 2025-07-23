import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cookbook_model.dart';

/// Provider for the current user ID
final userIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Provider for cookbook recipe IDs (map of cookbookId to list of recipeIds)
final cookbookRecipeIdsProvider = StateProvider<Map<String, List<String>>>(
  (ref) => {},
);

/// Provider for user cookbooks
final userCookbooksProvider = StateProvider<List<Cookbook>>((ref) => []);

/// Provider for user cookbook document IDs
final userCookbookDocIdsProvider = StateProvider<List<String>>((ref) => []);
