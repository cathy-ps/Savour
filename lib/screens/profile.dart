import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savourai/screens/auth/welcome.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/user_profile_provider.dart';
import 'package:savourai/constant/colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    return Scaffold(
      body: userProfile.when(
        data: (user) {
          final name = user?.name ?? 'No Name';
          final email = user?.email ?? 'No Email';
          final dietaryPreferences = user?.dietaryPreferences ?? [];
          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 48,
                      bottom: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            color: AppColors.darkGrey,
                            size: 40,
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
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  // Dietary Preferences Section
                  if (dietaryPreferences.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dietary Preferences',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: dietaryPreferences
                                .map((pref) => Chip(label: Text(pref)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  if (dietaryPreferences.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Text(
                        'No dietary preferences set.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  const Expanded(child: SizedBox()),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ShadButton.destructive(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => ShadDialog(
                          title: const Text('Sign Out'),
                          description: const Text(
                            'Are you sure you want to sign out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const WelcomePage(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('Sign Out'),
                  ),
                  // child: ElevatedButton.icon(
                  //   style: ElevatedButton.styleFrom(
                  //     minimumSize: const Size.fromHeight(48),
                  //     backgroundColor: Colors.redAccent,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(16),
                  //     ),
                  //   ),
                  //   icon: const Icon(Icons.logout, color: Colors.white),
                  //   label: const Text(
                  //     'Sign Out',
                  //     style: TextStyle(color: Colors.white, fontSize: 16),
                  //   ),
                  //   onPressed: () async {
                  //     await FirebaseAuth.instance.signOut();
                  //     Navigator.of(context).popUntil((route) => route.isFirst);
                  //   },
                  // ),
                ),
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
