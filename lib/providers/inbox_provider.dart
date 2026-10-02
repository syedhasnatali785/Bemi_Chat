import 'package:bemichat/models/inbox_model.dart';
import 'package:bemichat/providers/chat_provider.dart';
import 'package:bemichat/repository/inbox_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository();
});

/// Live list of the current user's chats. Emits an empty list when
/// signed out.
final inboxListProvider = StreamProvider.autoDispose<List<InboxModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  final repo = ref.watch(inboxRepositoryProvider);
  return repo.chatsForUser(userId);
});
