import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:bemichat/repository/fb_auth_repo.dart';
import 'package:bemichat/router/app_router.dart';
import 'package:bemichat/screens/home/inbox_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuthRepository().logout();
      if (!mounted) return;
      context.go(AppPaths.login);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  Future<void> _showSettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final profileDoc = currentUser == null
        ? null
        : await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final displayName =
            currentUser?.displayName ??
            profileDoc?.data()?['displayName'] ??
            'User';
        final email = currentUser?.email ?? 'No email';

        return Container(
          decoration: const BoxDecoration(
            color: NeomorphismTheme.backgroundGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: NeomorphismTheme.mediumGrey,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: NeomorphismTheme.accentPurple.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: NeomorphismTheme.accentPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: NeomorphismTheme.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              color: NeomorphismTheme.mediumGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: 'Account',
                  subtitle: 'Manage your profile and status',
                  onTap: () {},
                ),
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Configure push updates',
                  onTap: () {},
                ),
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  subtitle: 'End your current session',
                  onTap: _logout,
                  destructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changePage(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const InboxScreen(showScaffold: false),
      const _CallsLogScreen(),
      const _ComingSoonScreen(title: 'Discover'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            key: ValueKey<String>(
              ['Chats', 'Calls', 'Discover'][_currentIndex],
            ),
            ['Chats', 'Calls', 'Discover'][_currentIndex],
            style: const TextStyle(
              color: NeomorphismTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        backgroundColor: NeomorphismTheme.backgroundGrey,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'home_ai_fab',
                    onPressed: () => context.push('/ai-chat'),
                    tooltip: 'AI Chat',
                    elevation: 0,
                    child: const Icon(Icons.smart_toy_rounded),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'home_new_chat_fab',
                    onPressed: () => context.push('/search-users'),
                    tooltip: 'New chat',
                    elevation: 0,
                    child: const Icon(Icons.message_rounded),
                  ),
                ],
              ),
            )
          : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NeomorphismTheme.backgroundGrey,
          boxShadow: NeomorphismTheme.softShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chats',
                    selected: _currentIndex == 0,
                    onTap: () => _changePage(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.call_outlined,
                    label: 'Calls',
                    selected: _currentIndex == 1,
                    onTap: () => _changePage(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.explore_outlined,
                    label: 'Discover',
                    selected: _currentIndex == 2,
                    onTap: () => _changePage(2),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? NeomorphismTheme.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected ? NeomorphismTheme.mediumShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected
                  ? NeomorphismTheme.accentPurple
                  : NeomorphismTheme.mediumGrey,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? NeomorphismTheme.accentPurple
                    : NeomorphismTheme.mediumGrey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: NeomorphismTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NeomorphismTheme.softShadow,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: destructive
              ? NeomorphismTheme.errorRed
              : NeomorphismTheme.accentPurple,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: destructive
                ? NeomorphismTheme.errorRed
                : NeomorphismTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: NeomorphismTheme.mediumGrey),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CallsLogScreen extends StatelessWidget {
  const _CallsLogScreen();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('calls')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: NeomorphismTheme.accentPurple,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No recent calls',
              style: TextStyle(color: NeomorphismTheme.textDark),
            ),
          );
        }

        final calls = snapshot.data!.docs
            .map((doc) => CallLogEntry.fromDoc(doc))
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: calls.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final call = calls[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NeomorphismTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                boxShadow: NeomorphismTheme.softShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: NeomorphismTheme.accentPurple.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      call.status == 'missed'
                          ? Icons.call_missed
                          : Icons.call_rounded,
                      color: NeomorphismTheme.accentPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          call.callerName.isNotEmpty
                              ? call.callerName
                              : 'Unknown caller',
                          style: const TextStyle(
                            color: NeomorphismTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          call.statusLabel,
                          style: const TextStyle(
                            color: NeomorphismTheme.mediumGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    call.formattedTime,
                    style: const TextStyle(
                      color: NeomorphismTheme.mediumGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class CallLogEntry {
  const CallLogEntry({
    required this.callerName,
    required this.status,
    required this.createdAt,
  });

  final String callerName;
  final String status;
  final DateTime? createdAt;

  factory CallLogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CallLogEntry(
      callerName: (data?['callerName'] as String?) ?? 'Unknown caller',
      status: (data?['status'] as String?) ?? 'ended',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'ringing':
        return 'Incoming';
      case 'accepted':
        return 'Connected';
      case 'declined':
        return 'Declined';
      case 'missed':
        return 'Missed';
      default:
        return 'Ended';
    }
  }

  String get formattedTime {
    final date = createdAt;
    if (date == null) return '-';
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_rounded,
            size: 56,
            color: NeomorphismTheme.mediumGrey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: NeomorphismTheme.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon',
            style: TextStyle(color: NeomorphismTheme.mediumGrey),
          ),
        ],
      ),
    );
  }
}
