import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savourai/screens/auth/welcome.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/user_profile_provider.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/widgets/sign_out_card.dart';

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

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
                title: 'Edit Profile',
                onTap: () {
                  // showDialog(
                  //   context: context,
                  //   builder: (context) => _EditProfileShadDialog(
                  //     initialName: name,
                  //     initialPreferences: user?.dietaryPreferences ?? [],
                  //   ),
                  // ).then((result) {
                  //   if (result != null) {
                  //     ref.read(userProfileProvider.notifier).updateUserProfile(
                  //       name: result['name'],
                  //       dietaryPreferences: result['dietaryPreferences'],
                  //     );
                  //   }
                  // });
                },
              ),
              _SettingsTile(title: 'Change Password', onTap: () {}),
              _SettingsTile(title: 'Set Dietary Preferences', onTap: () {}),
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
              _SettingsTile(title: 'About', onTap: () {}),

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
              // Center(
              //   child: ElevatedButton.icon(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.white,
              //       foregroundColor: Colors.black,
              //       elevation: 2,
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 32,
              //         vertical: 12,
              //       ),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(24),
              //         side: const BorderSide(color: Colors.black12),
              //       ),
              //     ),
              //     icon: const Icon(Icons.logout, color: Colors.blue),
              //     label: const Text('Logout'),
              //     onPressed: () {},
              //   ),
              // ),
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

// class _EditProfileShadDialog extends StatefulWidget {
//   final String initialName;
//   final List<String> initialPreferences;
//   const _EditProfileShadDialog({
//     required this.initialName,
//     required this.initialPreferences,
//   });

//   @override
//   State<_EditProfileShadDialog> createState() => _EditProfileShadDialogState();
// }

// class _EditProfileShadDialogState extends State<_EditProfileShadDialog> {
//   late TextEditingController _nameController;
//   late List<String> _selectedPreferences;
//   static const List<String> _allPreferences = [
//     'Vegetarian',
//     'Vegan',
//     'Gluten-Free',
//     'Dairy-Free',
//     'Nut-Free',
//     'Halal',
//     'Kosher',
//     'Pescatarian',
//     'Low-Carb',
//     'Low-Fat',
//     'Keto',
//     'Paleo',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.initialName);
//     _selectedPreferences = List<String>.from(widget.initialPreferences);
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ShadDialog(
//       title: const Text('Edit Profile'),
//       description: SingleChildScrollView(
//         child: Material(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Name'),
//               ShadInput(
//                 controller: _nameController,
//                 placeholder: const Text('Enter your name'),
//               ),
//               const SizedBox(height: 16),
//               const Text('Dietary Preferences'),
//               Wrap(
//                 spacing: 8,
//                 children: _allPreferences.map((pref) {
//                   final selected = _selectedPreferences.contains(pref);
//                   return FilterChip(
//                     label: Text(pref),
//                     selected: selected,
//                     onSelected: (val) {
//                       setState(() {
//                         if (val) {
//                           _selectedPreferences.add(pref);
//                         } else {
//                           _selectedPreferences.remove(pref);
//                         }
//                       });
//                     },
//                   );
//                 }).toList(),
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         Row(
//           children: [
//             Flexible(
//               child: ShadButton.ghost(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancel'),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Flexible(
//               child: ShadButton(
//                 onPressed: () {
//                   Navigator.of(context).pop({
//                     'name': _nameController.text.trim(),
//                     'dietaryPreferences': _selectedPreferences,
//                   });
//                 },
//                 child: const Text('Save'),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
