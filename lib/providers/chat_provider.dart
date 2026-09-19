import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_request_context.dart';
import '../models/note_file.dart';
import '../services/ai_service.dart';
import '../utils/note_frontmatter.dart';
import '../models/course_metadata.dart';

class ChatProvider extends ChangeNotifier {
  final AiService _aiService = AiService();

  bool _isOpen = false;
  bool _isLoading = false;
  final List<ChatMessage> _messages = [];

  /// Toggle "Chỉ hỏi trong môn này" — mặc định OFF (không ảnh hưởng luồng cũ).
  bool _scopeToCurrentSubject = false;

  /// Note đang mở (set từ UI) để build context khi toggle bật.
  NoteFile? _currentNote;

  bool get isOpen => _isOpen;
  bool get isLoading => _isLoading;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get scopeToCurrentSubject => _scopeToCurrentSubject;
  NoteFile? get currentNote => _currentNote;

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

  void setScopeToCurrentSubject(bool value) {
    if (_scopeToCurrentSubject == value) return;
    _scopeToCurrentSubject = value;
    notifyListeners();
  }

  void setCurrentNote(NoteFile? note) {
    if (_currentNote?.path == note?.path) return;
    _currentNote = note;
    // Chỉ notify khi toggle đang bật (chip context cần cập nhật)
    if (_scopeToCurrentSubject) {
      notifyListeners();
    }
  }

  String? resolveCurrentSubjectId() {
    final note = _currentNote;
    if (note == null) return null;
    final meta = CourseMetadata.fromNote(note);
    return resolveSubjectId(
      rawContent: note.rawContent,
      fileName: note.fileName,
      bodyCode: meta.code,
    );
  }

  String? resolveCurrentSourceFile() {
    final note = _currentNote;
    if (note == null) return null;
    // KB relative path convention: "Kỳ N/CODE.md" hoặc folder/file
    if (note.folderName.isNotEmpty &&
        note.folderName != 'Tổng quan' &&
        note.folderName != 'Gốc') {
      return '${note.folderName}/${note.fileName}';
    }
    return note.fileName;
  }

  ChatRequestContext? _buildContextFromState(String question) {
    final tagged = parseAtTags(question);
    final parts = <ChatRequestContext>[];

    if (tagged.isNotEmpty) {
      parts.add(
        ChatRequestContext(
          sourceIds: tagged,
          mode: 'subject_focus',
        ),
      );
    }

    if (_scopeToCurrentSubject) {
      final id = resolveCurrentSubjectId();
      if (id != null) {
        parts.add(
          ChatRequestContext(
            sourceIds: [id],
            sourceFile: resolveCurrentSourceFile(),
            mode: 'subject_focus',
          ),
        );
      }
    }

    if (parts.isEmpty) return null;
    ChatRequestContext merged = parts.first;
    for (var i = 1; i < parts.length; i++) {
      merged = merged.merge(parts[i]);
    }
    return merged;
  }

  /// Gửi câu hỏi tới Backend AI.
  /// [override] dùng cho quick action / study plan; vẫn giữ signature gửi string đơn giản.
  Future<void> sendMessage(
    String question, {
    ChatRequestContext? override,
  }) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty) return;

    // 1. Thêm tin nhắn của User
    _messages.add(ChatMessage.user(cleanQuestion));
    _isLoading = true;
    notifyListeners();

    final autoCtx = _buildContextFromState(cleanQuestion);
    final ctx = override != null
        ? (autoCtx?.merge(override) ?? override)
        : autoCtx;

    // 2. Gửi tới AI Service (POST http://127.0.0.1:8000/chat)
    final aiResponse = await _aiService.ask(cleanQuestion, context: ctx);

    // 3. Thêm phản hồi của AI
    _messages.add(aiResponse);
    _isLoading = false;
    notifyListeners();
  }

  /// Quick action từ Markdown selection.
  Future<void> sendQuickAction({
    required String action,
    required String excerpt,
    String? sourceId,
    String? sourceFile,
  }) async {
    final labels = {
      'explain': 'Giải thích đoạn đã chọn',
      'translate_vi': 'Dịch đoạn đã chọn sang tiếng Việt',
      'summarize': 'Tóm tắt đoạn đã chọn',
    };
    final display = labels[action] ?? 'Phân tích đoạn đã chọn';
    final preview = excerpt.length > 80
        ? '${excerpt.substring(0, 80)}…'
        : excerpt;

    openChat();
    await sendMessage(
      '$display:\n"$preview"',
      override: ChatRequestContext(
        mode: 'quick_action',
        action: action,
        excerpt: excerpt,
        sourceIds: sourceId != null ? [sourceId] : const [],
        sourceFile: sourceFile,
      ),
    );
  }

  /// Study planner chip.
  Future<void> sendStudyPlan({
    required int currentSemester,
    required String goal,
    String? comboTrack,
  }) async {
    openChat();
    final trackNote =
        comboTrack != null ? ' (combo: $comboTrack)' : '';
    await sendMessage(
      'Lập lộ trình học tập từ Kỳ $currentSemester đến Kỳ 9, mục tiêu: $goal$trackNote',
      override: ChatRequestContext(
        mode: 'study_plan',
        currentSemester: currentSemester,
        goal: goal,
        comboTrack: comboTrack,
      ),
    );
  }

  /// Xóa lịch sử trò chuyện
  void clearHistory() {
    _messages.clear();
    _initGreeting();
    notifyListeners();
  }
}
