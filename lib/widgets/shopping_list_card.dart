import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';

class ShoppingListCard extends StatefulWidget {
  final ShoppingList list;
  final VoidCallback onDelete;
  final VoidCallback? onSetReminder;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.onDelete,
    this.onSetReminder,
  });

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.list.ingredients.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image from assets
          SizedBox.expand(
            child: Image.asset(
              'assets/images/list_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey[300]),
            ),
          ),
          // Overlay for readability
          Container(
            decoration: BoxDecoration(
              //color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        list.reminder != null
                            ? Icons.alarm_on
                            : Icons.alarm_add,
                        color: list.reminder != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: widget.onSetReminder,
                    ),
                    if (list.reminder != null)
                      Text(
                        'Reminder: ${list.reminder!.toLocal().toString().substring(0, 16)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.white54,
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        list.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black),
                      onSelected: (value) async {
                        if (value == 'reminder') {
                          if (widget.onSetReminder != null)
                            widget.onSetReminder!();
                        } else if (value == 'delete') {
                          widget.onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'reminder',
                          child: ListTile(
                            leading: Icon(Icons.alarm, color: Colors.black),
                            title: Text('Set Reminder'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            title: Text('Delete List'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total ingredients: ${list.totalIngredients}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.white54,
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final indexed = List.generate(
                        list.ingredients.length,
                        (i) => {
                          'ingredient': list.ingredients[i],
                          'checked': _checked[i],
                          'index': i,
                        },
                      );
                      indexed.sort((a, b) {
                        final aChecked = a['checked'] as bool;
                        final bChecked = b['checked'] as bool;
                        if (aChecked == bChecked) return 0;
                        return aChecked ? 1 : -1;
                      });
                      return ListView.builder(
                        itemCount: indexed.length,
                        itemBuilder: (context, sortedIdx) {
                          final ing =
                              indexed[sortedIdx]['ingredient']
                                  as ShoppingListIngredient;
                          final checked = indexed[sortedIdx]['checked'] as bool;
                          final origIdx = indexed[sortedIdx]['index'] as int;
                          return ListTile(
                            leading: InkWell(
                              onTap: () {
                                setState(
                                  () => _checked[origIdx] = !_checked[origIdx],
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: checked
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black54,
                                    width: 2,
                                  ),
                                  color: checked
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                ),
                                child: checked
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            title: Text(
                              '${ing.name} (${ing.quantity} ${ing.unit})',
                              style: checked
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    )
                                  : const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                            ),
                            onTap: () {
                              setState(
                                () => _checked[origIdx] = !_checked[origIdx],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
