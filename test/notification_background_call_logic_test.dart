import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bemichat/services/notification_service.dart';

void main() {
  test('detects call payloads from remote data messages', () {
    final message = RemoteMessage(
      data: {
        'type': 'call',
        'callId': 'call_123',
        'callerId': 'user_456',
        'callerName': 'Alice',
      },
    );

    expect(NotificationService.isCallPayload(message.data), isTrue);
    expect(NotificationService.extractCallPayload(message.data), {
      'type': 'call',
      'callId': 'call_123',
      'callerId': 'user_456',
      'callerName': 'Alice',
    });
  });

  test('ignores non-call payloads for the call UI route', () {
    final payload = {
      'type': 'chat',
      'chatId': 'chat_123',
      'chatTitle': 'Alice',
      'otherUserId': 'user_456',
    };

    expect(NotificationService.isCallPayload(payload), isFalse);
    expect(NotificationService.extractCallPayload(payload), isNull);
  });
}
