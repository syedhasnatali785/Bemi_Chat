import 'package:bemichat/models/inbox_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InboxRepository {
  InboxRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Live stream of chats the given user is a participant in,
  /// most recently active first. Excludes chats with no messages (empty chats).
  Stream<List<InboxModel>> chatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) {
          // Filter out empty chats (no messages sent yet)
          final chats = snap.docs
              .where((doc) => (doc['lastMessage'] as String? ?? '').isNotEmpty)
              .map(InboxModel.fromDoc)
              .toList();
          return chats;
        });
  }
}
