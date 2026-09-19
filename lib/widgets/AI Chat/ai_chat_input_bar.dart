import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note_file.dart';
import '../../utils/note_frontmatter.dart';

/// Thanh nhập câu hỏi AI với hỗ trợ phím Enter, gợi ý nhanh, @Tag autocomplete.
class AiChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onSend;
  final List<String> suggestions;
  final bool showSuggestions;
  final List<NoteFile> notes;
  final Widget? leadingChips;
  final VoidCallback? onStudyPlanTap;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.suggestions,
    required this.showSuggestions,
    this.notes = const [],
    this.leadingChips,
    this.onStudyPlanTap,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  List<String> _atSuggestions = [];
  int _atStart = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursor = widget.controller.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) {
      if (_atSuggestions.isNotEmpty) setState(() => _atSuggestions = []);
      return;
    }
    final before = text.substring(0, cursor);
    final atMatch = RegExp(r'@([A-Za-z0-9]*)$').firstMatch(before);
    if (atMatch == null) {
      if (_atSuggestions.isNotEmpty) setState(() => _atSuggestions = []);
      return;
    }
    _atStart = atMatch.start;
    final prefix = atMatch.group(1)!.toLowerCase();
    final codes = <String>{};
    for (final note in widget.notes) {
      final id = resolveSubjectId(
        rawContent: note.rawContent,
        fileName: note.fileName,
      );
      if (prefix.isEmpty || id.toLowerCase().startsWith(prefix)) {
        codes.add(id);
      }
    }
    final list = codes.toList()..sort();
    setState(() => _atSuggestions = list.take(12).toList());
  }

  void _insertAtTag(String code) {
    final text = widget.controller.text;
    final cursor = widget.controller.selection.baseOffset;
    if (_atStart < 0 || cursor < _atStart) return;
    final newText =
        '${text.substring(0, _atStart)}@$code ${text.substring(cursor)}';
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: _atStart + code.length + 2),
    );
    setState(() {
      _atSuggestions = [];
      _atStart = -1;
    });
    widget.focusNode.requestFocus();
  }

  void _submitCurrentText() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leadingChips != null) widget.leadingChips!,

        // Gợi ý @Tag
        if (_atSuggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 140),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _atSuggestions.length,
              itemBuilder: (context, index) {
                final code = _atSuggestions[index];
                return ListTile(
                  dense: true,
                  title: Text('@$code', style: const TextStyle(fontSize: 13)),
                  onTap: () => _insertAtTag(code),
                );
              },
            ),
          ),

        // 1. Thanh gợi ý câu hỏi nhanh + chip Lộ trình (chip lộ trình luôn hiện)
        if (!widget.isLoading)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                if (widget.onStudyPlanTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        Icons.timeline,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      label: const Text(
                        'Lộ trình học tập',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      onPressed: widget.onStudyPlanTap,
                    ),
                  ),
                if (widget.showSuggestions)
                  ...widget.suggestions.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ),
                        label:
                            Text(item, style: const TextStyle(fontSize: 11.5)),
                        onPressed: () => widget.onSend(item),
                      ),
                    );
                  }),
              ],
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
                        return KeyEventResult.ignored;
                      } else {
                        _submitCurrentText();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Hỏi về môn học… (@PRM393 để gắn môn, Enter gửi)',
                      hintStyle:
                          TextStyle(fontSize: 12, color: theme.hintColor),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor:
                          colorScheme.surfaceContainerHighest.withAlpha(100),
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
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                onPressed: widget.isLoading ? null : _submitCurrentText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
