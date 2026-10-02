enum AiMessageRole { user, assistant }

class AiMessage {
  AiMessage({required this.role, required this.content, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  final AiMessageRole role;
  final String content;
  final DateTime createdAt;

  /// Shape the Worker's /ai-chat endpoint expects for each history entry.
  Map<String, String> toApiMap() => {
    'role': role == AiMessageRole.user ? 'user' : 'assistant',
    'content': content,
  };
}
