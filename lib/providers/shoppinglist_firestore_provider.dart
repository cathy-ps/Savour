import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_list_model.dart';

Future<void> updateShoppingListReminder(String id, DateTime reminder) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('shoppingLists')
      .doc(id);
  await ref.update({'reminder': reminder.toIso8601String()});
}

final shoppingListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  final snapStream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('shoppingLists')
      .orderBy('createdAt', descending: true)
      .snapshots();
  return snapStream.map(
    (snap) => snap.docs
        .map(
          (doc) => ShoppingList.fromJson({...doc.data(), 'id': doc.id}, doc.id),
        )
        .where((list) => !list.archived)
        .toList(),
  );
});

Future<void> addShoppingList(ShoppingList list) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('shoppingLists')
      .doc(list.id);
  await ref.set(list.toJson());
}

Future<void> deleteShoppingList(String id) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('shoppingLists')
      .doc(id);
  await ref.delete();
}
