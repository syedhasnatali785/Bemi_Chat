import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:bemichat/models/inbox_model.dart';
import 'package:bemichat/providers/chat_provider.dart';
import 'package:bemichat/providers/inbox_provider.dart';
import 'package:bemichat/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final isToday =
        dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
    return isToday
        ? DateFormat.Hm().format(dateTime)
        : DateFormat.MMMd().format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(inboxListProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    final body = SafeArea(
      child: chatsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: NeomorphismTheme.accentPurple,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load chats: $err',
            style: const TextStyle(color: NeomorphismTheme.textDark),
          ),
        ),
        data: (chats) {
          if (currentUserId == null) {
            return const Center(
              child: Text(
                'Please log in to see your chats',
                style: TextStyle(color: NeomorphismTheme.textDark),
              ),
            );
          }
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_rounded,
                    size: 64,
                    color: NeomorphismTheme.mediumGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No chats yet',
                    style: TextStyle(
                      color: NeomorphismTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a conversation to begin chatting',
                    style: TextStyle(
                      color: NeomorphismTheme.mediumGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatTile(
                chat: chat,
                currentUserId: currentUserId,
                timeLabel: _formatTime(chat.lastMessageAt),
                onTap: () {
                  context.push(
                    '/chat/${chat.id}?title=${Uri.encodeComponent(chat.otherUserName(currentUserId))}&otherUserId=${Uri.encodeComponent(chat.otherUserId(currentUserId))}',
                  );
                },
                onProfileTap: () => _showOtherUserProfile(
                  context,
                  chat.otherUserId(currentUserId),
                  chat.otherUserName(currentUserId),
                  chat.otherUserPhoto(currentUserId),
                ),
              );
            },
          );
        },
      ),
    );

    if (!showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats'), elevation: 0),
      body: body,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'ai_chat_fab',
              onPressed: () => context.push(AppPaths.aiChat),
              tooltip: 'AI Chat',
              elevation: 0,
              child: const Icon(Icons.smart_toy_rounded),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'new_chat_fab',
              onPressed: () => context.push(AppPaths.searchUsers),
              tooltip: 'New chat',
              elevation: 0,
              child: const Icon(Icons.message_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOtherUserProfile(
    BuildContext context,
    String otherUserId,
    String otherUserName,
    String photoUrl,
  ) async {
    if (otherUserId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get();
    final data = doc.data() ?? {};
    final displayName = (data['displayName'] as String?) ?? otherUserName;
    final handle = (data['handle'] as String?) ?? '';
    final imageUrl = (data['photoUrl'] as String?) ?? photoUrl;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: NeomorphismTheme.backgroundGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                const SizedBox(height: 18),
                CircleAvatar(
                  radius: 42,
                  backgroundColor: NeomorphismTheme.accentPurple.withValues(
                    alpha: 0.12,
                  ),
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: NeomorphismTheme.accentPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: NeomorphismTheme.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '@$handle',
                    style: const TextStyle(
                      color: NeomorphismTheme.mediumGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeomorphismTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: NeomorphismTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.message_rounded,
                        color: NeomorphismTheme.accentPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Start or continue a conversation with ${displayName.isNotEmpty ? displayName : 'this user'}',
                          style: const TextStyle(
                            color: NeomorphismTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.timeLabel,
    required this.onTap,
    required this.onProfileTap,
  });

  final InboxModel chat;
  final String currentUserId;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final name = chat.otherUserName(currentUserId);
    final photo = chat.otherUserPhoto(currentUserId);
    final isLastFromMe = chat.lastSenderId == currentUserId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: NeomorphismTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: NeomorphismTheme.softShadow,
        ),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: NeomorphismTheme.accentPurple.withValues(
                  alpha: 0.1,
                ),
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: NeomorphismTheme.accentPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NeomorphismTheme.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage.isEmpty
                        ? 'Say hi 👋'
                        : (isLastFromMe
                              ? 'You: ${chat.lastMessage}'
                              : chat.lastMessage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: NeomorphismTheme.mediumGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time
            Text(
              timeLabel,
              style: const TextStyle(
                color: NeomorphismTheme.mediumGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
