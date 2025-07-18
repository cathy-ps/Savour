import 'package:flutter/material.dart';
import '../services/offline_recipe_service.dart';

class RecipeDetail extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onBack;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onAddToShoppingList;
  final VoidCallback? onDownload;

  const RecipeDetail({
    Key? key,
    required this.recipe,
    required this.onBack,
    required this.isSaved,
    required this.onToggleSave,
    required this.onAddToShoppingList,
    this.onDownload,
  }) : super(key: key);

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.recipe['imageUrl'] as String?;
    final recipeName = widget.recipe['recipeName'] ?? '';
    final description = widget.recipe['description'] ?? '';
    final prepTime = widget.recipe['prepTime']?.toString() ?? '';
    final cookTime = widget.recipe['cookTime']?.toString() ?? '';
    final totalTime = widget.recipe['totalTime']?.toString() ?? '';
    final servings = widget.recipe['servings']?.toString() ?? '';
    final calories = widget.recipe['calories']?.toString() ?? '';
    final ingredients =
        (widget.recipe['ingredients'] as List?)?.cast<String>() ?? [];
    final instructions =
        (widget.recipe['instructions'] as List?)?.cast<String>() ?? [];

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
                      onPressed: widget.onAddToShoppingList,
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
                            final isWide = constraints.maxWidth > 600;
                            return GridView.count(
                              crossAxisCount: isWide ? 5 : 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: [
                                InfoPill(
                                  icon: Icons.timer_outlined,
                                  label: 'Prep Time',
                                  value: prepTime,
                                ),
                                InfoPill(
                                  icon: Icons.soup_kitchen,
                                  label: 'Cook Time',
                                  value: cookTime,
                                ),
                                InfoPill(
                                  icon: Icons.schedule,
                                  label: 'Total Time',
                                  value: totalTime,
                                ),
                                InfoPill(
                                  icon: Icons.people_outline,
                                  label: 'Servings',
                                  value: servings,
                                ),
                                InfoPill(
                                  icon: Icons.local_fire_department,
                                  label: 'Calories',
                                  value: calories,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ingredients
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.list_alt,
                                        color: Colors.deepOrange,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ingredients',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    height: 2,
                                    width: 60,
                                    color: Colors.orange[200],
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: ingredients.length,
                                    itemBuilder: (context, idx) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.0,
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Instructions
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instructions',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    height: 2,
                                    width: 60,
                                    color: Colors.orange[200],
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: instructions.length,
                                    itemBuilder: (context, idx) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(
                                              color: Colors.deepOrange,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                              top: 2,
                                            ),
                                            child: Text(
                                              '${idx + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
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
