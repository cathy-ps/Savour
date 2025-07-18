import 'package:flutter/material.dart';
import '../services/offline_recipe_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/save_to_cookbook_modal.dart';
import 'shoppinglist.dart';

class RecipeDetail extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onBack;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback? onDownload;

  const RecipeDetail({
    Key? key,
    required this.recipe,
    required this.onBack,
    required this.isSaved,
    required this.onToggleSave,
    this.onDownload,
  }) : super(key: key);

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

bool _showSaveModal = false;
List<Cookbook> _cookbooks = [];

class _RecipeDetailState extends State<RecipeDetail> {
  void addToShoppingList() {
    final recipe = widget.recipe;
    final recipeId = recipe['id'] ?? '';
    final recipeName = recipe['recipeName'] ?? recipe['title'] ?? '';
    // Support both List<String> and List<Map> for ingredients
    List<String> ingredients = [];
    if (recipe['ingredients'] is List) {
      final ing = recipe['ingredients'] as List;
      if (ing.isNotEmpty && ing.first is String) {
        ingredients = ing.cast<String>();
      } else if (ing.isNotEmpty && ing.first is Map) {
        ingredients = ing.map((e) {
          if (e is Map) {
            final name = e['name'] ?? e['ingredient'] ?? '';
            final qty = e['quantity'] ?? e['qty'] ?? '';
            final unit = e['unit'] ?? '';
            return [
              name,
              qty,
              unit,
            ].where((x) => x != null && x.toString().isNotEmpty).join(' ');
          }
          return e.toString();
        }).toList();
      }
    }
    // Navigate to ShoppingListScreen and add the new list
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ShoppingListScreen(key: UniqueKey()),
          ),
        )
        .then((_) {
          // Optionally: show a snackbar or refresh
        });
    // TODO: Integrate with provider or global state for real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$recipeName" to shopping lists!')),
    );
  }

  Future<void> _fetchCookbooks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .get();
    setState(() {
      _cookbooks = snap.docs
          .map((doc) => Cookbook(id: doc.id, name: doc['name'] ?? doc.id))
          .toList();
    });
  }

  void _showSaveToCookbook() async {
    await _fetchCookbooks();
    setState(() {
      _showSaveModal = true;
    });
  }

  void _handleSaveToCookbook(String cookbookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc(cookbookId)
        .collection('recipes')
        .doc(widget.recipe['recipeName'] ?? widget.recipe['title'] ?? '')
        .set(widget.recipe);
    setState(() {
      _showSaveModal = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recipe saved to cookbook!')));
  }

  void _handleCreateAndSaveCookbook(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .add({'name': name});
    await newDoc
        .collection('recipes')
        .doc(widget.recipe['recipeName'] ?? widget.recipe['title'] ?? '')
        .set(widget.recipe);
    await _fetchCookbooks();
    setState(() {
      _showSaveModal = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created "$name" and saved recipe!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    // Robust extraction for all possible fields (legacy and Gemini)
    final imageUrl = recipe['imageUrl'] as String?;
    final recipeName = recipe['recipeName'] ?? recipe['title'] ?? '';
    final description = recipe['description'] ?? '';
    // Times
    final prepTime =
        recipe['prepTime']?.toString() ?? recipe['prep_time']?.toString() ?? '';
    final cookTime =
        recipe['cookTime']?.toString() ?? recipe['cook_time']?.toString() ?? '';
    String totalTime = '';
    if (recipe['totalTime'] != null &&
        recipe['totalTime'].toString().isNotEmpty) {
      totalTime = recipe['totalTime'].toString();
    } else if (recipe['cooking_duration'] != null) {
      totalTime = '${recipe['cooking_duration']} min';
    } else if (recipe['total_time'] != null) {
      totalTime = recipe['total_time'].toString();
    }
    // Servings
    final servings =
        recipe['servings']?.toString() ?? recipe['serving']?.toString() ?? '';
    // Calories and nutrition
    String calories = '';
    if (recipe['calories'] != null &&
        recipe['calories'].toString().isNotEmpty) {
      calories = recipe['calories'].toString();
    } else if (recipe['nutrition'] != null &&
        recipe['nutrition']['calories'] != null) {
      calories = '${recipe['nutrition']['calories']} kcal';
    }
    // Nutrition breakdown
    final nutrition = recipe['nutrition'] as Map<String, dynamic>?;
    // Ingredients: support both List<String> and List<Map>
    List<String> ingredients = [];
    if (recipe['ingredients'] is List) {
      final ing = recipe['ingredients'] as List;
      if (ing.isNotEmpty && ing.first is String) {
        ingredients = ing.cast<String>();
      } else if (ing.isNotEmpty && ing.first is Map) {
        ingredients = ing.map((e) {
          if (e is Map) {
            final name = e['name'] ?? e['ingredient'] ?? '';
            final qty = e['quantity'] ?? e['qty'] ?? '';
            final unit = e['unit'] ?? '';
            return [
              name,
              qty,
              unit,
            ].where((x) => x != null && x.toString().isNotEmpty).join(' ');
          }
          return e.toString();
        }).toList();
      }
    }
    // Instructions: support both List<String> and List<dynamic> and also check for 'steps'
    List<String> instructions = [];
    if (recipe['instructions'] is List) {
      instructions = (recipe['instructions'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (recipe['steps'] is List) {
      instructions = (recipe['steps'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.playlist_add, color: Colors.green),
                      tooltip: 'Add to Shopping List',
                      onPressed: addToShoppingList,
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isSaved ? Icons.favorite : Icons.favorite_border,
                        color: widget.isSaved ? Colors.red : Colors.orange,
                      ),
                      tooltip: widget.isSaved ? 'Unsave recipe' : 'Save recipe',
                      onPressed: widget.onToggleSave,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.download_for_offline,
                        color: Colors.blue,
                      ),
                      tooltip: 'Download for offline use',
                      onPressed: widget.onDownload,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              elevation: 6,
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Image.network(
                        imageUrl,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 240,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        Text(
                          recipeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 3 * 180;
                            final pills = <Widget>[];
                            if (totalTime.isNotEmpty) {
                              pills.add(
                                InfoPill(
                                  icon: Icons.schedule,
                                  label: 'Total Time',
                                  value: totalTime,
                                ),
                              );
                            }
                            if (calories.isNotEmpty) {
                              pills.add(
                                InfoPill(
                                  icon: Icons.local_fire_department,
                                  label: 'Calories',
                                  value: calories,
                                ),
                              );
                            }
                            if (pills.isEmpty) return const SizedBox.shrink();
                            return GridView.count(
                              crossAxisCount: isWide ? 3 : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: pills,
                            );
                          },
                        ),
                        if (nutrition != null && nutrition.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nutrition per serving:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    if (nutrition['calories'] != null)
                                      Text(
                                        'Calories: ${nutrition['calories']} kcal',
                                      ),
                                    if (nutrition['protein'] != null)
                                      Text('Protein: ${nutrition['protein']}g'),
                                    if (nutrition['carbs'] != null)
                                      Text('Carbs: ${nutrition['carbs']}g'),
                                    if (nutrition['fat'] != null)
                                      Text('Fat: ${nutrition['fat']}g'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 28),
                        if (ingredients.isNotEmpty || instructions.isNotEmpty)
                          DefaultTabController(
                            length:
                                (ingredients.isNotEmpty &&
                                    instructions.isNotEmpty)
                                ? 2
                                : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TabBar(
                                  labelColor: Colors.deepOrange,
                                  unselectedLabelColor: Colors.grey[700],
                                  indicatorColor: Colors.orange[300],
                                  tabs: [
                                    if (ingredients.isNotEmpty)
                                      const Tab(
                                        icon: Icon(Icons.list_alt),
                                        text: 'Ingredients',
                                      ),
                                    if (instructions.isNotEmpty)
                                      const Tab(
                                        icon: Icon(Icons.menu_book),
                                        text: 'Instructions',
                                      ),
                                  ],
                                ),
                                SizedBox(
                                  height: 320,
                                  child: TabBarView(
                                    children: [
                                      if (ingredients.isNotEmpty)
                                        ListView.builder(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          itemCount: ingredients.length,
                                          itemBuilder: (context, idx) =>
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4.0,
                                                      horizontal: 8.0,
                                                    ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_box_rounded,
                                                      color: Colors.deepOrange,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        ingredients[idx],
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        ),
                                      if (instructions.isNotEmpty)
                                        ListView.builder(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          itemCount: instructions.length,
                                          itemBuilder: (context, idx) =>
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 6.0,
                                                      horizontal: 8.0,
                                                    ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors
                                                                .deepOrange,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      alignment:
                                                          Alignment.center,
                                                      margin:
                                                          const EdgeInsets.only(
                                                            right: 12,
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        '${idx + 1}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        instructions[idx],
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoPill({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepOrange, size: 22),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5563),
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
