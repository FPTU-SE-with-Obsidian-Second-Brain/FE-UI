import 'study_plan.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> sources;
  final DateTime timestamp;
  final bool isError;
  final StudyPlan? studyPlan;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.sources = const [],
    DateTime? timestamp,
    this.isError = false,
    this.studyPlan,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.user(String text) {
    return ChatMessage(text: text, isUser: true);
  }

  factory ChatMessage.ai(
    String text, {
    List<String> sources = const [],
    StudyPlan? studyPlan,
  }) {
    return ChatMessage(
      text: text,
      isUser: false,
      sources: sources,
      studyPlan: studyPlan,
    );
  }

  factory ChatMessage.error(String text) {
    return ChatMessage(text: text, isUser: false, isError: true);
  }
}
