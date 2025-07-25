import 'package:flutter/material.dart';
import 'package:savourai/constant/colors.dart';
import '../models/shopping_list_model.dart';
import 'reminder_info_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reminder_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/reminder_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

  bool _wasAllChecked = false;

  Future<void> _archiveIfAllChecked() async {
    final allChecked = _checked.isNotEmpty && _checked.every((c) => c);
    if (allChecked && !_wasAllChecked) {
      _wasAllChecked = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('shoppingLists')
            .doc(widget.list.id)
            .set({'archived': true}, SetOptions(merge: true));
      }
      if (mounted) {
        widget.onDelete();
      }
    } else if (!allChecked) {
      _wasAllChecked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Consumer(
      builder: (context, ref, _) {
        final reminder = ref.watch(reminderProvider(list.name));

        // Listen to Firestore and update provider if changed
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid;
        if (userId == null) {
          return const Center(child: Text('Not signed in'));
        }
        // Listen to Firestore and update provider if changed
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('shoppingLists')
              .doc(list.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!.data();
              final firestoreReminder = data?['reminder'];
              DateTime? firestoreReminderDT;
              if (firestoreReminder != null) {
                if (firestoreReminder is Timestamp) {
                  firestoreReminderDT = firestoreReminder.toDate();
                } else if (firestoreReminder is DateTime) {
                  firestoreReminderDT = firestoreReminder;
                } else if (firestoreReminder is String) {
                  firestoreReminderDT = DateTime.tryParse(firestoreReminder);
                }
              }
              // Sync provider if different, but schedule after build
              final notifier = ref.read(reminderProvider(list.name).notifier);
              if (firestoreReminderDT != reminder) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (firestoreReminderDT != null) {
                    notifier.set(firestoreReminderDT);
                  } else {
                    notifier.clear();
                  }
                });
              }
            }

            Future<void> pickReminder() async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now,
                lastDate: DateTime(now.year + 5),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(now),
                );
                if (time != null) {
                  final selected = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  // Update UI immediately
                  ref.read(reminderProvider(list.name).notifier).set(selected);
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('shoppingLists')
                        .doc(list.id)
                        .set({'reminder': selected}, SetOptions(merge: true));

                    // Schedule local notification to remind user to buy groceries for this recipe
                    if (selected.isAfter(DateTime.now())) {
                      // Schedule notification
                      await scheduleReminderNotification(
                        list.name.hashCode, // Unique notification ID
                        selected,
                        'Don\'t forget to buy groceries for "${list.name}"!',
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a future time for the reminder.',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e, st) {
                    print(
                      '[ERROR] Failed to set reminder or schedule notification: $e\n$st',
                    );
                    if (context.mounted) {
                      ShadToaster.of(context).show(
                        ShadToast(
                          description: Text('Failed to set reminder: $e'),
                        ),
                      );
                    }
                  }
                }
              }
            }

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Background image from assets
                  // SizedBox.expand(
                  //   child: Image.asset(
                  //     'assets/images/list_bg.jpg',
                  //     fit: BoxFit.cover,
                  //     errorBuilder: (context, error, stackTrace) =>
                  //         Container(color: Colors.grey[300]),
                  //   ),
                  // ),
                  // Overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReminderInfoCard(
                          reminder: reminder,
                          onClearReminder: () async {
                            ref
                                .read(reminderProvider(list.name).notifier)
                                .clear();
                            // Update Firestore under users/{userId}/shoppingLists/{list.name}
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('shoppingLists')
                                .doc(list.id)
                                .set({
                                  'reminder': null,
                                }, SetOptions(merge: true));
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                list.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.black,
                                size: 20,
                              ),
                              onSelected: (value) async {
                                if (value == 'reminder') {
                                  await pickReminder();
                                } else if (value == 'delete') {
                                  widget.onDelete();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'reminder',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.alarm,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                    title: Text(
                                      'Set Reminder',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    title: Text(
                                      'Delete List',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total ingredients: ${list.totalIngredients}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                                  final checked =
                                      indexed[sortedIdx]['checked'] as bool;
                                  final origIdx =
                                      indexed[sortedIdx]['index'] as int;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 0,
                                    ),
                                    minLeadingWidth: 0,
                                    leading: InkWell(
                                      onTap: () async {
                                        setState(
                                          () => _checked[origIdx] =
                                              !_checked[origIdx],
                                        );
                                        await _archiveIfAllChecked();
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: checked
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Colors.black54,
                                            width: 2,
                                          ),
                                          color: checked
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.transparent,
                                        ),
                                        child: checked
                                            ? const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                    title: Text(
                                      '${ing.name} (${ing.quantity} ${ing.unit})',
                                      style: checked
                                          ? const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            )
                                          : const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                    ),
                                    onTap: () async {
                                      setState(
                                        () => _checked[origIdx] =
                                            !_checked[origIdx],
                                      );
                                      await _archiveIfAllChecked();
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
          },
        );
      },
    );
  }
}
