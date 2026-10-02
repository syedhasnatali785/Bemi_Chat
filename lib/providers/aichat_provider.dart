import 'package:bemichat/config/app_config.dart';
import 'package:bemichat/models/ai_chat_model.dart';
import 'package:bemichat/services/aichat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

class AiChatProviderState {
  const AiChatProviderState({
    this.messages = const [],
    this.loading = false,
    this.error,
  });

  final List<AiMessage> messages;
  final bool loading;
  final String? error;

  AiChatProviderState copyWith({
    List<AiMessage>? messages,
    bool? loading,
    String? error,
  }) {
    return AiChatProviderState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      error: error, // pass null explicitly to clear a previous error
    );
  }
}

class AiChatController extends StateNotifier<AiChatProviderState> {
  AiChatController(this._service) : super(const AiChatProviderState());

  final AiChatService _service;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.loading) return;

    final userMessage = AiMessage(role: AiMessageRole.user, content: trimmed);
    final withUserMessage = [...state.messages, userMessage];
    state = state.copyWith(
      messages: withUserMessage,
      loading: true,
      error: null,
    );

    try {
      final reply = await _service.sendMessage(withUserMessage);
      state = state.copyWith(
        messages: [
          ...withUserMessage,
          AiMessage(role: AiMessageRole.assistant, content: reply),
        ],
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  void reset() => state = const AiChatProviderState();
}

final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService(workerBaseUrl: AppConfig.workerBaseUrl);
});

/// autoDispose: a fresh conversation each time the AI chat screen opens.
/// Drop autoDispose if you'd rather the conversation persist while
/// navigating away and back.
final aiChatControllerProvider =
    StateNotifierProvider.autoDispose<AiChatController, AiChatProviderState>((
      ref,
    ) {
      return AiChatController(ref.watch(aiChatServiceProvider));
    });

/// Suggested starter prompts shown when the conversation is empty.
final aiIcebreakersProvider = Provider<List<String>>((ref) {
  return const [
    "What can you help me with?",
    "Give me 3 ideas to get started",
    "Summarize something for me",
    "Help me write a message",
  ];
});
