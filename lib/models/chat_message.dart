class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> sources;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.sources = const [],
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.user(String text) {
    return ChatMessage(text: text, isUser: true);
  }

  factory ChatMessage.ai(String text, {List<String> sources = const []}) {
    return ChatMessage(text: text, isUser: false, sources: sources);
  }

  factory ChatMessage.error(String text) {
    return ChatMessage(text: text, isUser: false, isError: true);
  }
}
