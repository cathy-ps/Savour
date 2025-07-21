import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ReminderInfoCard extends StatelessWidget {
  final DateTime? reminder;
  final VoidCallback? onClearReminder;
  const ReminderInfoCard({
    super.key,
    required this.reminder,
    this.onClearReminder,
  });

  @override
  Widget build(BuildContext context) {
    if (reminder == null) return const SizedBox.shrink();
    assert(
      onClearReminder != null,
      'onClearReminder callback must be provided',
    );
    String formatDate(DateTime date) {
      final d = date.toLocal();
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year.toString().substring(2);
      int hour = d.hour;
      final minute = d.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'pm' : 'am';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$day/$month/$year, $hour:$minute $ampm';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        title: Row(
          children: [
            const Icon(Icons.alarm, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reminder Set for: \n${formatDate(reminder!)}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: onClearReminder,
              tooltip: 'Remove reminder',
            ),
          ],
        ),
      ),
    );
  }
}
