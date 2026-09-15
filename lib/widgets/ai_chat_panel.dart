import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/note_provider.dart';

class AiChatPanel extends StatefulWidget {
  const AiChatPanel({super.key});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Kích thước chiều rộng của khung chat có thể điều chỉnh
  double _chatWidth = 420.0;
  bool _isDragging = false;
  bool _isHoveringResizeHandle = false;

  final List<String> _suggestions = [
    'Môn CSD201 học những gì?',
    'Điều kiện tiên quyết của môn SWP391?',
    'Môn PRF192 có bao nhiêu buổi học?',
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

  void _handleSend(ChatProvider provider, [String? customText]) {
    final text = customText ?? _controller.text;
    if (text.trim().isEmpty || provider.isLoading) return;

    _controller.clear();
    provider.sendMessage(text);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  void _copyToClipboard(String text, String messageType) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã sao chép $messageType vào bộ nhớ tạm',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 300,
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF3F3F46)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAllowedWidth = (screenWidth * 0.85).clamp(450.0, 1100.0);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        // Tự động cuộn xuống khi có tin nhắn mới
        _scrollToBottom();

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
              // Thanh kéo co giãn kích thước khung chat (Draggable Resize Handle)
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => setState(() => _isHoveringResizeHandle = true),
                onExit: (_) => setState(() => _isHoveringResizeHandle = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) {
                    setState(() => _isDragging = true);
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      // Kéo sang trái (delta.dx < 0) => tăng chiều rộng
                      // Kéo sang phải (delta.dx > 0) => giảm chiều rộng
                      _chatWidth = (_chatWidth - details.delta.dx)
                          .clamp(320.0, maxAllowedWidth);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() => _isDragging = false);
                  },
                  onDoubleTap: () {
                    // Nhấp đúp để chuyển nhanh giữa kích thước chuẩn (420px) và rộng (680px)
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

              // Nội dung chính của khung chat
              Expanded(
                child: Column(
                  children: [
                    // 1. Header khung Chat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(50),
                        border: Border(
                          bottom: BorderSide(color: theme.dividerColor, width: 1),
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
                            child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trợ lý AI (FPTU RAG)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Backend: http://127.0.0.1:8000',
                                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                          // Nút phóng to / thu nhỏ nhanh kích thước
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

                    // 2. Danh sách tin nhắn
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatProvider.messages.length) {
                            return _buildLoadingBubble(context);
                          }
                          final message = chatProvider.messages[index];
                          return _buildMessageBubble(context, message);
                        },
                      ),
                    ),

                    // 3. Thanh gợi ý câu hỏi nhanh
                    if (chatProvider.messages.length <= 2 && !chatProvider.isLoading)
                      Container(
                        height: 38,
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final item = _suggestions[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                label: Text(item, style: const TextStyle(fontSize: 11.5)),
                                onPressed: () => _handleSend(chatProvider, item),
                              ),
                            );
                          },
                        ),
                      ),

                    // 4. Thanh gõ câu hỏi (Input Bar với Enter để gửi)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(40),
                        border: Border(
                          top: BorderSide(color: theme.dividerColor, width: 1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Focus(
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.enter) {
                                  if (HardwareKeyboard.instance.isShiftPressed) {
                                    // Shift + Enter: Xuống dòng bình thường
                                    return KeyEventResult.ignored;
                                  } else {
                                    // Nhấn Enter: Gửi tin nhắn ngay lập tức mà không cần nhấn button send
                                    _handleSend(chatProvider);
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Hỏi về môn học FPTU... (Enter để gửi, Shift+Enter xuống dòng)',
                                  hintStyle: TextStyle(fontSize: 12, color: theme.hintColor),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(100),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (_) => _handleSend(chatProvider),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: chatProvider.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            onPressed: chatProvider.isLoading ? null : () => _handleSend(chatProvider),
                          ),
                        ],
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

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: message.isError
                  ? Colors.red.withAlpha(50)
                  : colorScheme.primary.withAlpha(40),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.smart_toy_outlined,
                size: 16,
                color: message.isError ? Colors.red : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : (message.isError
                        ? Colors.red.withAlpha(25)
                        : colorScheme.surfaceContainerHighest.withAlpha(120)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 14),
                ),
                border: message.isError
                    ? Border.all(color: Colors.red.withAlpha(100), width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh phụ phía trên bong bóng: Nhãn người gửi + Nút COPY tin nhắn
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isUser ? 'Bạn' : 'Trợ lý AI (FPTU)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUser
                              ? Colors.white.withAlpha(200)
                              : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút copy tin nhắn vào clipboard
                      Tooltip(
                        message: 'Sao chép tin nhắn',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => _copyToClipboard(
                            message.text,
                            isUser ? 'câu hỏi' : 'câu trả lời',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 11.5,
                                  color: isUser
                                      ? Colors.white.withAlpha(200)
                                      : theme.hintColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isUser
                                        ? Colors.white.withAlpha(200)
                                        : theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Nội dung tin nhắn (cho phép chọn & bôi đen copy)
                  if (isUser)
                    SelectableText(
                      message.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: const TextStyle(fontSize: 12.5, height: 1.5),
                        code: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                        codeblockDecoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),

                  // Nguồn trích dẫn (sources)
                  if (!isUser && message.sources.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 12),
                    Row(
                      children: [
                        Icon(Icons.link, size: 13, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Nguồn tham khảo:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: message.sources.map((src) {
                        return InkWell(
                          onTap: () {
                            // Mở tài liệu môn học này trên màn hình chính
                            final noteProvider =
                                Provider.of<NoteProvider>(context, listen: false);
                            final found = noteProvider.selectNoteByLink(src);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  found
                                      ? 'Đang mở tài liệu: $src'
                                      : 'Không tìm thấy file: $src trong thư mục',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colorScheme.primary.withAlpha(60),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description, size: 11, color: colorScheme.primary),
                                const SizedBox(width: 3),
                                Text(
                                  src,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primary.withAlpha(40),
            child: Icon(Icons.smart_toy_outlined, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang tra cứu tài liệu & suy nghĩ...',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
