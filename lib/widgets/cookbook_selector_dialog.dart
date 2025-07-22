import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/models/cookbook_model.dart';

class CookbookSelectorDialog extends StatefulWidget {
  final List<Cookbook> cookbooks;

  const CookbookSelectorDialog({super.key, required this.cookbooks});

  @override
  State<CookbookSelectorDialog> createState() => _CookbookSelectorDialogState();
}

class _CookbookSelectorDialogState extends State<CookbookSelectorDialog> {
  //int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a Cookbook',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 320,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: widget.cookbooks.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
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
            const SizedBox(height: 16),
            // TextButton(
            //   onPressed: () {
            //     if (onCreateNew != null) onCreateNew!();
            //     Navigator.pop(context, null);
            //   },
            //   child: const Text('Create New Cookbook'),
            // ),
          ],
        ),
      ),
    );
  }
}
