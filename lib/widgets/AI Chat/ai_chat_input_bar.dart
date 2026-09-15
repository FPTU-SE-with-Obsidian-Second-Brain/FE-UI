import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thanh nhập câu hỏi AI với hỗ trợ phím Enter để gửi và gợi ý câu hỏi nhanh
class AiChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onSend;
  final List<String> suggestions;
  final bool showSuggestions;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.suggestions,
    required this.showSuggestions,
  });

  void _submitCurrentText() {
    final text = controller.text.trim();
    if (text.isNotEmpty && !isLoading) {
      onSend(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Thanh gợi ý câu hỏi nhanh (nếu có)
        if (showSuggestions && !isLoading)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    label: Text(item, style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => onSend(item),
                  ),
                );
              },
            ),
          ),

        // 2. Thanh gõ câu hỏi (Input Field)
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
                        // Nhấn Enter: Gửi tin nhắn ngay lập tức mà không cần bấm nút send
                        _submitCurrentText();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
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
                    onSubmitted: (_) => _submitCurrentText(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                onPressed: isLoading ? null : _submitCurrentText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
