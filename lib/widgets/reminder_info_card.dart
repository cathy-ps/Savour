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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        title: Row(
          children: [
            const Icon(Icons.alarm, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reminder Set for: ${reminder!.toLocal().toString().substring(0, 16)}',
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
