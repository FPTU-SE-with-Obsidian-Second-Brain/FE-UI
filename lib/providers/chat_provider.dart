import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final AiService _aiService = AiService();

  bool _isOpen = false;
  bool _isLoading = false;
  final List<ChatMessage> _messages = [];

  bool get isOpen => _isOpen;
  bool get isLoading => _isLoading;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ChatProvider() {
    _initGreeting();
  }

  void _initGreeting() {
    _messages.add(
      ChatMessage.ai(
        'Xin chào! Tôi là Trợ lý AI ngành SE FPTU (RAG Assistant).\n\n'
        'Bạn có thể hỏi tôi bất kỳ điều gì về khung chương trình, đề cương, môn tiên quyết hoặc nội dung bài học!',
      ),
    );
  }

  /// Bật/Tắt khung chat
  void toggleChat() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void openChat() {
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  void closeChat() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  /// Gửi câu hỏi tới Backend AI
  Future<void> sendMessage(String question) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty) return;

    // 1. Thêm tin nhắn của User
    _messages.add(ChatMessage.user(cleanQuestion));
    _isLoading = true;
    notifyListeners();

    // 2. Gửi tới AI Service (POST http://127.0.0.1:8000/chat)
    final aiResponse = await _aiService.ask(cleanQuestion);

    // 3. Thêm phản hồi của AI
    _messages.add(aiResponse);
    _isLoading = false;
    notifyListeners();
  }

  /// Xóa lịch sử trò chuyện
  void clearHistory() {
    _messages.clear();
    _initGreeting();
    notifyListeners();
  }
}
