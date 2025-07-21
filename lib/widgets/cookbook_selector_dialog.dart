import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/models/cookbook_model.dart';

class CookbookSelectorDialog extends StatelessWidget {
  final List<Cookbook> cookbooks;
  final VoidCallback? onCreateNew;

  const CookbookSelectorDialog({
    super.key,
    required this.cookbooks,
    this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 2 / 3,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Select a Cookbook',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    itemCount: cookbooks.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemBuilder: (context, i) {
                      final cb = cookbooks[i];
                      final color = Color(cb.color);
                      return GestureDetector(
                        onTap: () async {
                          Navigator.pop(context, cb.id);
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recipe added to "${cb.title}"'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.border.withValues(alpha: 0.12),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.folder_fill,
                                size: 32,
                                color: color,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cb.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.text,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Center(
                //   child: TextButton(
                //     onPressed: () {
                //       if (onCreateNew != null) onCreateNew!();
                //       Navigator.pop(context, null);
                //     },
                //     child: const Text('Create New Cookbook'),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}
