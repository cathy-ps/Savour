import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cookbook_model.dart';

/// Provider for the list of cookbooks for the current user
final cookbooksProvider = StreamProvider<List<Cookbook>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  final collection = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cookbooks');
  return collection.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => Cookbook.fromJson(doc.data(), doc.id))
        .toList(),
  );
});

/// Notifier for cookbook actions (create, delete, update)
class CookbookActions extends StateNotifier<AsyncValue<void>> {
  CookbookActions() : super(const AsyncData(null));

  Future<void> createCookbook(Cookbook cookbook) async {
    state = const AsyncLoading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cookbooks');
      await collection.add(cookbook.toJson());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteCookbook(String cookbookId) async {
    state = const AsyncLoading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final doc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cookbooks')
          .doc(cookbookId);
      await doc.delete();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final cookbookActionsProvider =
    StateNotifierProvider<CookbookActions, AsyncValue<void>>(
      (ref) => CookbookActions(),
    );
