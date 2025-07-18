class Recipe {
  final String recipeName;
  final String description;
  final String prepTime;
  final String cookTime;
  final String totalTime;
  final String servings;
  final String calories;
  final List<String> ingredients;
  final List<String> instructions;
  final String imagePrompt;
  String? imageUrl;

  Recipe({
    required this.recipeName,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.calories,
    required this.ingredients,
    required this.instructions,
    required this.imagePrompt,
    this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    recipeName: json['recipeName'],
    description: json['description'],
    prepTime: json['prepTime'],
    cookTime: json['cookTime'],
    totalTime: json['totalTime'],
    servings: json['servings'],
    calories: json['calories'],
    ingredients: List<String>.from(json['ingredients']),
    instructions: List<String>.from(json['instructions']),
    imagePrompt: json['imagePrompt'],
    imageUrl: json['imageUrl'],
  );
}
