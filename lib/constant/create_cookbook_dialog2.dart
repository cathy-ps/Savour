import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            'Create New Cookbook',
            style: ShadTheme.of(context).textTheme.h3,
          ),
          const SizedBox(height: 20),
          ShadInputFormField(
            controller: _controller,
            id: 'cookbook_name',
            label: const Text('Cookbook Name'),
            placeholder: const Text('Enter a name for your cookbook'),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a color for your folder:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: widget.colorOptions.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.ghost(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ShadButton(
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
          ),
        ],
      ),
    );
  }
}
