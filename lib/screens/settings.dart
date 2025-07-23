import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savourai/screens/auth/welcome.dart';
import 'package:savourai/utils/form_validators.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/user_profile_provider.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/constant/dietary_preferences.dart';
import 'package:savourai/widgets/sign_out_card.dart';
import 'package:savourai/providers/auth_providers.dart';
import 'package:savourai/widgets/custom_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Settings'),
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
                    ShadToaster.of(context).show(
                      ShadToast(
                        title: const Text('Password changed successfully.'),
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

              // More Section
              const _SectionHeader(title: 'Others'),

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

// class _SwitchTile extends StatelessWidget {
//   final String title;
//   final bool value;
//   final ValueChanged<bool> onChanged;
//   const _SwitchTile({
//     required this.title,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SwitchListTile(
//       contentPadding: EdgeInsets.zero,
//       title: Text(
//         title,
//         style: const TextStyle(fontSize: 15, color: Colors.black),
//       ),
//       value: value,
//       onChanged: onChanged,
//       activeColor: Colors.blue,
//     );
//   }
// }

// Dialog for editing the user's name
class EditNameDialog extends StatefulWidget {
  final String initialName;
  const EditNameDialog({super.key, required this.initialName});

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
    //return Padding(
    //padding: const EdgeInsets.all(50.0),
    return ShadDialog(
      //radius: const BorderRadius.all(Radius.circular(30)),
      title: const Text('Edit Name'),
      constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //const Text('Name'),
          ShadInputFormField(
            controller: _nameController,
            id: 'name',
            label: const Text('Name'),
            placeholder: const Text('Enter your name'),
            validator: validateName,
            leading: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
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
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _currentObscure = true;
  bool _passwordObscure = true;
  bool _confirmObscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword(BuildContext context) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final currentPassword = _currentController.text.trim();
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() {
        _loading = false;
        _error = 'Passwords do not match.';
      });
      return;
    }
    if (newPassword.isEmpty || currentPassword.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please fill in all fields.';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) {
      setState(() {
        _loading = false;
        _error = 'No user signed in.';
      });
      return;
    }

    // Use Riverpod to access AuthNotifier
    final container = ProviderScope.containerOf(context, listen: false);
    final authNotifier = container.read(authNotifierProvider.notifier);
    final result = await authNotifier.reauthenticateWithPassword(
      email: email,
      currentPassword: currentPassword,
    );
    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.error ?? 'Incorrect current password.';
      });
      return;
    }

    // If re-auth successful, return new password to parent
    setState(() {
      _loading = false;
    });
    Navigator.of(context).pop(newPassword);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
      title: const Text('Change Password'),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadInputFormField(
            label: const Text('Current Password'),
            controller: _currentController,
            id: 'current_password',
            obscureText: _currentObscure,
            placeholder: const Text('Enter current password'),
            leading: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.lock_outline),
            ),
            trailing: IconButton(
              icon: Icon(
                _currentObscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _currentObscure = !_currentObscure),
            ),
          ),
          const SizedBox(height: 16),
          ShadInputFormField(
            label: const Text('New Password'),
            controller: _passwordController,
            id: 'new_password',
            obscureText: _passwordObscure,
            placeholder: const Text('Enter new password'),
            leading: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.lock_outline),
            ),
            trailing: IconButton(
              icon: Icon(
                _passwordObscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _passwordObscure = !_passwordObscure),
            ),
          ),
          const SizedBox(height: 16),
          ShadInputFormField(
            label: const Text('Confirm Password'),
            controller: _confirmController,
            id: 'confirm_password',
            obscureText: _confirmObscure,
            placeholder: const Text('Re-enter new password'),
            leading: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.lock_outline),
            ),
            trailing: IconButton(
              icon: Icon(
                _confirmObscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _confirmObscure = !_confirmObscure),
            ),
          ),
          const SizedBox(height: 14),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        Row(
          children: [
            Flexible(
              child: ShadButton.ghost(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: ShadButton(
                onPressed: _loading
                    ? null
                    : () => _handleChangePassword(context),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change'),
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
  // Use the shared dietary preferences constant

  @override
  void initState() {
    super.initState();
    _selectedPreferences = List<String>.from(widget.initialPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
      title: const Text('Set Dietary Preferences'),
      description: Material(
        color: Colors.transparent,
        child: Wrap(
          spacing: 8,
          children: kAllDietaryPreferences.map((pref) {
            final selected = _selectedPreferences.contains(pref);
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 2.0,
              ),
              child: FilterChip(
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
              ),
            );
          }).toList(),
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
          Center(
            child: Text(
              'Photos provided by Pexels',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
