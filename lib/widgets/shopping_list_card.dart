import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import 'reminder_info_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reminder_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              .collection('shoppingList')
              .doc(list.name)
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
                    print(
                      '[DEBUG] Writing reminder to Firestore: $selected for list: ${list.name}',
                    );
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('shoppingList')
                        .doc(list.name)
                        .set({'reminder': selected}, SetOptions(merge: true));
                    print('[DEBUG] Firestore write successful');
                  } catch (e, st) {
                    print(
                      '[ERROR] Failed to write reminder to Firestore: $e\n$st',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to set reminder: $e')),
                      );
                    }
                  }
                }
              }
            }

            return Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
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
                        ReminderInfoCard(
                          reminder: reminder,
                          onClearReminder: () async {
                            ref
                                .read(reminderProvider(list.name).notifier)
                                .clear();
                            // Update Firestore under users/{userId}/shoppingList/{list.name}
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('shoppingList')
                                .doc(list.name)
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  // shadows: [
                                  //   Shadow(
                                  //     color: Colors.black54,
                                  //     offset: Offset(0, 1),
                                  //     blurRadius: 4,
                                  //   ),
                                  // ],
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.black,
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
                                    ),
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
                                  final checked =
                                      indexed[sortedIdx]['checked'] as bool;
                                  final origIdx =
                                      indexed[sortedIdx]['index'] as int;
                                  return ListTile(
                                    leading: InkWell(
                                      onTap: () {
                                        setState(
                                          () => _checked[origIdx] =
                                              !_checked[origIdx],
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
                                              decoration:
                                                  TextDecoration.lineThrough,
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
                                        () => _checked[origIdx] =
                                            !_checked[origIdx],
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
          },
        );
      },
    );
  }
}
