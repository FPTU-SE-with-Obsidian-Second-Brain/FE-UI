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
        // Thanh Quick Actions luôn thấy — hiện rõ khi đã bôi đen đủ dài
        Material(
          color: colorScheme.surfaceContainerHighest.withAlpha(
            _hasSelection ? 160 : 70,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: _hasSelection
                      ? colorScheme.primary
                      : theme.hintColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _hasSelection
                        ? 'Đã chọn ${_excerpt.length} ký tự — chọn hành động AI:'
                        : 'Bôi đen đoạn văn (≥12 ký tự) hoặc chuột phải → Quick Actions',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _hasSelection
                          ? colorScheme.onSurface
                          : theme.hintColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _ActionChipBtn(
                  label: 'Giải thích',
                  enabled: _hasSelection,
                  onTap: () => _runAction('explain'),
                ),
                _ActionChipBtn(
                  label: 'Dịch VI',
                  enabled: _hasSelection,
                  onTap: () => _runAction('translate_vi'),
                ),
                _ActionChipBtn(
                  label: 'Tóm tắt',
                  enabled: _hasSelection,
                  onTap: () => _runAction('summarize'),
                ),
              ],
            ),
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
  final bool enabled;
  final VoidCallback onTap;

  const _ActionChipBtn({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: TextButton(
        onPressed: enabled ? onTap : null,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
