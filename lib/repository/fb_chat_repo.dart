import 'dart:async';

import 'package:bemichat/config/app_config.dart';
import 'package:bemichat/models/chat_model.dart';
import 'package:bemichat/services/push_notf_servic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository wrapping Firestore access for a single chat's messages.
class ChatRepository {
  ChatRepository({
    FirebaseFirestore? firestore,
    PushNotificationClient? pushClient,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _pushClient =
           pushClient ??
           PushNotificationClient(
             workerBaseUrl: AppConfig.workerBaseUrl,
           );

  final FirebaseFirestore _firestore;
  final PushNotificationClient _pushClient;

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _firestore.collection('chats').doc(chatId).collection('messages');

  /// Live stream of messages for [chatId], oldest first.
  Stream<List<ChatMessage>> messages(String chatId) {
    return _messagesRef(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    
    // ignore: avoid_print
    print('💾 DATABASE: Adding message to chat $chatId');
    await _messagesRef(chatId).add(message.toMap());

    // Update the parent chat doc with lastMessage so recipient sees it in inbox
    // ignore: avoid_print
    print('💾 DATABASE: Updating chat $chatId with lastMessage...');
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    });
    // ignore: avoid_print
    print('💾 DATABASE: ✓ Chat updated with lastMessage');

    // Fire-and-forget — a failed push should never block message sending.
    unawaited(_notifyRecipient(chatId: chatId, senderId: senderId, text: text));
  }

  Future<void> _notifyRecipient({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final data = chatDoc.data();
      if (data == null) {
        // ignore: avoid_print
        print('📨 NOTIFICATION: Chat doc not found: $chatId');
        return;
      }

      final participants = List<String>.from(
        data['participants'] as List? ?? [],
      );
      final recipientId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );
      if (recipientId.isEmpty) {
        // ignore: avoid_print
        print('📨 NOTIFICATION: No recipient found in chat: $chatId');
        return;
      }

      final names = Map<String, String>.from(
        data['participantNames'] as Map? ?? {},
      );
      final senderName = names[senderId] ?? 'New message';

      // ignore: avoid_print
      print('📨 NOTIFICATION: Sending push to $recipientId from $senderName');
      
      await _pushClient.sendNotification(
        recipientUid: recipientId,
        notification: {'title': senderName, 'body': text},
        data: {
          'type': 'chat',
          'chatId': chatId,
          'chatTitle': senderName,
          'otherUserId': senderId,
        },
      );
      
      // ignore: avoid_print
      print('📨 NOTIFICATION: Push sent successfully to $recipientId');
    } catch (e) {
      // Notification failures are non-fatal — the message already sent.
      // ignore: avoid_print
      print('❌ NOTIFICATION ERROR: Failed to send push: $e');
    }
  }
}
