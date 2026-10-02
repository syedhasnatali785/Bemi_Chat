import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:bemichat/models/search_user_model.dart';
import 'package:bemichat/providers/search_user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchUserScreen extends ConsumerStatefulWidget {
  const SearchUserScreen({super.key});

  @override
  ConsumerState<SearchUserScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<SearchUserScreen> {
  final _searchController = TextEditingController();
  String? _startingChatWithUid; // disables the tapped tile while creating

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChatWith(SearchUserModel user) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    setState(() => _startingChatWithUid = user.uid);
    try {
      final chatId = await findOrCreateChat(
        myUid: me.uid,
        myName: me.displayName ?? '',
        myPhoto: me.photoURL ?? '',
        otherUser: user,
      );

      if (!mounted) return;
      final encodedTitle = Uri.encodeComponent(user.displayName);
      final encodedOtherUserId = Uri.encodeComponent(user.uid);
      context.pushReplacement(
        '/chat/$chatId?title=$encodedTitle&otherUserId=$encodedOtherUserId',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start chat. Try again.')),
      );
      setState(() => _startingChatWithUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchControllerProvider);
    final controller = ref.read(userSearchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('New chat'), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: NeomorphismTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: NeomorphismTheme.mediumShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: controller.search,
                  style: const TextStyle(
                    color: NeomorphismTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by handle',
                    hintStyle: const TextStyle(
                      color: NeomorphismTheme.mediumGrey,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: NeomorphismTheme.mediumGrey,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: NeomorphismTheme.mediumGrey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              controller.clear();
                            },
                          ),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: NeomorphismTheme.accentPurple,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(searchState)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SearchUserState state) {
    if (state.query.isEmpty) {
      return const Center(
        child: Text(
          'Search for a handle to start a chat',
          style: TextStyle(color: NeomorphismTheme.textDark, fontSize: 16),
        ),
      );
    }
    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(color: NeomorphismTheme.accentPurple),
      );
    }
    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(color: NeomorphismTheme.textDark),
        ),
      );
    }
    if (state.results.isEmpty) {
      return Center(
        child: Text(
          'No users found for "${state.query}"',
          style: const TextStyle(color: NeomorphismTheme.textDark),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = state.results[index];
        final starting = _startingChatWithUid == user.uid;

        return GestureDetector(
          onTap: _startingChatWithUid == null
              ? () => _openChatWith(user)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: NeomorphismTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: NeomorphismTheme.softShadow,
              // opacity: _startingChatWithUid == null ? 1.0 : 0.5,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: NeomorphismTheme.accentPurple.withValues(
                    alpha: 0.1,
                  ),
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: NeomorphismTheme.accentPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName.isEmpty
                            ? user.handle
                            : user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NeomorphismTheme.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.handle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NeomorphismTheme.mediumGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (starting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        NeomorphismTheme.accentPurple,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
