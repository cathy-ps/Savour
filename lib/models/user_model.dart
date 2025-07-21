import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  //String id;
  String name;
  DateTime createdAt;
  String email;
  List<String> dietaryPreferences;

  User({
    //required this.id,
    required this.name,
    required this.createdAt,
    required this.email,
    required this.dietaryPreferences,
  });

  factory User.fromJson(Map<String, dynamic> json, String id) {
    return User(
      //id: id,
      name: json['name'] ?? '',
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      email: json['email'] ?? '',
      dietaryPreferences: List<String>.from(json['dietaryPreferences'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt,
      'email': email,
      'dietaryPreferences': dietaryPreferences,
    };
  }
}
