import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' as app_user;

final userProfileProvider = FutureProvider<app_user.User?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  if (!doc.exists) return null;
  final data = doc.data();
  if (data == null) return null;
  // Use the User model for mapping
  return app_user.User.fromJson(data, user.uid);
});

// /// Update both name and dietary preferences (batch update)
// Future<void> updateUserProfile({
//   required String name,
//   required List<String> dietaryPreferences,
// }) async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) return;
//   final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
//   await doc.update({'name': name, 'dietaryPreferences': dietaryPreferences});
// }

/// Update only the user's name
Future<void> updateUserName(String name) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  await doc.update({'name': name});
}

/// Update only the user's dietary preferences
Future<void> updateUserDietaryPreferences(
  List<String> dietaryPreferences,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  await doc.update({'dietaryPreferences': dietaryPreferences});
}

/// Change the user's password (Firebase Auth)
Future<void> changeUserPassword(String newPassword) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await user.updatePassword(newPassword);
}
