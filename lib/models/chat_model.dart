import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'] as Timestamp?;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      // Falls back to "now" for a message whose server timestamp hasn't
      // been written yet (Firestore returns null for pending writes).
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
