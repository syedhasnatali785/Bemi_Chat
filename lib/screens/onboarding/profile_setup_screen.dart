import 'dart:async';
import 'package:bemichat/components/roundbutton.dart';
import 'package:bemichat/components/textfield.dart';
import 'package:bemichat/repository/setup_repo.dart';
import 'package:bemichat/router/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

enum _HandleStatus { idle, checking, available, taken, invalid }

/// Shown once, right after signup, to collect a display name, a unique
/// handle, and (optionally) a profile photo before entering the app.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _repo = ProfileSetupRepository();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _handleController = TextEditingController();

  static const _handlePattern = r'^[a-z0-9_]{3,20}$';
  static const _debounce = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  _HandleStatus _handleStatus = _HandleStatus.idle;
  int _checkId = 0;
  bool _saving = false;

  String? _photoUrl; // TODO: wire up image_picker + Storage to set this

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  void _onHandleChanged(String raw) {
    final handle = raw.trim().toLowerCase();
    _debounceTimer?.cancel();

    if (handle.isEmpty) {
      setState(() => _handleStatus = _HandleStatus.idle);
      return;
    }
    if (!RegExp(_handlePattern).hasMatch(handle)) {
      setState(() => _handleStatus = _HandleStatus.invalid);
      return;
    }

    setState(() => _handleStatus = _HandleStatus.checking);
    _debounceTimer = Timer(_debounce, () => _checkHandle(handle));
  }

  Future<void> _checkHandle(String handle) async {
    final myId = ++_checkId;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      final available = await _repo.isHandleAvailable(handle, myUid: uid);
      if (myId != _checkId || !mounted) return; // superseded by a newer check
      setState(() {
        _handleStatus = available
            ? _HandleStatus.available
            : _HandleStatus.taken;
      });
    } catch (_) {
      if (myId != _checkId || !mounted) return;
      setState(() => _handleStatus = _HandleStatus.idle);
    }
  }

  String? _validateName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'At least 2 characters';
    return null;
  }

  String? _validateHandle(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Handle is required';
    if (!RegExp(_handlePattern).hasMatch(value.toLowerCase())) {
      return '3-20 chars: letters, numbers, underscore';
    }
    if (_handleStatus == _HandleStatus.taken) return 'Handle is already taken';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_handleStatus == _HandleStatus.checking) return; // wait for the check
    if (_handleStatus == _HandleStatus.taken) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await _repo.saveProfile(
        uid: uid,
        displayName: _nameController.text.trim(),
        handle: _handleController.text.trim().toLowerCase(),
        photoUrl: _photoUrl ?? '',
         isCompleted: 'true',
      );

      if (!mounted) return;
      context.go(AppPaths.inbox);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _handleSuffixIcon() {
    switch (_handleStatus) {
      case _HandleStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _HandleStatus.available:
        return const Icon(Icons.check_circle, color: Colors.green);
      case _HandleStatus.taken:
      case _HandleStatus.invalid:
        return const Icon(Icons.error, color: Colors.red);
      case _HandleStatus.idle:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Text(
                    'Set up your profile',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is how others will find and see you',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Avatar picker placeholder
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: _photoUrl != null
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: _photoUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 48,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                // TODO: wire up image_picker + upload to
                                // Firebase Storage, then setState(() =>
                                // _photoUrl = uploadedUrl).
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Inputtextfield(
                    controller: _nameController,
                    label: 'Display name',
                    hint: 'Your name',
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 16),
                  Inputtextfield(
                    controller: _handleController,
                    label: 'Handle',
                    hint: 'your_handle',
                    prefixIcon: Icons.alternate_email,
                    textInputAction: TextInputAction.done,
                    enabled: !_saving,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]'),
                      ),
                    ],
                    validator: _validateHandle,
                    onChanged: _onHandleChanged,
                    suffixIcon: _handleSuffixIcon(),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _handleStatus == _HandleStatus.invalid
                          ? '3-20 characters: lowercase letters, numbers, underscore'
                          : 'Others can find you by this handle',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _handleStatus == _HandleStatus.invalid
                            ? theme.colorScheme.error
                            : theme.hintColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  RoundButton(
                    title: 'Continue',
                    loading: _saving,
                    ontap: _save,
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
