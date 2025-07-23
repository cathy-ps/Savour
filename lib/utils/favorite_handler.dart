import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../models/cookbook_model.dart';
import '../providers/saved_recipes_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/cookbook_selector_dialog.dart';

/// Handles saving/removing a recipe from any cookbook and updates global saved state.
///
/// [context] - BuildContext for showing toasts/snackbars.
/// [ref] - WidgetRef for Riverpod state.
/// [recipe] - The recipe to save/remove.
/// [userId] - The current user's UID.
/// [cookbookRecipeIds] - Map of cookbookId to list of recipeIds (can be null if not needed).
/// [userCookbooks] - List of user's cookbooks (can be null if not needed).
/// [userCookbookDocIds] - List of user's cookbook docIds (can be null if not needed).
/// [showSelector] - If true, will show cookbook selector dialog if not already saved.
Future<void> handleFavoriteTap({
  required BuildContext context,
  required WidgetRef ref,
  required Recipe recipe,
  required String userId,
  required Map<String, List<String>>? cookbookRecipeIds,
  required List<Cookbook>? userCookbooks,
  required List<String>? userCookbookDocIds,
  bool showSelector = true,
}) async {
  final id = recipe.id.isNotEmpty
      ? recipe.id
      : recipe.title.hashCode.toString();
  final savedIds = ref.read(savedRecipeIdsProvider.notifier);
  // Find all cookbooks where this recipe is saved
  final savedCookbookIds =
      cookbookRecipeIds?.entries
          .where((entry) => entry.value.contains(id))
          .map((entry) => entry.key)
          .toList() ??
      [];
  if (savedCookbookIds.isNotEmpty) {
    // Remove from all cookbooks
    for (final cookbookId in savedCookbookIds) {
      final recipeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cookbooks')
          .doc(cookbookId)
          .collection('recipes')
          .doc(id);
      await recipeRef.delete();
      cookbookRecipeIds?[cookbookId]?.remove(id);
      // Show toast for removal
      final cookbookIdx = userCookbookDocIds?.indexOf(cookbookId) ?? -1;
      if (cookbookIdx != -1 && userCookbooks != null) {
        final cookbook = userCookbooks[cookbookIdx];
        final messenger = ShadToaster.maybeOf(context);
        messenger?.show(
          ShadToast(
            description: Text(
              'This recipe has been removed from ${cookbook.title}',
            ),
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
  // Otherwise, prompt user to select a cookbook if allowed
  if (showSelector &&
      (userCookbooks == null ||
          userCookbooks.isEmpty ||
          userCookbookDocIds == null ||
          userCookbookDocIds.isEmpty)) {
    debugPrint('No cookbooks available for selection.');
    return;
  }
  String? selectedCookbookId;
  if (showSelector) {
    selectedCookbookId = await showDialog<String>(
      context: context,
      builder: (context) => CookbookSelectorDialog(cookbooks: userCookbooks!),
    );
    if (selectedCookbookId == null || selectedCookbookId.trim().isEmpty) {
      debugPrint('No valid cookbook ID selected: "$selectedCookbookId"');
      return;
    }
  } else {
    // If not showing selector, use the first cookbook (for detail pages)
    selectedCookbookId = userCookbookDocIds?.isNotEmpty == true
        ? userCookbookDocIds!.first
        : null;
    if (selectedCookbookId == null) {
      debugPrint('No valid cookbook ID available.');
      return;
    }
  }
  // Save the recipe to the selected cookbook's recipes subcollection in Firestore
  final recipeRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('cookbooks')
      .doc(selectedCookbookId)
      .collection('recipes')
      .doc(id);
  await recipeRef.set(recipe.toJson());
  cookbookRecipeIds?[selectedCookbookId] ??= [];
  cookbookRecipeIds?[selectedCookbookId]?.add(id);
  // Update global saved state
  savedIds.update((state) {
    final newSet = Set<String>.from(state);
    newSet.add(id);
    return newSet;
  });
  // Show a toast/snackbar to notify user
  final cookbookIdx = userCookbookDocIds?.indexOf(selectedCookbookId) ?? -1;
  if (cookbookIdx != -1 && userCookbooks != null) {
    final cookbook = userCookbooks[cookbookIdx];
    final messenger = ShadToaster.maybeOf(context);
    messenger?.show(
      ShadToast(
        description: Text('This recipe has been added to ${cookbook.title}'),
      ),
    );
  }
}
