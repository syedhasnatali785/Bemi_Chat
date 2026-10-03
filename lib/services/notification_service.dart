import 'dart:async';
import 'dart:convert';

import 'package:bemichat/screens/home/calls/voice_call_screen.dart';
import 'package:bemichat/screens/home/chat_screen.dart';
import 'package:bemichat/services/call_services/call_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final navigatorKey = GlobalKey<NavigatorState>();
  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _initialized = false;

  FirebaseMessaging get messaging {
    final msg = _messaging ??= FirebaseMessaging.instance;
    return msg;
  }

  FlutterLocalNotificationsPlugin get localNotifications =>
      _localNotifications ??= FlutterLocalNotificationsPlugin();

  static bool isCallPayload(Map<String, dynamic> data) {
    return data['type'] == 'call';
  }

  static bool isCallStatusPayload(Map<String, dynamic> data) {
    return data['type'] == 'call_status';
  }

  static Map<String, dynamic>? extractCallPayload(Map<String, dynamic> data) {
    if (!isCallPayload(data)) return null;

    final callId = data['callId'] as String?;
    final callerId = data['callerId'] as String?;
    final callerName = data['callerName'] as String?;
    if (callId == null || callerId == null || callerName == null) {
      return null;
    }

    return {
      'type': 'call',
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
    };
  }

  static Map<String, dynamic>? extractCallStatusPayload(
    Map<String, dynamic> data,
  ) {
    if (!isCallStatusPayload(data)) return null;

    final callId = data['callId'] as String?;
    final status = data['status'] as String?;
    final callerId = data['callerId'] as String?;
    final calleeName = data['calleeName'] as String?;
    if (callId == null || status == null || callerId == null) {
      return null;
    }

    return {
      'type': 'call_status',
      'callId': callId,
      'status': status,
      'callerId': callerId,
      'calleeName': calleeName ?? 'Caller',
    };
  }

  static const _channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat messages',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _requestPermission();
      await _setupLocalNotifications();
      await registerCallKitListeners();

      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          unawaited(_syncToken());
        }
      });

      if (FirebaseAuth.instance.currentUser != null) {
        await _syncToken();
      }

      messaging.onTokenRefresh.listen(_saveToken);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessageTap(initialMessage);
        });
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'notification_service',
          context: ErrorSummary('Notification initialization failed'),
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('📱 Notification permission requested');
    debugPrint('📱 Authorization status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️  CRITICAL: User DENIED notification permission!');
      debugPrint('⚠️  → No notifications will be shown on this device');
      debugPrint('⚠️  → User must enable in Settings → Notifications');
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission GRANTED');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️  Notification permission PROVISIONAL (iOS only)');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _navigateFromData(Map<String, dynamic>.from(jsonDecode(payload)));
      },
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> registerCallKitListeners() async {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;

      final eventName = event.eventName;

      String? callId;
      Map<String, dynamic> extra = const {};

      if (event is CallEventActionCallAccept) {
        callId = event.callKitParams.id;
        extra = Map<String, dynamic>.from(
          event.callKitParams.extra ?? const {},
        );
      } else if (event is CallEventActionCallDecline) {
        callId = event.callKitParams.id;
        extra = Map<String, dynamic>.from(
          event.callKitParams.extra ?? const {},
        );
      } else if (event is CallEventActionCallEnded) {
        callId = event.callKitParams.id;
        extra = Map<String, dynamic>.from(
          event.callKitParams.extra ?? const {},
        );
      } else if (event is CallEventActionCallTimeout) {
        callId = event.id;
      } else if (event is CallEventActionCallConnected) {
        callId = event.id;
      } else if (event is CallEventActionCallStart) {
        callId = event.callKitParams.id;
      } else if (event is CallEventActionCallIncoming) {
        callId = event.callKitParams.id;
        extra = Map<String, dynamic>.from(
          event.callKitParams.extra ?? const {},
        );
      }

      if (callId == null) return;

      final callService = CallService.active;

      if (eventName == CallEventConstants.actionCallAccept) {
        try {
          await callService.answerCall(callId);
        } catch (_) {
          return;
        }
        final callerName = extra['callerName'] as String? ?? 'Unknown';
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) =>
                CallScreen(callService: callService, peerName: callerName),
          ),
        );
        return;
      }

      if (eventName == CallEventConstants.actionCallDecline ||
          eventName == CallEventConstants.actionCallTimeout) {
        await callService.declineCall(callId);
        return;
      }

      if (eventName == CallEventConstants.actionCallEnded) {
        await callService.hangUp();
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 MESSAGE RECEIVED (foreground): ${message.messageId}');
    debugPrint('📬 Notification block present: ${message.notification != null}');
    debugPrint('📬 Data: ${message.data}');

    final callStatus = extractCallStatusPayload(message.data);
    if (callStatus != null) {
      debugPrint('📬 → Call status update: callId=${callStatus['callId']}, status=${callStatus['status']}');
      final service = CallService.active;
      await service.applyRemoteCallStatus(
        callId: callStatus['callId'] as String,
        status: callStatus['status'] as String,
      );
      return;
    }

    final payload = extractCallPayload(message.data);
    if (payload != null) {
      debugPrint('📬 → Call notification: callId=${payload['callId']}');
      await CallService.showIncomingCallkit(
        callId: payload['callId'] as String,
        callerId: payload['callerId'] as String,
        callerName: payload['callerName'] as String,
      );
      return;
    }

    debugPrint('📬 → Chat notification from ${message.data['otherUserId']}');
    await _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      debugPrint('📬 SKIP: No notification block in message');
      return;
    }

    debugPrint('📬 SHOW: Title="${notification.title}" Body="${notification.body}"');
    
    try {
      await localNotifications.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
      debugPrint('📬 ✅ Local notification displayed successfully');
    } catch (e) {
      debugPrint('📬 ❌ ERROR showing local notification: $e');
    }
  }

  void _handleMessageTap(RemoteMessage message) =>
      _navigateFromData(message.data);

  void _navigateFromData(Map<String, dynamic> data) {
    final callStatus = extractCallStatusPayload(data);
    if (callStatus != null) {
      final service = CallService.active;
      unawaited(
        service.applyRemoteCallStatus(
          callId: callStatus['callId'] as String,
          status: callStatus['status'] as String,
        ),
      );
      return;
    }

    final payload = extractCallPayload(data);
    if (payload != null) {
      CallService.showIncomingCallkit(
        callId: payload['callId'] as String,
        callerId: payload['callerId'] as String,
        callerName: payload['callerName'] as String,
      );
      return;
    }

    final chatId = data['chatId'] as String?;
    final otherUserId = data['otherUserId'] as String?;
    if (chatId == null || otherUserId == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          title: data['chatTitle'] as String? ?? 'Chat',
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  Future<void> _syncToken() async {
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('🔐 FCM TOKEN: Got token from Firebase Messaging: ${token.substring(0, 20)}...');
      await _saveToken(token);
    } else {
      debugPrint('🔐 FCM TOKEN: ⚠️ Firebase Messaging returned null token');
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('🔐 FCM TOKEN: ⚠️ No current user — skipping token save');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      debugPrint('🔐 FCM TOKEN: ✓ Saved token for user $uid to Firestore');
    } catch (e) {
      debugPrint('🔐 FCM TOKEN: ❌ Failed to save token: $e');
    }
  }

  Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }
    await messaging.deleteToken();
  }
}
