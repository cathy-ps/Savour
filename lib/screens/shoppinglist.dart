import 'package:flutter/material.dart';
import 'models/recipe_model.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // List to store shopping lists
  final List<ShoppingList> shoppingLists = [];

  // Add a recipe to the shopping list
  void addToShoppingList({
    required String recipeId,
    required String recipeName,
    required List<String> ingredients,
  }) {
    // Generate unique shopping list id
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final items = ingredients
        .map(
          (name) => ShoppingListItem(
            id: UniqueKey().toString(),
            name: name,
            checked: false,
          ),
        )
        .toList();
    setState(() {
      shoppingLists.add(
        ShoppingList(
          id: newId,
          recipeId: recipeId,
          recipeName: recipeName,
          items: items,
          reminder: null,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$recipeName" to shopping lists!')),
    );
  }

  void _deleteList(String listId) {
    setState(() {
      shoppingLists.removeWhere((l) => l.id == listId);
    });
  }

  void _toggleItem(String listId, String itemId) {
    setState(() {
      final list = shoppingLists.firstWhere((l) => l.id == listId);
      final idx = list.items.indexWhere((i) => i.id == itemId);
      if (idx != -1) {
        list.items[idx] = ShoppingListItem(
          id: list.items[idx].id,
          name: list.items[idx].name,
          checked: !list.items[idx].checked,
        );
      }
    });
  }

  void _setReminder(String listId, String reminder) {
    setState(() {
      final list = shoppingLists.firstWhere((l) => l.id == listId);
      final idx = shoppingLists.indexOf(list);
      shoppingLists[idx] = ShoppingList(
        id: list.id,
        recipeId: list.recipeId,
        recipeName: list.recipeName,
        items: list.items,
        reminder: reminder,
      );
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Shopping Lists',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here are the shopping lists created from your saved recipes.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (shoppingLists.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No shopping lists yet. View a recipe and add its ingredients to create one.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: shoppingLists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 20),
                  itemBuilder: (context, idx) {
                    final list = shoppingLists[idx];
                    return SizedBox(
                      width: 350,
                      child: ShoppingListCard(
                        list: list,
                        onDelete: _deleteList,
                        onToggleItem: _toggleItem,
                        onSetReminder: _setReminder,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ShoppingListCard extends StatefulWidget {
  final ShoppingList list;
  final void Function(String listId) onDelete;
  final void Function(String listId, String itemId) onToggleItem;
  final void Function(String listId, String reminder) onSetReminder;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.onDelete,
    required this.onToggleItem,
    required this.onSetReminder,
  });

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  late TextEditingController _reminderController;

  @override
  void initState() {
    super.initState();
    _reminderController = TextEditingController(
      text: widget.list.reminder ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ShoppingListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list.reminder != widget.list.reminder) {
      _reminderController.text = widget.list.reminder ?? '';
    }
  }

  @override
  void dispose() {
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.recipeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Shopping List',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Delete list',
                  onPressed: () => widget.onDelete(list.id),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: list.items.length,
                itemBuilder: (context, idx) {
                  final item = list.items[idx];
                  return InkWell(
                    onTap: () => widget.onToggleItem(list.id, item.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: item.checked
                                  ? Colors.orange[500]
                                  : Colors.transparent,
                              border: Border.all(
                                color: item.checked
                                    ? Colors.orange[500]!
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: item.checked
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: item.checked
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF374151),
                                decoration: item.checked
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 20,
                  color: Color(0xFFFB923C),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Set a Reminder',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reminderController,
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM-DD HH:MM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () =>
                      widget.onSetReminder(list.id, _reminderController.text),
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
