import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ShoppingListIngredient.fromJson(
    Map<String, dynamic> json,
    String id,
  ) => ShoppingListIngredient(
    id: id,
    name: json['name'] ?? '',
    quantity: json['quantity'] ?? '',
    unit: json['unit'] ?? '',
  );

  Map<String, dynamic> toJson() => {
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
  final bool archived;

  ShoppingList({
    required this.id,
    required this.name,
    required this.ingredients,
    this.reminder,
    required this.createdAt,
    this.archived = false,
  });

  int get totalIngredients => ingredients.length;

  factory ShoppingList.fromJson(Map<String, dynamic> json, String id) =>
      ShoppingList(
        id: id,
        name: json['name'] ?? '',
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map(
              (x) => ShoppingListIngredient.fromJson(
                x as Map<String, dynamic>,
                x['id'] ?? '',
              ),
            )
            .toList(),
        reminder: json['reminder'] != null
            ? (json['reminder'] is DateTime
                  ? json['reminder']
                  : (json['reminder'] is String
                        ? DateTime.tryParse(json['reminder'])
                        : (json['reminder'] is Timestamp
                              ? (json['reminder'] as Timestamp).toDate()
                              : null)))
            : null,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        archived: json['archived'] ?? false,
      );

  // For use with Firestore DocumentSnapshot
  static ShoppingList fromFirestore(Map<String, dynamic> json, String docId) =>
      ShoppingList.fromJson(json, docId);

  Map<String, dynamic> toJson() => {
    'name': name,
    'ingredients': ingredients.map((x) => x.toJson()).toList(),
    'reminder': reminder?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'archived': archived,
  };
}
