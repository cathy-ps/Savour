import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReminderNotifier extends StateNotifier<DateTime?> {
  ReminderNotifier(super.initial);
  void clear() => state = null;
  void set(DateTime value) => state = value;
}

final reminderProvider =
    StateNotifierProvider.family<ReminderNotifier, DateTime?, String>(
      (ref, listId) => ReminderNotifier(null),
    );
