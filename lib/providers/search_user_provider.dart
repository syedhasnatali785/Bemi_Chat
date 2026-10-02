import 'dart:async';

import 'package:bemichat/models/search_user_model.dart';
import 'package:bemichat/providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/legacy.dart';

class SearchUserState {
  const SearchUserState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.error,
  });

  final String query;
  final List<SearchUserModel> results;
  final bool loading;
  final String? error;

  SearchUserState copyWith({
    String? query,
    List<SearchUserModel>? results,
    bool? loading,
    String? error,
  }) {
    return SearchUserState(
      query: query ?? this.query,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Searches `users` by `handle` prefix, as the user types.
///
/// - Debounced: waits [_debounce] after the last keystroke before querying,
///   so a fast typist doesn't fire a query per character.
/// - Throttled: even if triggered again sooner (e.g. programmatically),
///   won't issue a new Firestore read within [_throttle] of the last one.
/// - No search button: `search()` is called directly from the field's
///   onChanged.
class SearchUserController extends StateNotifier<SearchUserState> {
  SearchUserController({FirebaseFirestore? firestore, this.excludeUid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(const SearchUserState());

  final FirebaseFirestore _firestore;
  final String? excludeUid;

  static const _debounce = Duration(milliseconds: 400);
  static const _throttle = Duration(milliseconds: 600);
  static const _resultLimit = 15;

  Timer? _debounceTimer;
  DateTime? _lastQueryAt;
  int _requestId = 0;

  void search(String rawQuery) {
    final query = rawQuery.trim();
    state = state.copyWith(query: query);

    _debounceTimer?.cancel();

    if (query.isEmpty) {
      state = state.copyWith(results: [], loading: false, error: null);
      return;
    }

    _debounceTimer = Timer(_debounce, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    // Throttle guard: if a query just ran, wait out the remainder
    // before firing another one, so bursts collapse to one call.
    final lastQueryAt = _lastQueryAt;
    if (lastQueryAt != null) {
      final elapsed = DateTime.now().difference(lastQueryAt);
      if (elapsed < _throttle) {
        await Future.delayed(_throttle - elapsed);
        // The query box may have changed again during the wait;
        // only proceed if this call is still the latest request.
        if (state.query != query) return;
      }
    }

    final myRequestId = ++_requestId;
    _lastQueryAt = DateTime.now();
    state = state.copyWith(loading: true, error: null);

    try {
      final handleQuery = query.toLowerCase();
      final snap = await _firestore
          .collection('users')
          .orderBy('handle')
          .startAt([handleQuery])
          .endAt(['$handleQuery\uf8ff'])
          .limit(_resultLimit)
          .get();

      // Drop stale responses from a superseded request.
      if (myRequestId != _requestId) return;

      final users = snap.docs
          .map(SearchUserModel.fromDoc)
          .where((u) => u.uid != excludeUid)
          .toList();

      state = state.copyWith(results: users, loading: false);
    } catch (e) {
      if (myRequestId != _requestId) return;
      state = state.copyWith(
        loading: false,
        error: 'Search failed. Try again.',
      );
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const SearchUserState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final userSearchControllerProvider =
    StateNotifierProvider.autoDispose<SearchUserController, SearchUserState>(
      (ref) {
        final myUid = ref.watch(currentUserIdProvider);
        return SearchUserController(excludeUid: myUid);
      },
    );

/// Finds an existing 1-to-1 chat between the two users, or creates one.
/// Returns the chat id.
Future<String> findOrCreateChat({
  required String myUid,
  required String myName,
  required String myPhoto,
  required SearchUserModel otherUser,
}) async {
  final firestore = FirebaseFirestore.instance;
  final chats = firestore.collection('chats');

  final existing = await chats
      .where('participants', arrayContains: myUid)
      .get();

  for (final doc in existing.docs) {
    final participants = List<String>.from(doc['participants'] as List);
    if (participants.contains(otherUser.uid) && participants.length == 2) {
      return doc.id;
    }
  }

  final newChat = await chats.add({
    'participants': [myUid, otherUser.uid],
    'participantNames': {myUid: myName, otherUser.uid: otherUser.displayName},
    'participantPhotos': {myUid: myPhoto, otherUser.uid: otherUser.photoUrl},
    'lastMessage': '',
    'lastMessageAt': FieldValue.serverTimestamp(),
    'lastSenderId': '',
  });
  return newChat.id;
}
