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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    list.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Total ingredients: ${list.totalIngredients}'),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: list.ingredients.length,
                itemBuilder: (context, i) {
                  final ing = list.ingredients[i];
                  return CheckboxListTile(
                    value: _checked[i],
                    onChanged: (val) {
                      setState(() => _checked[i] = val ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      '${ing.name} (${ing.quantity} ${ing.unit})',
                      style: _checked[i]
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    list.reminder != null ? Icons.alarm_on : Icons.alarm_add,
                    color: list.reminder != null ? Colors.green : Colors.grey,
                  ),
                  onPressed: widget.onSetReminder,
                ),
                if (list.reminder != null)
                  Text(
                    'Reminder: ${list.reminder!.toLocal().toString().substring(0, 16)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
