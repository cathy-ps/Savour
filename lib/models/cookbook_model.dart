import 'package:cloud_firestore/cloud_firestore.dart';

class Cookbook {
  String id;
  String title;
  DateTime createdAt;
  int recipeCount;
  int color;

  Cookbook({
    required this.id,
    required this.title,
    required this.createdAt,
    this.recipeCount = 0,
    required this.color,
  });

  // Factory constructor to create a Cookbook instance from JSON
  // and a document ID (for Firestore)
  factory Cookbook.fromJson(Map<String, dynamic> json, String id) {
    return Cookbook(
      id: id,
      title: json['title'] ?? '',
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      recipeCount: json['recipeCount'] ?? 0,
      color: json['color'] ?? 0xFF2196F3, // Default to blue if not set
    );
  }

  // For use with Firestore DocumentSnapshot
  static Cookbook fromFirestore(Map<String, dynamic> json, String docId) =>
      Cookbook.fromJson(json, docId);

  // Method to convert a Cookbook instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'createdAt': createdAt,
      'recipeCount': recipeCount,
      'color': color,
    };
  }
}
