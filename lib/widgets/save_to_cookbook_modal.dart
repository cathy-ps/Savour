import 'package:flutter/material.dart';

class Cookbook {
  final String id;
  final String name;
  Cookbook({required this.id, required this.name});
}

class SaveToCookbookModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final List<Cookbook> cookbooks;
  final void Function(String cookbookId) onSave;
  final void Function(String name) onCreateAndSave;

  const SaveToCookbookModal({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.cookbooks,
    required this.onSave,
    required this.onCreateAndSave,
  }) : super(key: key);

  @override
  State<SaveToCookbookModal> createState() => _SaveToCookbookModalState();
}

class _SaveToCookbookModalState extends State<SaveToCookbookModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();
    return GestureDetector(
      onTap: widget.onClose,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Save Recipe To...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.cookbooks.isNotEmpty) ...[
                    const Text(
                      'Existing Cookbooks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        itemCount: widget.cookbooks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, idx) {
                          final cb = widget.cookbooks[idx];
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            onPressed: () => widget.onSave(cb.id),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                cb.name,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    widget.cookbooks.isNotEmpty
                        ? 'Or Create a New One'
                        : 'Create a New Cookbook',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Weeknight Meals',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        onPressed: _controller.text.trim().isEmpty
                            ? null
                            : () {
                                final name = _controller.text.trim();
                                if (name.isNotEmpty) {
                                  widget.onCreateAndSave(name);
                                  _controller.clear();
                                  setState(() {});
                                }
                              },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
