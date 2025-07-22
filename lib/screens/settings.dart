import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savourai/screens/auth/welcome.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/user_profile_provider.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/widgets/sign_out_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: userProfile.when(
        data: (user) {
          final name = user?.name ?? 'No Name';
          final email = user?.email ?? 'No Email';
          //final dietaryPreferences = user?.dietaryPreferences ?? [];
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Card at the top
              ShadCard(
                radius: const BorderRadius.all(Radius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 24,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Account Section
              const _SectionHeader(title: 'Account'),
              _SettingsTile(
                title: 'Edit Name',
                onTap: () async {
                  final newName = await showDialog<String>(
                    context: context,
                    builder: (context) => EditNameDialog(initialName: name),
                  );
                  if (newName != null &&
                      newName.isNotEmpty &&
                      newName != name) {
                    await updateUserName(newName);
                    ref.invalidate(userProfileProvider);
                  }
                },
              ),
              _SettingsTile(
                title: 'Change Password',
                onTap: () async {
                  final newPassword = await showDialog<String>(
                    context: context,
                    builder: (context) => const ChangePasswordDialog(),
                  );
                  if (newPassword != null && newPassword.isNotEmpty) {
                    await changeUserPassword(newPassword);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully.'),
                      ),
                    );
                  }
                },
              ),
              _SettingsTile(
                title: 'Set Dietary Preferences',
                onTap: () async {
                  final newPrefs = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => SetDietaryPreferencesDialog(
                      initialPreferences: user?.dietaryPreferences ?? [],
                    ),
                  );
                  if (newPrefs != null) {
                    await updateUserDietaryPreferences(newPrefs);
                    ref.invalidate(userProfileProvider);
                  }
                },
              ),

              const SizedBox(height: 24),
              // Notifications Section
              const _SectionHeader(title: 'Notifications'),
              _SwitchTile(
                title: 'App notification',
                value: true,
                onChanged: (v) {},
              ),
              const SizedBox(height: 24),
              // More Section
              const _SectionHeader(title: 'About'),
              _SettingsTile(
                title: 'About Savour',
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    isScrollControlled: true,
                    builder: (context) => const AboutBottomSheet(),
                  );
                },
              ),

              const SizedBox(height: 24),
              // Logout Button
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
        error: (error, stackTrace) =>
            Center(child: Text('Error loading profile: $error')),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SettingsTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, color: Colors.black),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, color: Colors.black),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }
}

// Dialog for editing the user's name
class EditNameDialog extends StatefulWidget {
  final String initialName;
  const EditNameDialog({required this.initialName});

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Edit Name'),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Name'),
          ShadInput(
            controller: _nameController,
            placeholder: const Text('Enter your name'),
          ),
        ],
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
                  Navigator.of(context).pop(_nameController.text.trim());
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

// Dialog for changing password
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Change Password'),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Password'),
          ShadInput(
            controller: _passwordController,
            obscureText: _obscure,
            placeholder: const Text('Enter new password'),
          ),
          const SizedBox(height: 16),
          const Text('Confirm Password'),
          ShadInput(
            controller: _confirmController,
            obscureText: _obscure,
            placeholder: const Text('Re-enter new password'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ],
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
                  if (_passwordController.text == _confirmController.text &&
                      _passwordController.text.isNotEmpty) {
                    Navigator.of(context).pop(_passwordController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match.')),
                    );
                  }
                },
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Dialog for setting dietary preferences
class SetDietaryPreferencesDialog extends StatefulWidget {
  final List<String> initialPreferences;
  const SetDietaryPreferencesDialog({
    required this.initialPreferences,
    super.key,
  });

  @override
  State<SetDietaryPreferencesDialog> createState() =>
      _SetDietaryPreferencesDialogState();
}

class _SetDietaryPreferencesDialogState
    extends State<SetDietaryPreferencesDialog> {
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
      title: const Text('Set Dietary Preferences'),
      description: Wrap(
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
                  Navigator.of(context).pop(_selectedPreferences);
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

// About Bottom Sheet
class AboutBottomSheet extends StatelessWidget {
  const AboutBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Savour',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const Text(
            'About the App',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Savour is your intelligent food companion, designed to help you make better dietary choices and manage your food preferences with ease. Our mission is to empower users to discover, track, and personalize their food journey, whether you have specific dietary needs or simply want to eat healthier.\n\n'
            'Features include:\n'
            '- Personalized dietary preference management\n'
            '- Secure profile and password management\n'
            '- Smart notifications and reminders\n'
            '- Clean, modern UI with accessibility in mind\n\n'
            'We hope Savour helps you enjoy food that fits your lifestyle. Your feedback and suggestions are always welcome!',
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2025 Savour Team',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
