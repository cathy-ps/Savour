import 'package:flutter/material.dart';

class CookbookSelectorDialog extends StatelessWidget {
  final List<String> cookbookIds;
  final VoidCallback? onCreateNew;

  const CookbookSelectorDialog({
    super.key,
    required this.cookbookIds,
    this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Select Cookbook'),
      children: [
        ...cookbookIds.map(
          (id) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, id),
            child: Text(id),
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            if (onCreateNew != null) onCreateNew!();
            Navigator.pop(context, null);
          },
          child: const Text('Create New Cookbook'),
        ),
      ],
    );
  }
}
