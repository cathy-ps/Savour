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
