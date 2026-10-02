import 'package:bemichat/components/roundbutton.dart';
import 'package:bemichat/components/textfield.dart';
import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:bemichat/repository/fb_auth_repo.dart';
import 'package:bemichat/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Created once, not on every rebuild.
  final _firebaseRepo = FirebaseAuthRepository();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _firebaseRepo.signup(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      _showMessage('Account created successfully');
      context.go(AppPaths.profileSetup);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError 
              ? NeomorphismTheme.errorRed 
              : NeomorphismTheme.accentPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Create account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: NeomorphismTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join BemiChat to start messaging',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: NeomorphismTheme.mediumGrey,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email Field
                  Inputtextfield(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    label: 'Email',
                    hint: 'you@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_loading,
                    validator: _validateEmail,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 20),
                  // Password Field
                  Inputtextfield(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    label: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    enabled: !_loading,
                    validator: _validatePassword,
                    onSubmitted: (_) => _signup(),
                  ),
                  const SizedBox(height: 28),
                  // Signup Button
                  RoundButton(
                    title: 'Create Account',
                    loading: _loading,
                    ontap: _signup,
                  ),
                  const SizedBox(height: 20),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: NeomorphismTheme.textDark,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextButton(
                        onPressed: _loading 
                            ? null 
                            : () => context.go(AppPaths.login),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            color: NeomorphismTheme.accentPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
