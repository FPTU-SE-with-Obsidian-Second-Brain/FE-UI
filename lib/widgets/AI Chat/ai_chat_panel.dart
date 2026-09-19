import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/note_provider.dart';
import 'ai_chat_input_bar.dart';
import 'ai_chat_message_bubble.dart';
import 'study_plan_dialog.dart';

/// Khung điều khiển trò chuyện Trợ lý AI (FPTU RAG Chatbot)
class AiChatPanel extends StatefulWidget {
  const AiChatPanel({super.key});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Kích thước chiều rộng có thể co giãn
  double _chatWidth = 420.0;
  bool _isDragging = false;
  bool _isHoveringResizeHandle = false;

  static const List<String> _defaultSuggestions = [
    'Môn CSD201 học những gì?',
    'Điều kiện tiên quyết của môn SWP391?',
    'Môn PRF192 có bao nhiêu buổi học?',
  ];

  static const List<String> _scopedSuggestions = [
    'Tóm tắt môn này',
    '10 flashcard ôn tập',
    'Môn tiên quyết là gì?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(ChatProvider provider, String text) {
    if (text.trim().isEmpty || provider.isLoading) return;

    _controller.clear();
    provider.sendMessage(text);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Future<void> _openStudyPlanDialog(ChatProvider chatProvider) async {
    final result = await showStudyPlanDialog(context);
    if (result == null || !mounted) return;
    await chatProvider.sendStudyPlan(
      currentSemester: result.semester,
      goal: result.goal,
      comboTrack: result.comboTrack,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAllowedWidth = (screenWidth * 0.85).clamp(450.0, 1100.0);

    return Consumer2<ChatProvider, NoteProvider>(
      builder: (context, chatProvider, noteProvider, _) {
        // Đồng bộ note đang mở sau frame (tránh side-effect trong build)
        final selected = noteProvider.selectedNote;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          chatProvider.setCurrentNote(selected);
        });

        _scrollToBottom();

        final subjectId = chatProvider.resolveCurrentSubjectId();
        final hasNote = noteProvider.selectedNote != null;
        final suggestions = chatProvider.scopeToCurrentSubject
            ? _scopedSuggestions
            : _defaultSuggestions;

        return Container(
          width: _chatWidth.clamp(320.0, maxAllowedWidth),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              left: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              // 1. Thanh kéo co giãn kích thước khung chat (Draggable Resize Handle)
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => setState(() => _isHoveringResizeHandle = true),
                onExit: (_) => setState(() => _isHoveringResizeHandle = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) =>
                      setState(() => _isDragging = true),
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _chatWidth = (_chatWidth - details.delta.dx).clamp(
                        320.0,
                        maxAllowedWidth,
                      );
                    });
                  },
                  onHorizontalDragEnd: (_) =>
                      setState(() => _isDragging = false),
                  onDoubleTap: () {
                    setState(() {
                      _chatWidth = _chatWidth > 550 ? 420.0 : 680.0;
                    });
                  },
                  child: Container(
                    width: 7,
                    color: (_isDragging || _isHoveringResizeHandle)
                        ? colorScheme.primary.withAlpha(50)
                        : Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 2.5,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (_isDragging || _isHoveringResizeHandle)
                              ? colorScheme.primary
                              : theme.dividerColor.withAlpha(160),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Nội dung chính của khung chat
              Expanded(
                child: Column(
                  children: [
                    // Header khung Chat
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          50,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trợ lý AI (FPTU RAG)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Backend: http://127.0.0.1:8000',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: _chatWidth > 550
                                ? 'Thu nhỏ chiều rộng (420px)'
                                : 'Mở rộng chiều rộng (680px)',
                            icon: Icon(
                              _chatWidth > 550
                                  ? Icons.close_fullscreen_rounded
                                  : Icons.open_in_full_rounded,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _chatWidth = _chatWidth > 550 ? 420.0 : 680.0;
                              });
                            },
                          ),
                          IconButton(
                            tooltip: 'Xóa lịch sử chat',
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: chatProvider.messages.length > 1
                                ? () => chatProvider.clearHistory()
                                : null,
                          ),
                          IconButton(
                            tooltip: 'Đóng khung chat',
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => chatProvider.closeChat(),
                          ),
                        ],
                      ),
                    ),

                    // Danh sách tin nhắn
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            chatProvider.messages.length +
                            (chatProvider.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatProvider.messages.length) {
                            return const AiChatLoadingBubble();
                          }
                          final message = chatProvider.messages[index];
                          return AiChatMessageBubble(message: message);
                        },
                      ),
                    ),

                    // Thanh nhập + toggle scope + @ autocomplete
                    AiChatInputBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      isLoading: chatProvider.isLoading,
                      onSend: (text) => _handleSend(chatProvider, text),
                      suggestions: suggestions,
                      showSuggestions: chatProvider.messages.length <= 2 ||
                          chatProvider.scopeToCurrentSubject,
                      notes: noteProvider.notes,
                      onStudyPlanTap: () =>
                          _openStudyPlanDialog(chatProvider),
                      leadingChips: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilterChip(
                              selected: chatProvider.scopeToCurrentSubject,
                              label: Text(
                                hasNote && subjectId != null
                                    ? 'Chỉ hỏi trong môn này ($subjectId)'
                                    : 'Chỉ hỏi trong môn này',
                                style: const TextStyle(fontSize: 11.5),
                              ),
                              avatar: Icon(
                                Icons.filter_alt_outlined,
                                size: 16,
                                color: chatProvider.scopeToCurrentSubject
                                    ? colorScheme.primary
                                    : theme.hintColor,
                              ),
                              onSelected: hasNote
                                  ? (v) =>
                                      chatProvider.setScopeToCurrentSubject(v)
                                  : null,
                            ),
                            if (chatProvider.scopeToCurrentSubject &&
                                hasNote &&
                                subjectId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      '$subjectId · ${noteProvider.selectedNote!.folderName}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    avatar: const Icon(
                                      Icons.description_outlined,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
