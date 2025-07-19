import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the set of all saved recipe IDs (across all cookbooks)
final savedRecipeIdsProvider = StateProvider<Set<String>>((ref) => {});
