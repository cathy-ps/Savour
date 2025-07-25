import 'package:flutter/material.dart';
import '../constant/colors.dart';
import '../widgets/shopping_list_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shoppinglist_firestore_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Future<void> _setReminder(
    BuildContext context,
    String listId,
    DateTime? currentReminder,
  ) async {
    final now = DateTime.now();
    final initialDate = currentReminder ?? now.add(const Duration(hours: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;
    final reminder = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    // Call Firestore update function (assume updateShoppingListReminder exists in provider)
    await updateShoppingListReminder(listId, reminder);
  }

  // Only using Firestore data via provider.
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final shoppingListsAsync = ref.watch(shoppingListsProvider);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shopping Lists',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: shoppingListsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (shoppingLists) {
                      if (shoppingLists.isEmpty) {
                        return const Center(child: Text('No shopping lists.'));
                      }
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: shoppingLists.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentPage = i),
                              itemBuilder: (context, index) {
                                final list = shoppingLists[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: ShoppingListCard(
                                    list: list,
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Delete Shopping List',
                                          ),
                                          content: const Text(
                                            'Are you sure you want to delete this shopping list?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await deleteShoppingList(list.id);
                                      }
                                    },
                                    onSetReminder: () async {
                                      await _setReminder(
                                        context,
                                        list.id,
                                        list.reminder,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              shoppingLists.length,
                              (i) => Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _currentPage
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
