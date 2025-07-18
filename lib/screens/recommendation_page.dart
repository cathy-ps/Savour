import 'package:flutter/material.dart';

class RecommendationPage extends StatelessWidget {
  final List<String> ingredients;
  const RecommendationPage({Key? key, required this.ingredients})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder for recipe cards, replace with real data
    final recipes = List.generate(
      3,
      (i) => {
        'title': 'Recipe ${i + 1}',
        'desc': 'A delicious meal using: ${ingredients.join(", ")}',
        'image': null,
      },
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Recipes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 2.2,
            mainAxisSpacing: 16,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, idx) {
            final recipe = recipes[idx];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                    child: recipe['image'] == null
                        ? const Icon(
                            Icons.fastfood,
                            size: 48,
                            color: Colors.grey,
                          )
                        : Image.network(
                            recipe['image'] as String,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['title'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe['desc'] as String,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
