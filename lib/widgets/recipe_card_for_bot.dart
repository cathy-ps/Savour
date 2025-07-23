import 'package:flutter/material.dart';
import 'package:savourai/models/recipe_model.dart';
import 'package:savourai/constant/colors.dart';

class RecipeCardForBot extends StatelessWidget {
  final Recipe recipe;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const RecipeCardForBot({
    super.key,
    required this.recipe,
    this.imageUrl,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final imgUrl = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl!
        : (recipe.imageUrl.isNotEmpty)
        ? recipe.imageUrl
        : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 144, // Fixed height to prevent overflow
          child: Column(
            children: [
              // Image section with fixed height
              SizedBox(
                height: 100, // Reduced height for image
                width: double.infinity,
                child: Stack(
                  children: [
                    // Image with placeholder
                    SizedBox.expand(
                      child: imgUrl != null
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildPlaceholder(isLoading: true);
                                  },
                            )
                          : _buildPlaceholder(),
                    ),

                    // Duration chip
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${recipe.cookingDuration} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Favorite button
                    if (onFavoriteTap != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onFavoriteTap,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 18,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title section with remaining height
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      color: AppColors.card,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.restaurant, size: 24, color: AppColors.lightGrey),
      ),
    );
  }
}
