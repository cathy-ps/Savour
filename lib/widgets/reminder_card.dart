import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constant/colors.dart';
import '../models/shopping_list_model.dart';
import '../screens/shoppinglist.dart';

class ReminderCard extends StatelessWidget {
  final ShoppingList shoppingList;

  const ReminderCard({Key? key, required this.shoppingList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the reminder date
    final reminderTime = shoppingList.reminder;
    final formattedDate = reminderTime != null
        ? DateFormat('MMM dd, yyyy').format(reminderTime)
        : 'No date set';
    final formattedTime = reminderTime != null
        ? DateFormat('hh:mm a').format(reminderTime)
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reminder header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Reminder',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Recipe name and time
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shopping for ${shoppingList.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${shoppingList.totalIngredients} items',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
