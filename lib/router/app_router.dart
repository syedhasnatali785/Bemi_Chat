import 'package:bemichat/screens/ai_chat_screen.dart';
import 'package:bemichat/screens/auth/login.dart';
import 'package:bemichat/screens/auth/signup.dart';
import 'package:bemichat/screens/home/calls/voice_call_screen.dart';
import 'package:bemichat/screens/home/chat_screen.dart';
import 'package:bemichat/screens/home/home_shell.dart';
import 'package:bemichat/screens/home/search_user_screen.dart';
import 'package:bemichat/screens/onboarding/profile_setup_screen.dart';
import 'package:bemichat/screens/splash/splash_screen.dart';
import 'package:bemichat/services/call_services/call_service.dart';
import 'package:bemichat/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppPaths {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const inbox = '/inbox';
  static const profileSetup = '/profile-setup';
  static const searchUsers = '/search-users';
  static const aiChat = '/ai-chat';
  static const chat = '/chat/:chatId';
  static const voiceCall = '/call/voice';
}

final appRouter = GoRouter(
  navigatorKey: NotificationService.instance.navigatorKey,
  initialLocation: AppPaths.splash,
  routes: [
    GoRoute(
      path: AppPaths.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppPaths.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppPaths.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppPaths.profileSetup,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppPaths.inbox,
      builder: (context, state) => const HomeShell(initialIndex: 0),
    ),
    GoRoute(
      path: AppPaths.searchUsers,
      builder: (context, state) => const SearchUserScreen(),
    ),
    GoRoute(
      path: AppPaths.aiChat,
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: AppPaths.chat,
      builder: (context, state) {
        final chatId = state.pathParameters['chatId'] ?? '';
        final title = state.uri.queryParameters['title'] ?? 'Chat';
        final otherUserId = state.uri.queryParameters['otherUserId'] ?? '';

        return ChatScreen(
          chatId: chatId,
          otherUserId: otherUserId,
          title: title,
        );
      },
    ),
    GoRoute(
      path: AppPaths.voiceCall,
      builder: (context, state) {
        final peerName = state.uri.queryParameters['peerName'] ?? 'Call';
        return CallScreen(callService: CallService.active, peerName: peerName);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  ),
);
