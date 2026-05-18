enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;
  final bool isReminder;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
    this.isReminder = false,
  });

  bool get isUser => role == MessageRole.user;

  ChatMessage copyWith({bool? isLoading, String? content}) => ChatMessage(
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
        isReminder: isReminder,
      );
}
