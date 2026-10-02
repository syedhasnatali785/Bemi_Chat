import 'dart:convert';

import 'package:bemichat/config/app_config.dart';
import 'package:bemichat/models/ai_chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  AiChatService({String? workerBaseUrl})
    : workerBaseUrl = AppConfig.normalizeWorkerBaseUrl(
        workerBaseUrl ?? AppConfig.defaultWorkerBaseUrl,
      );

  final String workerBaseUrl;

  Future<String> sendMessage(List<AiMessage> history) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to use AI chat');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Missing Firebase auth token');
    }

    final response = await http
        .post(
          Uri.parse('$workerBaseUrl/ai-chat'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'messages': history.map((m) => m.toApiMap()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final bodyText = response.body.trim();
      throw Exception(
        'AI request failed (${response.statusCode}): ${bodyText.isNotEmpty ? bodyText : 'empty response'}',
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = data['reply'] as String?;
      if (reply == null || reply.trim().isEmpty) {
        throw Exception('AI worker returned an empty reply');
      }
      return reply;
    } catch (_) {
      throw Exception('AI worker returned an invalid response: ${response.body}');
    }
  }
}
