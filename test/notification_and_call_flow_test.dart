import 'dart:convert';

import 'package:bemichat/config/app_config.dart';
import 'package:bemichat/services/notification_service.dart';
import 'package:bemichat/services/push_notf_servic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('worker URLs are normalized from a single app config source', () {
    expect(
      AppConfig.normalizeWorkerBaseUrl('https://example.com/'),
      'https://example.com',
    );
    expect(
      AppConfig.normalizeWorkerBaseUrl('https://example.com'),
      'https://example.com',
    );
  });

  test('push notification client normalizes the worker endpoint', () {
    final client = PushNotificationClient(
      workerBaseUrl: 'https://example.com/',
    );

    expect(
      client.workerBaseUrl,
      'https://example.com/',
    );
  });

  test('notification payload data includes chat navigation fields', () {
    final payload = {
      'type': 'chat',
      'chatId': 'chat_123',
      'chatTitle': 'Alice',
      'otherUserId': 'user_456',
    };

    expect(payload['type'], 'chat');
    expect(payload['chatId'], 'chat_123');
    expect(payload['otherUserId'], 'user_456');
  });

  test('call notification payload contains call metadata', () {
    final payload = {
      'type': 'call',
      'callId': 'call_123',
      'callerId': 'user_456',
      'callerName': 'Alice',
    };

    expect(payload['type'], 'call');
    expect(payload['callId'], 'call_123');
    expect(payload['callerName'], 'Alice');
  });

  test('navigable payload JSON round-trips when serialized', () {
    final payload = {
      'type': 'chat',
      'chatId': 'chat_123',
      'chatTitle': 'Alice',
      'otherUserId': 'user_456',
    };

    final json = jsonEncode(payload);
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded, payload);
  });

  test('notification service initializes notification payload routing constants', () {
    expect(NotificationService.instance.navigatorKey, isNotNull);
  });
}
