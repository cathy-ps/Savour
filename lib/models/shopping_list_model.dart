class ShoppingListIngredient {
  final String id;
  final String name;
  final String quantity;
  final String unit;

  ShoppingListIngredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory ShoppingListIngredient.fromJson(Map<String, dynamic> json) =>
      ShoppingListIngredient(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        quantity: json['quantity'] ?? '',
        unit: json['unit'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
  };
}

class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingListIngredient> ingredients;
  final DateTime? reminder;
  final DateTime createdAt;

  ShoppingList({
    required this.id,
    required this.name,
    required this.ingredients,
    this.reminder,
    required this.createdAt,
  });

  int get totalIngredients => ingredients.length;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    ingredients: (json['ingredients'] as List<dynamic>? ?? [])
        .map((x) => ShoppingListIngredient.fromJson(x as Map<String, dynamic>))
        .toList(),
    reminder: json['reminder'] != null
        ? DateTime.tryParse(json['reminder'])
        : null,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ingredients': ingredients.map((x) => x.toJson()).toList(),
    'reminder': reminder?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
}
