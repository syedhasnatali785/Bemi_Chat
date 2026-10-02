import 'package:cloud_firestore/cloud_firestore.dart';

/// Summary of a chat document, as shown in the chat list.
///
/// Expects a Firestore doc at `chats/{chatId}` shaped like:
/// {
///   participants: [uid1, uid2],
///   participantNames: { uid1: "Alice", uid2: "Bob" },
///   participantPhotos: { uid1: "https://...", uid2: "" },
///   lastMessage: "hey!",
///   lastMessageAt: Timestamp,
///   lastSenderId: uid1,
/// }
class InboxModel {
  const InboxModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
  });

  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;

  factory InboxModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['lastMessageAt'] as Timestamp?;
    return InboxModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] as Map? ?? {},
      ),
      participantPhotos: Map<String, String>.from(
        data['participantPhotos'] as Map? ?? {},
      ),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: timestamp?.toDate(),
      lastSenderId: data['lastSenderId'] as String? ?? '',
    );
  }

  /// The other participant's id in a 1-to-1 chat (empty if not found).
  String otherUserId(String myId) =>
      participants.firstWhere((id) => id != myId, orElse: () => '');

  String otherUserName(String myId) =>
      participantNames[otherUserId(myId)] ?? 'Unknown';

  String otherUserPhoto(String myId) =>
      participantPhotos[otherUserId(myId)] ?? '';
}
