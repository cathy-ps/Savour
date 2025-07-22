import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savourai/screens/auth/welcome.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/user_profile_provider.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/widgets/sign_out_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: userProfile.when(
        data: (user) {
          final name = user?.name ?? 'No Name';
          final email = user?.email ?? 'No Email';
          final dietaryPreferences = user?.dietaryPreferences ?? [];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Section
              ShadCard(
                radius: BorderRadius.all(Radius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 24,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: AppColors.lightGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        onPressed: () async {
                          if (user == null) return;
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => _EditProfileShadDialog(
                              initialName: user.name,
                              initialPreferences: user.dietaryPreferences,
                            ),
                          );
                          if (result != null) {
                            final newName = result['name'] as String;
                            final newPrefs =
                                result['dietaryPreferences'] as List<String>;
                            await updateUserProfile(
                              name: newName,
                              dietaryPreferences: newPrefs,
                            );
                            ref.refresh(userProfileProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Personal Information',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              // Dietary Preferences Section
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // IconButton(
                          //   icon: const Icon(Icons.edit),
                          //   onPressed: () async {
                          //     if (user == null) return;
                          //     final result =
                          //         await showDialog<Map<String, dynamic>>(
                          //           context: context,
                          //           builder: (context) =>
                          //               _EditDietaryPreferencesShadDialog(
                          //                 initialPreferences:
                          //                     user.dietaryPreferences,
                          //               ),
                          //         );
                          //     if (result != null) {
                          //       final newPrefs =
                          //           result['dietaryPreferences']
                          //               as List<String>;
                          //       await updateUserProfile(
                          //         name: user.name,
                          //         dietaryPreferences: newPrefs,
                          //       );
                          //       ref.refresh(userProfileProvider);
                          //     }
                          //   },
                          // ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      dietaryPreferences.isNotEmpty
                          ? Wrap(
                              spacing: 8,
                              children: dietaryPreferences
                                  .map((pref) => Chip(label: Text(pref)))
                                  .toList(),
                            )
                          : Text(
                              'No dietary preferences set.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Account Section
              ShadCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: const Text('Change Password'),
                      onTap: () async {
                        if (user == null) return;
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: user.email,
                        );
                        if (context.mounted) {
                          ShadToaster.of(context).show(
                            const ShadToast(
                              description: Text('Password reset email sent.'),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => ShadDialog(
                            title: const Text('Delete Account'),
                            description: const Text(
                              'Are you sure you want to delete your account? This action cannot be undone.',
                            ),
                            actions: [
                              ShadButton.ghost(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ShadButton.destructive(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await FirebaseAuth.instance.currentUser?.delete();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const WelcomePage(),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ShadToaster.of(context).show(
                                ShadToast(
                                  description: Text(
                                    'Failed to delete account: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // About Section
              ShadCard(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text(
                    'SavourAI v1.0.0\nA smart food and recipe assistant.',
                  ),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'SavourAI',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2024 SavourAI Team',
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Sign Out Button
              ShadButton.destructive(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 350,
                            minWidth: 200,
                          ),
                          child: SignOutCard(
                            onSignOut: () async {
                              Navigator.of(context).pop(true);
                            },
                            onCancel: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                  if (result == true) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const WelcomePage(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                child: const Text('Sign Out'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// Enhanced dietary preferences dialog using shadcn_ui
class _EditDietaryPreferencesShadDialog extends StatefulWidget {
  final List<String> initialPreferences;
  const _EditDietaryPreferencesShadDialog({required this.initialPreferences});

  @override
  State<_EditDietaryPreferencesShadDialog> createState() =>
      _EditDietaryPreferencesShadDialogState();
}

class _EditDietaryPreferencesShadDialogState
    extends State<_EditDietaryPreferencesShadDialog> {
  late List<String> _selectedPreferences;
  static const List<String> _allPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Halal',
    'Kosher',
    'Pescatarian',
    'Low-Carb',
    'Low-Fat',
    'Keto',
    'Paleo',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPreferences = List<String>.from(widget.initialPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Edit Dietary Preferences'),
      description: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          children: _allPreferences.map((pref) {
            final selected = _selectedPreferences.contains(pref);
            return FilterChip(
              label: Text(pref),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedPreferences.add(pref);
                  } else {
                    _selectedPreferences.remove(pref);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        ShadButton.ghost(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'dietaryPreferences': _selectedPreferences});
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Profile edit dialog using shadcn_ui
class _EditProfileShadDialog extends StatefulWidget {
  final String initialName;
  final List<String> initialPreferences;
  const _EditProfileShadDialog({
    required this.initialName,
    required this.initialPreferences,
  });

  @override
  State<_EditProfileShadDialog> createState() => _EditProfileShadDialogState();
}

class _EditProfileShadDialogState extends State<_EditProfileShadDialog> {
  late TextEditingController _nameController;
  late List<String> _selectedPreferences;
  static const List<String> _allPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Halal',
    'Kosher',
    'Pescatarian',
    'Low-Carb',
    'Low-Fat',
    'Keto',
    'Paleo',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedPreferences = List<String>.from(widget.initialPreferences);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Edit Profile'),
      description: SingleChildScrollView(
        child: Material(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Name'),
              ShadInput(
                controller: _nameController,
                placeholder: const Text('Enter your name'),
              ),
              const SizedBox(height: 16),
              const Text('Dietary Preferences'),
              Wrap(
                spacing: 8,
                children: _allPreferences.map((pref) {
                  final selected = _selectedPreferences.contains(pref);
                  return FilterChip(
                    label: Text(pref),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedPreferences.add(pref);
                        } else {
                          _selectedPreferences.remove(pref);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Flexible(
              child: ShadButton.ghost(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: ShadButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'name': _nameController.text.trim(),
                    'dietaryPreferences': _selectedPreferences,
                  });
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
