import 'package:bemichat/models/chat_model.dart';
import 'package:bemichat/repository/fb_chat_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// Live message stream for a given chat id.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, chatId) {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.messages(chatId);
    });

/// Current signed-in user id, used to tell "my" bubbles from others'.
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Tracks whether a send is in flight, so the UI can disable the button.
final sendingMessageProvider = StateProvider.autoDispose<bool>((ref) => false);
