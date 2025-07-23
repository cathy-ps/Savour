import '../constant/colors.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/cupertino.dart';

import 'package:savourai/screens/cookbook_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savourai/models/cookbook_model.dart';
import 'package:savourai/widgets/create_cookbook.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savourai/widgets/custom_search_bar.dart';

class CookbookScreen extends StatefulWidget {
  const CookbookScreen({super.key});

  @override
  State<CookbookScreen> createState() => _CookbookScreenState();
}

class _CookbookScreenState extends State<CookbookScreen> {
  String _sortBy = 'date'; // 'date' or 'title'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  void _openCookbookRecipes(Cookbook cookbook, String cookbookDocId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CookbookDetailScreen(
          cookbook: cookbook,
          userId: _userId!,
          cookbookDocId: cookbookDocId,
        ),
      ),
    );
  }

  List<Cookbook> _cookbooks = [];
  List<String> _cookbookDocIds = [];
  bool _loading = false;
  String? _error;
  String? _userId;
  final List<Color> _colorOptions = [
    const Color(0xFFF8BBD0), // Muted Pink
    const Color(0xFFFFE0B2), // Muted Orange
    const Color(0xFFFFF9C4), // Muted Yellow
    const Color(0xFFC8E6C9), // Muted Green
    const Color(0xFFB3E5FC), // Muted Blue
    const Color(0xFFD1C4E9), // Muted Purple
    const Color(0xFFD7CCC8), // Muted Brown
    const Color(0xFFCFD8DC), // Muted Blue Grey
    const Color(0xFFFFFDE7), // Muted Cream
    const Color(0xFFFFCDD2), // Muted Red
  ];

  //get Navigator => null;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _fetchCookbooks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      List<Map<String, dynamic>> cookbookData = snap.docs
          .map((doc) => {'data': doc.data(), 'docId': doc.id})
          .toList();

      List<Cookbook> cookbooks = [];
      List<String> cookbookDocIds = [];
      for (var cb in cookbookData) {
        final data = cb['data'] as Map<String, dynamic>;
        final docId = cb['docId'] as String;
        final recipesSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('cookbooks')
            .doc(docId)
            .collection('recipes')
            .get();
        cookbooks.add(
          Cookbook(
            id: docId,
            title: data['title'] ?? '',
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            recipeCount: recipesSnap.docs.length,
            color: data['color'] ?? AppColors.primary.value,
          ),
        );
        cookbookDocIds.add(docId);
      }
      setState(() {
        _cookbooks = cookbooks;
        _cookbookDocIds = cookbookDocIds;
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
    String capitalizedTitle = title
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
    final newDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('cookbooks')
        .doc();
    final newCookbook = Cookbook(
      id: newDoc.id,
      title: capitalizedTitle,
      createdAt: DateTime.now(),
      recipeCount: 0,
      color: color.value,
    );
    await newDoc.set(newCookbook.toJson());
    // Show toast after creation
    final messenger = ShadToaster.maybeOf(context);
    if (messenger != null) {
      messenger.show(
        ShadToast(
          description: Text('Cookbook "$capitalizedTitle" has been created'),
        ),
      );
    }
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cookbook',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: AppColors.white,
                            size: 24,
                          ),
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) => CreateCookbookDialog(
                                colorOptions: _colorOptions,
                                onCreate: (title, color) {
                                  Navigator.of(context).pop();
                                  _addCookbook(title, color);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomSearchBar(                          
                          hintIcon: const Icon(Icons.search, size: 20),
                          controller: _searchController,
                          hintText: 'Search cookbooks...',
                          onSubmit: () {
                            setState(() {
                              _searchQuery = _searchController.text.trim();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DropdownButton<String>(
                              value: _sortBy,
                              icon: Icon(
                                CupertinoIcons.arrow_up_arrow_down_circle,
                              ),
                              underline: Container(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.text,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              items: const [
                                DropdownMenuItem(
                                  value: 'date',
                                  child: Text('Newest'),
                                ),
                                DropdownMenuItem(
                                  value: 'title',
                                  child: Text('A-Z'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _sortBy = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            // IconButton(
                            //   icon: Icon(_sortBy == 'title' ? CupertinoIcons.arrow_up_down : CupertinoIcons.arrow_up_down),
                            //   tooltip: 'Toggle sort direction',
                            //   onPressed: () {
                            //     setState(() {
                            //       // Toggle sort direction (ascending/descending)
                            //       _cookbooks = _cookbooks.reversed.toList();
                            //     });
                            //   },
                            // ),
                          ],
                        ),
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
                  child: Builder(
                    builder: (context) {
                      // Build filteredCookbooks and filteredDocIds in parallel
                      //List<int> filteredIndexes = [];
                      final filteredCookbooks = <Cookbook>[];
                      final filteredDocIds = <String>[];
                      for (int i = 0; i < _cookbooks.length; i++) {
                        final cb = _cookbooks[i];
                        if (_searchQuery.isEmpty ||
                            cb.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            )) {
                          filteredCookbooks.add(cb);
                          filteredDocIds.add(_cookbookDocIds[i]);
                        }
                      }
                      // Sort after filtering
                      if (_sortBy == 'title') {
                        final zipped = List.generate(
                          filteredCookbooks.length,
                          (i) =>
                              MapEntry(filteredCookbooks[i], filteredDocIds[i]),
                        );
                        zipped.sort(
                          (a, b) => a.key.title.toLowerCase().compareTo(
                            b.key.title.toLowerCase(),
                          ),
                        );
                        filteredCookbooks
                          ..clear()
                          ..addAll(zipped.map((e) => e.key));
                        filteredDocIds
                          ..clear()
                          ..addAll(zipped.map((e) => e.value));
                      } else if (_sortBy == 'date') {
                        final zipped = List.generate(
                          filteredCookbooks.length,
                          (i) =>
                              MapEntry(filteredCookbooks[i], filteredDocIds[i]),
                        );
                        zipped.sort(
                          (a, b) => b.key.createdAt.compareTo(a.key.createdAt),
                        );
                        filteredCookbooks
                          ..clear()
                          ..addAll(zipped.map((e) => e.key));
                        filteredDocIds
                          ..clear()
                          ..addAll(zipped.map((e) => e.value));
                      }
                      if (filteredCookbooks.isEmpty) {
                        return const Center(child: Text('No cookbooks found.'));
                      }
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                        itemCount: filteredCookbooks.length,
                        itemBuilder: (context, index) {
                          final cb = filteredCookbooks[index];
                          final docId = filteredDocIds[index];
                          final color = Color(
                            (cb.toJson()['color'] ?? AppColors.transparent)
                                as int,
                          );
                          return GestureDetector(
                            onTap: () => _openCookbookRecipes(cb, docId),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                // boxShadow: [
                                //   BoxShadow(
                                //     color: AppColors.border.withOpacity(0.2),
                                //     blurRadius: 4,
                                //     offset: Offset(0, 2),
                                //   ),
                                // ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.folder_fill,
                                    size: 64,
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
