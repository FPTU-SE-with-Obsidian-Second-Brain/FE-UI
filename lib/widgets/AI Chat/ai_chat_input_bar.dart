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
  final VoidCallback? onToggleScope;
  final bool isScopeActive;
  final String? currentSubjectId;

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
    this.onToggleScope,
    this.isScopeActive = false,
    this.currentSubjectId,
  });

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  List<String> _atSuggestions = [];
  int _atStart = -1;
  int _atEnd = -1;
  int _selectedIndex = 0;
  final ScrollController _atScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _atScrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursor = widget.controller.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) {
      if (_atSuggestions.isNotEmpty) {
        setState(() {
          _atSuggestions = [];
          _selectedIndex = 0;
          _atStart = -1;
          _atEnd = -1;
        });
      }
      return;
    }
    final before = text.substring(0, cursor);
    final atMatch = RegExp(r'@([A-Za-z0-9]*)$').firstMatch(before);
    if (atMatch == null) {
      if (_atSuggestions.isNotEmpty) {
        setState(() {
          _atSuggestions = [];
          _selectedIndex = 0;
          _atStart = -1;
          _atEnd = -1;
        });
      }
      return;
    }
    _atStart = atMatch.start;

    // Tìm điểm kết thúc nếu có ký tự ngay sau con trỏ thuộc token @ này
    final after = text.substring(cursor);
    final afterMatch = RegExp(r'^[A-Za-z0-9]*').firstMatch(after);
    _atEnd = cursor + (afterMatch?.group(0)?.length ?? 0);

    final prefix = atMatch.group(1)!.toLowerCase();
    final codes = <String>{};
    for (final note in widget.notes) {
      final id = resolveSubjectId(
        rawContent: note.rawContent,
        fileName: note.fileName,
      );
      if (prefix.isEmpty || id.toLowerCase().contains(prefix)) {
        codes.add(id);
      }
    }
    final list = codes.toList()
      ..sort((a, b) {
        final aStarts = a.toLowerCase().startsWith(prefix);
        final bStarts = b.toLowerCase().startsWith(prefix);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return a.compareTo(b);
      });
    final topList = list.take(12).toList();
    setState(() {
      _atSuggestions = topList;
      _selectedIndex = 0;
    });
  }

  void _scrollToSelected() {
    if (_atScrollController.hasClients && _atSuggestions.isNotEmpty) {
      const itemHeight = 36.0;
      final target = (_selectedIndex * itemHeight).clamp(
        0.0,
        _atScrollController.position.maxScrollExtent,
      );
      _atScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
      );
    }
  }

  void _insertAtTag(String code) {
    final text = widget.controller.text;
    if (_atStart < 0 || _atStart > text.length) return;

    int end = _atEnd;
    if (end < _atStart || end > text.length) {
      final cursor = widget.controller.selection.baseOffset;
      end = (cursor >= _atStart && cursor <= text.length)
          ? cursor
          : text.length;
    }

    final prefix = text.substring(0, _atStart);
    final suffix = text.substring(end);
    final newText = '$prefix@$code $suffix';
    final newCursor = _atStart + code.length + 2;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCursor.clamp(0, newText.length),
      ),
    );

    setState(() {
      _atSuggestions = [];
      _atStart = -1;
      _atEnd = -1;
      _selectedIndex = 0;
    });

    widget.focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.focusNode.requestFocus();
      }
    });
  }

  void _submitCurrentText() {
    // Nếu đang mở popup gợi ý môn học, phím Enter sẽ chọn môn thay vì gửi chat
    if (_atSuggestions.isNotEmpty) {
      if (_selectedIndex >= 0 && _selectedIndex < _atSuggestions.length) {
        _insertAtTag(_atSuggestions[_selectedIndex]);
      }
      return;
    }
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
        // Gợi ý @Tag
        if (_atSuggestions.isNotEmpty)
          FocusScope(
            canRequestFocus: false,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(140),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alternate_email,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Chọn môn học',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '↑↓ duyệt · Enter / Tab để chọn',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: theme.dividerColor.withAlpha(120),
                  ),
                  Flexible(
                    child: ListView.builder(
                      controller: _atScrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _atSuggestions.length,
                      itemBuilder: (context, index) {
                        final code = _atSuggestions[index];
                        final isSelected = index == _selectedIndex;
                        return InkWell(
                          canRequestFocus: false,
                          onTap: () => _insertAtTag(code),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            color: isSelected
                                ? colorScheme.primary.withAlpha(45)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.primary.withAlpha(60),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '@$code',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Text(
                                    'Enter để chọn ↵',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 1. Filter chip nằm ở bên trái (giống Image 1)
        if (widget.leadingChips != null)
          widget.leadingChips!,

        // 2. Thanh gợi ý câu hỏi nhanh + chip Lộ trình (chip lộ trình luôn hiện)
        if (!widget.isLoading)
          Container(
            height: 34,
            margin: const EdgeInsets.only(top: 2, bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                if (widget.onStudyPlanTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.primary.withAlpha(25),
                      side: BorderSide(
                        color: colorScheme.primary.withAlpha(110),
                        width: 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      avatar: Icon(
                        Icons.timeline,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      label: const Text(
                        'Lộ trình học tập',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
                        backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                        side: BorderSide(
                          color: theme.dividerColor.withAlpha(150),
                          width: 0.9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ),
                        label: Text(
                          item,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colorScheme.onSurface.withAlpha(220),
                          ),
                        ),
                        onPressed: () => widget.onSend(item),
                      ),
                    );
                  }),
              ],
            ),
          ),

        // 3. Thanh gõ câu hỏi (Input Field) kèm nút công cụ / filter bên trái giống Gemini (Ảnh 2)
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
              // Nút Công cụ / Filter bên trái giống Gemini (Ảnh 2)
              _buildLeftToolsButton(context, colorScheme, theme),
              const SizedBox(width: 8),
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;

                    if (_atSuggestions.isNotEmpty) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() {
                          _selectedIndex =
                              (_selectedIndex + 1) % _atSuggestions.length;
                        });
                        _scrollToSelected();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() {
                          _selectedIndex =
                              (_selectedIndex - 1 + _atSuggestions.length) %
                              _atSuggestions.length;
                        });
                        _scrollToSelected();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                          event.logicalKey == LogicalKeyboardKey.tab) {
                        if (_selectedIndex >= 0 &&
                            _selectedIndex < _atSuggestions.length) {
                          _insertAtTag(_atSuggestions[_selectedIndex]);
                          return KeyEventResult.handled;
                        }
                      }
                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        setState(() {
                          _atSuggestions = [];
                          _atStart = -1;
                          _atEnd = -1;
                          _selectedIndex = 0;
                        });
                        return KeyEventResult.handled;
                      }
                    }

                    if (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
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

  /// Nút công cụ / Filter bên trái thanh nhập liệu (Thiết kế lấy cảm hứng từ Gemini trong Ảnh 2)
  Widget _buildLeftToolsButton(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final subId = widget.currentSubjectId;
    final hasScope = widget.isScopeActive;

    return PopupMenuButton<String>(
      tooltip: subId != null
          ? (hasScope ? 'Đang lọc theo $subId (Bấm để tùy chọn)' : 'Lọc & Công cụ AI')
          : 'Công cụ AI',
      offset: const Offset(0, -210), // Mở menu hướng lên trên từ góc trái
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withAlpha(120)),
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      icon: Container(
        height: 38,
        padding: EdgeInsets.symmetric(
          horizontal: hasScope && subId != null ? 10 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: hasScope
              ? colorScheme.primary.withAlpha(45)
              : colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasScope
                ? colorScheme.primary
                : theme.dividerColor.withAlpha(140),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasScope ? Icons.filter_alt_rounded : Icons.tune_rounded,
              size: 16,
              color: hasScope ? colorScheme.primary : theme.hintColor,
            ),
            if (hasScope && subId != null) ...[
              const SizedBox(width: 4),
              Text(
                subId,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
      onSelected: (action) {
        if (action == 'toggle_scope') {
          widget.onToggleScope?.call();
        } else if (action == 'study_plan') {
          widget.onStudyPlanTap?.call();
        } else if (action == 'summarize' && subId != null) {
          widget.onSend('Tóm tắt tổng quan môn học $subId');
        } else if (action == 'flashcard' && subId != null) {
          widget.onSend('Tạo 10 flashcard câu hỏi ôn tập trọng tâm môn $subId');
        } else if (action == 'prereq' && subId != null) {
          widget.onSend('Điều kiện tiên quyết và môn liên quan của $subId là gì?');
        }
      },
      itemBuilder: (context) => [
        if (subId != null)
          PopupMenuItem<String>(
            value: 'toggle_scope',
            child: Row(
              children: [
                Icon(
                  hasScope
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: hasScope ? colorScheme.primary : theme.hintColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chỉ hỏi trong môn này ($subId)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: hasScope ? FontWeight.bold : FontWeight.normal,
                      color: hasScope ? colorScheme.primary : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.onStudyPlanTap != null)
          const PopupMenuItem<String>(
            value: 'study_plan',
            child: Row(
              children: [
                Icon(Icons.timeline_rounded, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Lập lộ trình học tập FPTU', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
        if (subId != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'summarize',
            child: Row(
              children: [
                const Icon(Icons.auto_stories_rounded, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Tóm tắt môn $subId', style: const TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'flashcard',
            child: Row(
              children: [
                const Icon(Icons.style_rounded, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('10 Flashcard ôn tập $subId', style: const TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'prereq',
            child: Row(
              children: [
                const Icon(Icons.account_tree_rounded, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Môn tiên quyết & liên kết', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
