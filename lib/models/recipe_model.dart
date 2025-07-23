class Recipe {
  final String id;
  final String title;
  final String category; // e.g., breakfast, lunch, dinner, snack, dessert
  final String cuisine;
  final String difficulty; // easy, medium, hard
  final int cookingDuration; // in minutes
  final String description;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final Nutrition nutrition;
  final String imageUrl;
  final bool isFavorite;
  final String? videoUrl;
  final DateTime createdAt; // New field for tracking when recipes are saved

  Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.cuisine,
    required this.difficulty,
    required this.cookingDuration,
    required this.description,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.nutrition,
    required this.imageUrl,
    this.isFavorite = false,
    this.videoUrl,
    DateTime? createdAt, // Optional parameter with default value
  }) : createdAt =
           createdAt ??
           DateTime.now(); // Default to current time if not provided

  factory Recipe.fromJson(Map<String, dynamic> json, String id) => Recipe(
    id: id,
    title: json['title'] ?? '',
    category: json['category'] ?? '',
    cuisine: json['cuisine'] ?? '',
    difficulty: json['difficulty'] ?? '',
    cookingDuration: json['cooking_duration'] is int
        ? json['cooking_duration']
        : int.tryParse(json['cooking_duration']?.toString() ?? '') ?? 0,
    description: json['description'] ?? '',
    servings: json['servings'] is int
        ? json['servings']
        : int.tryParse(json['servings']?.toString() ?? '') ?? 1,
    ingredients: (json['ingredients'] as List<dynamic>? ?? [])
        .map((x) => RecipeIngredient.fromJson(x as Map<String, dynamic>))
        .toList(),
    instructions: (json['instructions'] as List<dynamic>? ?? [])
        .map((x) => x.toString())
        .toList(),
    nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
    imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
    isFavorite: json['isFavorite'] is bool
        ? json['isFavorite']
        : (json['isFavorite'] == null
              ? false
              : json['isFavorite'].toString() == 'true'),
    videoUrl: json['videoUrl'] ?? json['video_url'],
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] is String
              ? DateTime.tryParse(json['createdAt'])
              : (json['createdAt'] as DateTime))
        : DateTime.now(),
  );

  // For use with Firestore DocumentSnapshot
  static Recipe fromFirestore(Map<String, dynamic> json, String docId) =>
      Recipe.fromJson(json, docId);

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'cuisine': cuisine,
    'difficulty': difficulty,
    'cooking_duration': cookingDuration,
    'description': description,
    'servings': servings,
    'ingredients': ingredients.map((x) => x.toJson()).toList(),
    'instructions': instructions,
    'nutrition': nutrition.toJson(),
    'imageUrl': imageUrl,
    'isFavorite': isFavorite,
    if (videoUrl != null) 'videoUrl': videoUrl,
    'createdAt': createdAt.toIso8601String(),
  };
}

class Nutrition {
  final num calories;
  final num protein;
  final num carbs;
  final num fat;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
    calories: json['calories'] is num
        ? json['calories']
        : num.tryParse(json['calories']?.toString() ?? '') ?? 0,
    protein: json['protein'] is num
        ? json['protein']
        : num.tryParse(json['protein']?.toString() ?? '') ?? 0,
    carbs: json['carbs'] is num
        ? json['carbs']
        : num.tryParse(json['carbs']?.toString() ?? '') ?? 0,
    fat: json['fat'] is num
        ? json['fat']
        : num.tryParse(json['fat']?.toString() ?? '') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}

class RecipeIngredient {
  final String name;
  final String quantity;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: (json['name'] ?? '').toString(),
        quantity: (json['quantity'] ?? json['amount'] ?? '').toString(),
        unit: (json['unit'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
  };
}
