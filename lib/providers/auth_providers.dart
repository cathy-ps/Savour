import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

// Auth state stream provider
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// Auth result class for better error handling
class AuthResult {
  final User? user;
  final String? error;
  final bool isSuccess;

  AuthResult._({this.user, this.error, required this.isSuccess});

  factory AuthResult.success(User user) =>
      AuthResult._(user: user, isSuccess: true);
  factory AuthResult.error(String error) =>
      AuthResult._(error: error, isSuccess: false);
}

// Enhanced Auth Notifier with business logic
class AuthNotifier extends Notifier<AsyncValue<User?>> {
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  @override
  AsyncValue<User?> build() {
    // Subscribe to auth state changes
    final authState = ref.watch(authStateProvider);
    return authState;
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        return AuthResult.success(credential.user!);
      } else {
        return AuthResult.error('Sign in failed');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      // Create user document in Firestore and default cookbook
      final user = credential.user;
      if (user != null) {
        try {
          final userDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          await userDoc.set({
            'name': displayName ?? '',
            'email': email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'userPreferences': <String>[],
          });

          // Create a default cookbook for the user
          final cookbooksCollection = userDoc.collection('cookbooks');
          await cookbooksCollection.add({
            
                    'title':
                'Favorites',
            'createdAt': FieldValue.serverTimestamp(),
            'recipeCount': 0,
            'color': 0xFF2196F3, // Default blue
          });
        } catch (e) {
          // Firestore write failed, but user is created in Auth
        }
        return AuthResult.success(user);
      } else {
        return AuthResult.error('Account creation failed');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Handle sign out error if needed
      rethrow;
    }
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('Failed to send reset email');
    }
  }

  // Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.error('No user signed in');
      }

      await user.delete();
      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('Failed to delete account');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Helper method to convert Firebase errors to user-friendly messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}

// Auth notifier provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(
  () => AuthNotifier(),
);

// Convenience providers for common auth states
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final isLoadingAuthProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});
