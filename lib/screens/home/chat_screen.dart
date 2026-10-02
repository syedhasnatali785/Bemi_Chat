import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:bemichat/models/chat_model.dart';
import 'package:bemichat/providers/call_provider.dart';
import 'package:bemichat/providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.title = 'Chat',
  });

  final String chatId;
  final String otherUserId;
  final String title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return; // not signed in

    // ignore: avoid_print
    print(
      '💬 CHAT: User $userId sending message to chat ${widget.chatId}: "$text"',
    );

    _textController.clear();
    ref.read(sendingMessageProvider.notifier).state = true;
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(chatId: widget.chatId, senderId: userId, text: text);
      // ignore: avoid_print
      print('💬 CHAT: ✓ Message sent successfully');
      // New message arrives via the stream; nudge the list down.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      // ignore: avoid_print
      print('💬 CHAT: ❌ Failed to send message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    } finally {
      if (mounted) ref.read(sendingMessageProvider.notifier).state = false;
    }
  }

  Future<void> _startCall() async {
    final callService = ref.read(callServiceProvider);
    final peerName = Uri.encodeComponent(widget.title);

    context.push('/call/voice?peerName=$peerName');

    try {
      await callService.startCall(
        myName: widget.title,
        calleeId: widget.otherUserId,
        calleeName: widget.title,
      );
    } catch (e) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start call: $e')));
    }
  }

  Future<void> _showOtherUserProfile() async {
    if (widget.otherUserId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();
    final data = doc.data() ?? {};
    final displayName = (data['displayName'] as String?) ?? widget.title;
    final handle = (data['handle'] as String?) ?? '';
    final photoUrl = (data['photoUrl'] as String?) ?? '';

    if (!mounted) return;

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
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
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
                        Icons.call_rounded,
                        color: NeomorphismTheme.accentPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Call or message ${displayName.isNotEmpty ? displayName : 'this user'}',
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

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final sending = ref.watch(sendingMessageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              color: NeomorphismTheme.accentPurple,
            ),
            tooltip: 'Profile',
            onPressed: _showOtherUserProfile,
          ),
          IconButton(
            icon: const Icon(
              Icons.call_outlined,
              color: NeomorphismTheme.accentPurple,
            ),
            tooltip: 'Call',
            onPressed: _startCall,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: NeomorphismTheme.accentPurple,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Failed to load chat: $err',
                    style: const TextStyle(color: NeomorphismTheme.textDark),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
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
                            'No messages yet',
                            style: TextStyle(
                              color: NeomorphismTheme.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Say hi to start the conversation!',
                            style: TextStyle(
                              color: NeomorphismTheme.mediumGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // Scroll to bottom once new data renders.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      return _MessageBubble(message: message, isMe: isMe);
                    },
                  );
                },
              ),
            ),
            _MessageInputBar(
              controller: _textController,
              sending: sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? NeomorphismTheme.accentPurple
        : NeomorphismTheme.lightGrey;
    final fg = isMe ? NeomorphismTheme.surfaceWhite : NeomorphismTheme.textDark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: NeomorphismTheme.mediumShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.Hm().format(message.createdAt),
              style: TextStyle(
                color: fg.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeomorphismTheme.backgroundGrey,
        boxShadow: NeomorphismTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: NeomorphismTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: NeomorphismTheme.mediumShadow,
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(
                    color: NeomorphismTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(
                      color: NeomorphismTheme.mediumGrey,
                      fontSize: 14,
                    ),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (sending)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: NeomorphismTheme.surfaceWhite,
                  shape: BoxShape.circle,
                  boxShadow: NeomorphismTheme.softShadow,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        NeomorphismTheme.accentPurple,
                      ),
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: NeomorphismTheme.accentPurple,
                    shape: BoxShape.circle,
                    boxShadow: NeomorphismTheme.softShadow,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: NeomorphismTheme.surfaceWhite,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
