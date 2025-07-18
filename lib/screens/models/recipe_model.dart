class Recipe {
  final String id;
  final String recipeName;
  final String description;
  final String totalCookingTime;
  final String servings;
  final String calories;
  final List<String> ingredients;
  final List<String> instructions;
  final String imagePrompt;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.recipeName,
    required this.description,
    required this.totalCookingTime,
    required this.servings,
    required this.calories,
    required this.ingredients,
    required this.instructions,
    required this.imagePrompt,
    this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] ?? '',
    recipeName: json['recipeName'] ?? '',
    description: json['description'] ?? '',
    totalCookingTime: json['totalCookingTime'] ?? '',
    servings: json['servings'] ?? '',
    calories: json['calories'] ?? '',
    ingredients: List<String>.from(json['ingredients'] ?? []),
    instructions: List<String>.from(json['instructions'] ?? []),
    imagePrompt: json['imagePrompt'] ?? '',
    imageUrl: json['imageUrl'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipeName': recipeName,
    'description': description,
    'totalCookingTime': totalCookingTime,
    'servings': servings,
    'calories': calories,
    'ingredients': ingredients,
    'instructions': instructions,
    'imagePrompt': imagePrompt,
    'imageUrl': imageUrl,
  };
}

class RecipeRequest {
  final String ingredients;

  RecipeRequest({required this.ingredients});

  factory RecipeRequest.fromJson(Map<String, dynamic> json) =>
      RecipeRequest(ingredients: json['ingredients'] ?? '');

  Map<String, dynamic> toJson() => {'ingredients': ingredients};
}

class Cookbook {
  final String id;
  final String name;
  final List<String> recipeIds;

  Cookbook({required this.id, required this.name, required this.recipeIds});

  factory Cookbook.fromJson(Map<String, dynamic> json) => Cookbook(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    recipeIds: List<String>.from(json['recipeIds'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'recipeIds': recipeIds,
  };
}

class ShoppingListItem {
  final String id;
  final String name;
  final bool checked;

  ShoppingListItem({
    required this.id,
    required this.name,
    required this.checked,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      ShoppingListItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        checked: json['checked'] ?? false,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'checked': checked};
}

class ShoppingList {
  final String id;
  final String recipeId;
  final String recipeName;
  final List<ShoppingListItem> items;
  final String? reminder;

  ShoppingList({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.items,
    this.reminder,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
    id: json['id'] ?? '',
    recipeId: json['recipeId'] ?? '',
    recipeName: json['recipeName'] ?? '',
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    reminder: json['reminder'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipeId': recipeId,
    'recipeName': recipeName,
    'items': items.map((e) => e.toJson()).toList(),
    'reminder': reminder,
  };
}
