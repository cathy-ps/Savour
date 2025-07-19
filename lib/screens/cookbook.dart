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
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
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
      setState(() {
        _cookbooks = snap.docs
            .map((doc) => Cookbook.fromJson(doc.data(), doc.id))
            .toList();
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
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF7C4DFF),
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
                      color: Colors.white,
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
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7C4DFF),
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
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
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
                        (cb.toJson()['color'] ?? Colors.blue.value) as int,
                      );
                      return GestureDetector(
                        onTap: () => _openCookbookRecipes(cb),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder, size: 54, color: color),
                              const SizedBox(height: 10),
                              Text(
                                cb.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cb.recipeCount} recipes',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
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
