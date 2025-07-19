import 'package:flutter/material.dart';

class CreateCookbookDialog extends StatefulWidget {
  final void Function(String title, Color color) onCreate;
  final List<Color> colorOptions;

  const CreateCookbookDialog({
    super.key,
    required this.onCreate,
    required this.colorOptions,
  });

  @override
  State<CreateCookbookDialog> createState() => _CreateCookbookDialogState();
}

class _CreateCookbookDialogState extends State<CreateCookbookDialog> {
  final TextEditingController _controller = TextEditingController();
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.colorOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Cookbook'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Cookbook Name'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: widget.colorOptions.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _controller.text.trim();
            if (title.isNotEmpty && _selectedColor != null) {
              widget.onCreate(title, _selectedColor!);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
