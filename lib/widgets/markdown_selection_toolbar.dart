import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/course_metadata.dart';
import '../models/note_file.dart';
import '../providers/chat_provider.dart';
import '../utils/note_frontmatter.dart';

/// Bọc vùng Markdown: bắt selection + thanh Quick Actions.
///
/// Quan trọng: child Markdown phải `selectable: false` để SelectionArea
/// làm chủ selection (tránh xung đột với SelectableText bên trong).
class MarkdownSelectionToolbar extends StatefulWidget {
  final Widget child;
  final NoteFile note;

  const MarkdownSelectionToolbar({
    super.key,
    required this.child,
    required this.note,
  });

  @override
  State<MarkdownSelectionToolbar> createState() =>
      _MarkdownSelectionToolbarState();
}

class _MarkdownSelectionToolbarState extends State<MarkdownSelectionToolbar> {
  String? _selectedText;

  static const int _minChars = 12;

  String get _excerpt => _selectedText?.trim() ?? '';
  bool get _hasSelection => _excerpt.length >= _minChars;

  void _onSelectionChanged(SelectedContent? content) {
    final text = content?.plainText.trim() ?? '';
    final next = text.length >= _minChars ? text : null;
    if (next == _selectedText) return;
    setState(() => _selectedText = next);
  }

  String _subjectId() {
    final meta = CourseMetadata.fromNote(widget.note);
    return resolveSubjectId(
      rawContent: widget.note.rawContent,
      fileName: widget.note.fileName,
      bodyCode: meta.code,
    );
  }

  String? _sourceFile() {
    final note = widget.note;
    if (note.folderName.isNotEmpty &&
        note.folderName != 'Tổng quan' &&
        note.folderName != 'Gốc') {
      return '${note.folderName}/${note.fileName}';
    }
    return note.fileName;
  }

  void _runAction(String action) {
    final excerpt = _excerpt;
    if (excerpt.length < _minChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy bôi đen ít nhất ~12 ký tự trong nội dung môn học trước.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.sendQuickAction(
      action: action,
      excerpt: excerpt,
      sourceId: _subjectId(),
      sourceFile: _sourceFile(),
    );
    setState(() => _selectedText = null);
  }

  Future<void> _runActionFromClipboard(String action) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.length < _minChars) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có đoạn chọn. Bôi đen văn bản (hoặc Ctrl+C) rồi thử lại.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _selectedText = text);
    _runAction(action);
  }

  void _showContextMenu(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final position = RelativeRect.fromLTRB(
      local.dx,
      local.dy,
      local.dx + 1,
      local.dy + 1,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: 'explain', child: Text('Giáo sư AI giải thích')),
        PopupMenuItem(value: 'translate_vi', child: Text('Dịch sang tiếng Việt')),
        PopupMenuItem(value: 'summarize', child: Text('Tóm tắt')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'clipboard_explain',
          child: Text('Dùng đoạn vừa Copy (Ctrl+C) → Giải thích'),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      if (value.startsWith('clipboard_')) {
        _runActionFromClipboard(value.replaceFirst('clipboard_', ''));
      } else if (_hasSelection) {
        _runAction(value);
      } else {
        _runActionFromClipboard(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thanh Quick Actions luôn thấy — sáng rõ, nổi bật các nút AI
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: _hasSelection
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface.withAlpha(220),
            border: Border(
              bottom: BorderSide(
                color: _hasSelection
                    ? colorScheme.primary.withAlpha(160)
                    : theme.dividerColor.withAlpha(90),
                width: _hasSelection ? 1.5 : 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _hasSelection
                      ? colorScheme.primary.withAlpha(50)
                      : colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: _hasSelection
                      ? colorScheme.secondary
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasSelection
                      ? 'Đã chọn ${_excerpt.length} ký tự — sẵn sàng chạy AI:'
                      : 'Bôi đen đoạn văn (≥12 ký tự) hoặc chọn nhanh:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _hasSelection ? FontWeight.w600 : FontWeight.normal,
                    color: _hasSelection
                        ? colorScheme.onSurface
                        : theme.hintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ActionChipBtn(
                label: 'Giải thích',
                icon: Icons.lightbulb_rounded,
                enabled: _hasSelection,
                accentColor: const Color(0xFFF59E0B),
                onTap: () => _runAction('explain'),
              ),
              _ActionChipBtn(
                label: 'Dịch VI',
                icon: Icons.translate_rounded,
                enabled: _hasSelection,
                accentColor: const Color(0xFF38BDF8),
                onTap: () => _runAction('translate_vi'),
              ),
              _ActionChipBtn(
                label: 'Tóm tắt',
                icon: Icons.summarize_rounded,
                enabled: _hasSelection,
                accentColor: const Color(0xFF34D399),
                onTap: () => _runAction('summarize'),
              ),
            ],
          ),
        ),

        Expanded(
          child: GestureDetector(
            onSecondaryTapUp: (details) {
              _showContextMenu(details.globalPosition);
            },
            child: SelectionArea(
              onSelectionChanged: _onSelectionChanged,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChipBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionChipBtn({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(enabled ? 65 : 28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withAlpha(enabled ? 240 : 130),
                width: enabled ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(enabled ? 90 : 35),
                  blurRadius: enabled ? 8 : 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13.5,
                  color: enabled ? Colors.white : accentColor,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: enabled ? FontWeight.bold : FontWeight.w600,
                    color: enabled ? Colors.white : const Color(0xFFF4F4F5),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
