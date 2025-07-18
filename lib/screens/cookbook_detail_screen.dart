import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/recipe_card.dart';
import 'cookbook.dart';

class CookbookDetailScreen extends ConsumerStatefulWidget {
  final Cookbook cookbook;
  const CookbookDetailScreen({Key? key, required this.cookbook})
    : super(key: key);

  @override
  @override
  _CookbookDetailScreenState createState() => _CookbookDetailScreenState();
}

class _CookbookDetailScreenState extends ConsumerState<CookbookDetailScreen> {
  Future<void> _unsaveRecipe(String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final cookbook = widget.cookbook;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc(cookbook.id)
        .collection('recipes')
        .doc(recipeId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final cookbook = widget.cookbook;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(cookbook.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Text(
              cookbook.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('cookbooks')
                  .doc(cookbook.id)
                  .collection('recipes')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: Text(
                        'This cookbook is empty. Go find some recipes to save!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final recipeMap = docs[idx].data() as Map<String, dynamic>;
                    final recipe = Recipe.fromJson(recipeMap);
                    final recipeId = docs[idx].id;
                    return RecipeCard(
                      recipe: recipe,
                      onSelect: (_) {}, // TODO: Implement navigation to detail
                      isSaved: true,
                      onToggleSave: (_) => _unsaveRecipe(recipeId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ...existing code up to the end of the first State class...
