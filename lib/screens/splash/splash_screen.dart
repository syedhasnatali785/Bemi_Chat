import 'package:bemichat/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash screen shown on app start.
///
/// - Shows the app logo/name with a simple fade + scale animation.
/// - After a short delay, checks Firebase auth state and navigates to
///   home (if logged in) or login (if not).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _navigateNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  // Future<void> isCompleted()async{
  //   final user = FirebaseAuth.instance.currentUser?.uid;
  // final doc = await FirebaseFirestore.instance.collection('users').doc(user).get();
  // final profileCompleted = doc.data()?['isCompleted'] == true;
  // if(profileCompleted){
  //   Navigator.push(context, MaterialPageRoute(builder: (context)=>InboxScreen()));
  // }else {
  //   Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileSetupScreen()));

  // }
  // }
  Future<void> _navigateNext() async {
    // Minimum splash duration, independent of any real auth check delay.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      context.go(AppPaths.login);
      return;
    }
    if (!mounted) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final profileCompleted = doc.data()?['isCompleted'] == true;
    if (profileCompleted) {
      if (!mounted) return;
      context.go(AppPaths.inbox);
    } else {
      if (!mounted) return;
      context.go(AppPaths.profileSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bolt_rounded, // TODO: replace with your app logo
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bemi Chat', // TODO: replace with your app name
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
