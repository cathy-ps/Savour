import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SignOutCard extends StatelessWidget {
  final VoidCallback onSignOut;
  final VoidCallback onCancel;

  const SignOutCard({super.key, required this.onSignOut, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      width: double.infinity,

      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign Out',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: ShadButton.ghost(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: ShadButton.destructive(
                    onPressed: onSignOut,
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
