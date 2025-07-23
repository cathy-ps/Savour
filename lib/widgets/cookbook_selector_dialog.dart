import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/models/cookbook_model.dart';

class CookbookSelectorDialog extends StatefulWidget {
  final List<Cookbook> cookbooks;

  const CookbookSelectorDialog({super.key, required this.cookbooks});

  // Static method to show the dialog as a modal bottom sheet
  static Future<String?> show(BuildContext context, List<Cookbook> cookbooks) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, // 70% of screen height
        minChildSize: 0.5, // Minimum 50% of screen height
        maxChildSize: 0.9, // Maximum 90% of screen height
        expand: false,
        builder: (context, scrollController) {
          return CookbookSelectorDialog(cookbooks: cookbooks);
        },
      ),
    );
  }

  @override
  State<CookbookSelectorDialog> createState() => _CookbookSelectorDialogState();
}

class _CookbookSelectorDialogState extends State<CookbookSelectorDialog> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const Text(
            'Select a Cookbook',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: widget.cookbooks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, i) {
                final cb = widget.cookbooks[i];
                final color = Color(cb.color);
                return GestureDetector(
                  onTap: () => Navigator.pop(context, cb.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.border.withOpacity(0.12),
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
        ],
      ),
    );
  }
}
