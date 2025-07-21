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
  late final List<Color> _colors;

  //get Navigator => null;

  @override
  void initState() {
    super.initState();
    // Provide a fallback with more muted (pastel/soft) colors if not enough are passed
    _colors = (widget.colorOptions.isNotEmpty
        ? widget.colorOptions
        : [
            const Color(0xFFF8BBD0), // Muted Pink
            const Color(0xFFFFE0B2), // Muted Orange
            const Color(0xFFFFF9C4), // Muted Yellow
            const Color(0xFFC8E6C9), // Muted Green
            const Color(0xFFB3E5FC), // Muted Blue
            const Color(0xFFD1C4E9), // Muted Purple
            const Color(0xFFD7CCC8), // Muted Brown
            const Color(0xFFCFD8DC), // Muted Blue Grey
            const Color(0xFFFFFDE7), // Muted Cream
            const Color(0xFFE1BEE7), // Muted Lavender
            const Color(0xFFFFF3E0), // Muted Peach
            const Color(0xFFB2DFDB), // Muted Teal
            const Color(0xFFFFCDD2), // Muted Red
            const Color(0xFFE0F2F1), // Muted Cyan
            const Color(0xFFF0F4C3), // Muted Lime
            const Color(0xFFDCEDC8), // Muted Light Green
            const Color(0xFFB3E5FC), // Muted Light Blue
            const Color(0xFFECEFF1), // Muted Grey
          ]);
    _selectedColor = _colors.first;
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
          SizedBox(
            height: 90,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((color) {
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
                                  color: color.withOpacity(0.4),
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
            ),
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
                    //Navigator.of(context).pop();
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
