import 'dart:async';

import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:bemichat/firebase_options.dart';
import 'package:bemichat/router/app_router.dart';
import 'package:bemichat/services/call_services/call_service.dart';
import 'package:bemichat/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📲 BACKGROUND MESSAGE: ${message.messageId}');
  debugPrint('📲 Data: ${message.data}');
  
  final payload = NotificationService.extractCallPayload(message.data);
  if (payload != null) {
    debugPrint('📲 → Call notification, showing CallKit');
    await CallService.showIncomingCallkit(
      callId: payload['callId'] as String,
      callerId: payload['callerId'] as String,
      callerName: payload['callerName'] as String,
    );
    return;
  }
  
  // Chat messages: FCM handles notification display automatically
  // App-specific handling happens when user taps the notification
  debugPrint('📲 → Chat message, FCM will display notification');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(ProviderScope(child: MyApp()));

  // Do not block app startup on native permission + token sync. Start it once
  // the first frame has been produced, and fail gracefully if the plugin hangs.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      NotificationService.instance.initialize().catchError((error) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            library: 'notification_service',
            context: ErrorSummary('FCM initialization failed during startup'),
          ),
        );
      }),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'BemiChat',
      theme: NeomorphismTheme.lightTheme,
    );
  }
}
