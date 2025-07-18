import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cookbook_detail_screen.dart';

class Cookbook {
  final String id;
  final String name;
  Cookbook({required this.id, required this.name});
  factory Cookbook.fromFirestore(DocumentSnapshot doc) =>
      Cookbook(id: doc.id, name: doc['title'] ?? doc['name'] ?? doc.id);
}

final cookbookProvider =
    StateNotifierProvider<CookbookNotifier, AsyncValue<List<Cookbook>>>((ref) {
      return CookbookNotifier();
    });

class CookbookNotifier extends StateNotifier<AsyncValue<List<Cookbook>>> {
  CookbookNotifier() : super(const AsyncValue.loading()) {
    loadCookbooks();
  }

  final _prefsKey = 'cookbooks_cache';

  Future<void> loadCookbooks() async {
    // Try to load from cache first
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      final decoded = (jsonDecode(cached) as List)
          .map((e) => Cookbook(id: e['id'], name: e['name']))
          .toList();
      state = AsyncValue.data(decoded);
    }
    // Always fetch from Firestore for latest
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cookbooks')
          .get();
      final cookbooks = snap.docs
          .map((doc) => Cookbook.fromFirestore(doc))
          .toList();
      state = AsyncValue.data(cookbooks);
      // Save to cache
      await prefs.setString(
        _prefsKey,
        jsonEncode(cookbooks.map((e) => {'id': e.id, 'name': e.name}).toList()),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCookbook(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || name.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .add({'title': name.trim()});
    await loadCookbooks();
  }

  Future<void> deleteCookbook(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc(id)
        .delete();
    await loadCookbooks();
  }
}

class CookbookScreen extends ConsumerWidget {
  const CookbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookbooksAsync = ref.watch(cookbookProvider);
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Cookbooks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'New cookbook name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: cookbooksAsync.isLoading
                      ? null
                      : () async {
                          await ref
                              .read(cookbookProvider.notifier)
                              .addCookbook(controller.text);
                          controller.clear();
                        },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            cookbooksAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error: $e'),
              data: (cookbooks) => Expanded(
                child: ListView.builder(
                  itemCount: cookbooks.length,
                  itemBuilder: (context, idx) {
                    final cb = cookbooks[idx];
                    return Card(
                      child: ListTile(
                        title: Text(cb.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref
                              .read(cookbookProvider.notifier)
                              .deleteCookbook(cb.id),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CookbookDetailScreen(cookbook: cb),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
