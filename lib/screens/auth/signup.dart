import 'package:flutter/material.dart';
import 'signin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:savourai/providers/auth_providers.dart';
import 'package:savourai/utils/form_validators.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  //final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    //_confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _errorMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final result = await authNotifier.signUpWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!result.isSuccess) {
        _errorMessage = result.error ?? 'Sign up failed';
      }
    });
    if (result.isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),

          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset('assets/images/savour.png', height: 180),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Account',
                    style: ShadTheme.of(context).textTheme.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: ShadTheme.of(context).textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  ShadInputFormField(
                    controller: _nameController,
                    id: 'name',
                    label: const Text('Full Name'),
                    placeholder: const Text('Enter your full name'),
                    validator: validateName,
                    leading: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  ShadInputFormField(
                    controller: _emailController,
                    id: 'email',
                    label: const Text('Email Address'),
                    placeholder: const Text('Enter your email'),
                    validator: validateEmail,
                    leading: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  ShadInputFormField(
                    controller: _passwordController,
                    id: 'password',
                    label: const Text('Password'),
                    placeholder: const Text('Enter your password'),
                    validator: validatePassword,
                    obscureText: _obscurePassword,
                    leading: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.lock_outline),
                    ),
                    trailing: ShadButton.ghost(
                      width: 24,
                      height: 24,
                      padding: EdgeInsets.zero,
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  //ShadInputFormField(
                  //   controller: _confirmPasswordController,
                  //   id: 'confirm_password',
                  //   label: const Text('Confirm Password'),
                  //   placeholder: const Text('Re-enter your password'),
                  //   validator: (value) => validateConfirmPassword(
                  //     value,
                  //     _passwordController.text,
                  //   ),
                  //   obscureText: _obscurePassword,
                  //   leading: const Padding(
                  //     padding: EdgeInsets.all(4.0),
                  //     child: Icon(Icons.lock_outline),
                  //   ),
                  //   textInputAction: TextInputAction.done,
                  // ),
                  // const SizedBox(height: 24),
                  ShadButton(
                    onPressed: _isLoading ? null : _signUp,
                    width: double.infinity,
                    size: ShadButtonSize.lg,
                    child: _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Signing up...'),
                            ],
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                      ShadButton.ghost(
                        size: ShadButtonSize.sm,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                          );
                        },
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
