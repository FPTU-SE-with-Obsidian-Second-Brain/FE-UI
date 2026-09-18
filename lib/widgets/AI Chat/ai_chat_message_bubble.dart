import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/note_provider.dart';

export 'ai_chat_loading_bubble.dart';

/// Bong bóng hiển thị tin nhắn trong khung Chat AI (người dùng & AI)
class AiChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const AiChatMessageBubble({super.key, required this.message});

  void _copyToClipboard(BuildContext context, String text, String messageType) {
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
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: message.isError
                  ? Colors.red.withAlpha(50)
                  : colorScheme.primary.withAlpha(40),
              child: Icon(
                message.isError
                    ? Icons.error_outline
                    : Icons.smart_toy_outlined,
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
                            context,
                            message.text,
                            isUser ? 'câu hỏi' : 'câu trả lời',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
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
                        code: const TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                        ),
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
                            final noteProvider = Provider.of<NoteProvider>(
                              context,
                              listen: false,
                            );
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                                Icon(
                                  Icons.description,
                                  size: 11,
                                  color: colorScheme.primary,
                                ),
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
}
