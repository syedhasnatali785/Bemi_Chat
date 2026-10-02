import 'dart:convert';

import 'package:bemichat/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class IceServerConfig {
  const IceServerConfig({required this.urls, this.username, this.credential});

  final String urls;
  final String? username;
  final String? credential;

  Map<String, dynamic> toMap() => {
    'urls': urls,
    if (username != null) 'username': username,
    if (credential != null) 'credential': credential,
  };
}

/// Fetches short-lived TURN credentials from your Cloudflare Worker,
/// which itself calls Metered's API using a server-side secret.
class TurnCredentialsService {
  TurnCredentialsService({required this.workerUrl})
    : _turnCredentialsUrl = _buildUrl(workerUrl);

  /// e.g. https://turn-credentials.your-subdomain.workers.dev
  final String workerUrl;
  final Uri _turnCredentialsUrl;

  static Uri _buildUrl(String rawUrl) {
    final normalized = AppConfig.normalizeWorkerBaseUrl(rawUrl);
    return Uri.parse('$normalized/turn-credentials');
  }

  Uri get turnCredentialsUrl => _turnCredentialsUrl;

  Future<List<IceServerConfig>> fetchIceServers() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw StateError('Must be signed in to fetch TURN credentials');
    }

    final response = await http.get(
      _turnCredentialsUrl,
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch TURN credentials (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['iceServers'] as List<dynamic>;

    return list.map((entry) {
      final map = entry as Map<String, dynamic>;
      return IceServerConfig(
        urls: map['urls'] as String,
        username: map['username'] as String?,
        credential: map['credential'] as String?,
      );
    }).toList();
  }
}
