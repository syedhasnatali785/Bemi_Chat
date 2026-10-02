import 'dart:convert';

import 'package:bemichat/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Triggers an FCM push by calling the Cloudflare Worker's
/// /send-notification endpoint — this is the client-side replacement for
/// the two Firestore-triggered Cloud Functions (onNewChatMessage, onNewCall).
///
/// The Worker looks the recipient's FCM token up itself (via a service
/// account), so this only ever needs to say *who* to notify, not their
/// raw device token.
class PushNotificationClient {
  PushNotificationClient({required this.workerBaseUrl});

  /// e.g. https://turn-credentials.your-subdomain.workers.dev
  /// (same Worker as TurnCredentialsService — different path)
  final String workerBaseUrl;

  Future<void> sendNotification({
    required String recipientUid,
    Map<String, String>? notification,
    required Map<String, String> data,
  }) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        // ignore: avoid_print
        print('🔔 PUSH: Not signed in — cannot send notification');
        return; // not signed in — nothing to authenticate with
      }

      final normalizedBaseUrl = AppConfig.normalizeWorkerBaseUrl(workerBaseUrl);
      final endpoint = '$normalizedBaseUrl/send-notification';

      // ignore: avoid_print
      print('🔔 PUSH: Sending to Worker → recipient: $recipientUid, '
          'has_notification: ${notification != null}, '
          'endpoint: $endpoint');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recipientUid': recipientUid,
          'notification': notification,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        // ignore: avoid_print
        print('🔔 PUSH: ✓ Worker accepted (${response.body})');
      } else {
        // A failed push shouldn't fail the message/call it's attached to —
        // just log it. The message/call itself was already saved.
        // ignore: avoid_print
        print('🔔 PUSH: ✗ Failed with ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Same reasoning — swallow network errors here.
      // ignore: avoid_print
      print('🔔 PUSH: Network error: $e');
    }
  }
}
