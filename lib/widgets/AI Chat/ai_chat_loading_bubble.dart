import 'package:flutter/material.dart';

/// Bong bóng hiển thị trạng thái đang suy nghĩ và tra cứu của AI
class AiChatLoadingBubble extends StatelessWidget {
  const AiChatLoadingBubble({super.key});

  @override
  Widget build(BuildContext context) {
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
