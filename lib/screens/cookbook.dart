import '../constant/colors.dart';
import 'package:flutter/cupertino.dart';

import 'package:savourai/models/recipe_model.dart';
import 'package:savourai/widgets/recipe_card.dart';
import 'package:savourai/screens/cookbook_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savourai/models/cookbook_model.dart';
import 'package:savourai/widgets/custom_search_bar.dart';
import 'package:savourai/widgets/create_cookbook_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CookbookScreen extends StatefulWidget {
  const CookbookScreen({super.key});

  @override
  State<CookbookScreen> createState() => _CookbookScreenState();
}

class _CookbookScreenState extends State<CookbookScreen> {
  void _openCookbookRecipes(Cookbook cookbook) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CookbookDetailScreen(cookbook: cookbook, userId: _userId!),
      ),
    );
  }

  List<Cookbook> _cookbooks = [];
  bool _loading = false;
  String? _error;
  String? _userId;
  final List<Color> _colorOptions = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.card,
    AppColors.success,
    AppColors.error,
    AppColors.muted,
  ];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _fetchCookbooks();
  }

  Future<void> _fetchCookbooks() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('cookbooks')
          .orderBy('createdAt', descending: true)
          .get();
      List<Cookbook> cookbooks = snap.docs
          .map((doc) => Cookbook.fromJson(doc.data(), doc.id))
          .toList();

      // Fetch actual recipe count for each cookbook
      for (int i = 0; i < cookbooks.length; i++) {
        final cb = cookbooks[i];
        final recipesSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('cookbooks')
            .doc(cb.id)
            .collection('recipes')
            .get();
        cookbooks[i] = Cookbook(
          id: cb.id,
          title: cb.title,
          createdAt: cb.createdAt,
          recipeCount: recipesSnap.docs.length,
          color: cb.color,
        );
      }
      setState(() {
        _cookbooks = cookbooks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cookbooks.';
        _loading = false;
      });
    }
  }

  Future<void> _addCookbook(String title, Color color) async {
    final newDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('cookbooks')
        .doc();
    final newCookbook = Cookbook(
      id: newDoc.id,
      title: title,
      createdAt: DateTime.now(),
      recipeCount: 0,
      color: color.value,
    );
    await newDoc.set(newCookbook.toJson());
    _fetchCookbooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cookbook',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Container()),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('New Cookbook'),
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => CreateCookbookDialog(
                              colorOptions: _colorOptions,
                              onCreate: (title, color) {
                                _addCookbook(title, color);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (!_loading && _cookbooks.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _cookbooks.length,
                    itemBuilder: (context, index) {
                      final cb = _cookbooks[index];
                      final color = Color(
                        (cb.toJson()['color'] ?? AppColors.primary.value)
                            as int,
                      );
                      return GestureDetector(
                        onTap: () => _openCookbookRecipes(cb),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.border.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.folder_fill,
                                size: 54,
                                color: color,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cb.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cb.recipeCount} recipes',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (!_loading && _cookbooks.isEmpty)
              const Center(child: Text('No cookbooks yet.')),
          ],
        ),
      ),
    );
  }
}
