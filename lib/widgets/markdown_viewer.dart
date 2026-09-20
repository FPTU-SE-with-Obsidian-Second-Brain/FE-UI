import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../utils/markdown_table_converter.dart';
import '../services/course_pdf_exporter.dart';
import 'markdown_selection_toolbar.dart';

/// Cú pháp nội dòng để chuyển thẻ <br> thành ngắt dòng thực sự trong Markdown
class HtmlBrSyntax extends md.InlineSyntax {
  HtmlBrSyntax() : super(r'<br\s*\/?>', caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('br', '\n'));
    return true;
  }
}

class MarkdownViewer extends StatelessWidget {
  const MarkdownViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        final note = provider.selectedNote;

        if (note == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chọn một môn học từ danh sách bên trái',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh tiêu đề bài học đang chọn
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(50),
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor.withAlpha(50)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              note.folderName.contains('Kỳ')
                                  ? Icons.school_outlined
                                  : Icons.folder_outlined,
                              size: 13,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.comboTrack != null
                                  ? '${note.folderName} › ${note.comboTrack}'
                                  : note.folderName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        note.fileName,
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Xuất đề cương PDF đẹp',
                        child: FilledButton.tonalIcon(
                          onPressed: () => exportCoursePdf(context, note),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: const Text('Xuất PDF', style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (note.links.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 14, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              'Môn liên kết:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        ...note.links.map((link) {
                          final cleanLink = link.replaceAll(RegExp(r'[\[\]]'), '').trim();
                          return ActionChip(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                            avatar: Icon(Icons.link_rounded, size: 12, color: colorScheme.primary),
                            label: Text(cleanLink),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: colorScheme.primary.withAlpha(25),
                            side: BorderSide(color: colorScheme.primary.withAlpha(80)),
                            onPressed: () {
                              final found = provider.selectNoteByLink(cleanLink);
                              if (!found) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Không tìm thấy môn học: $cleanLink'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Khu vực hiển thị Markdown đã render (+ quick actions khi bôi đen)
            Expanded(
              child: MarkdownSelectionToolbar(
                note: note,
                child: Markdown(
                  data: MarkdownTableConverter.formatWikiLinks(
                    MarkdownTableConverter.cleanAllHtml(note.rawContent),
                  ),
                  // false: SelectionArea (Quick Actions) làm chủ selection.
                  // true sẽ tạo SelectableText lồng nhau → onSelectionChanged không chạy.
                  selectable: false,
                  inlineSyntaxes: [HtmlBrSyntax()],
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      // Nếu là link dạng môn học
                      final success = provider.selectNoteByLink(href);
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Liên kết: $href')),
                        );
                      }
                    }
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    h1: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    p: const TextStyle(fontSize: 13.5, height: 1.6),
                    code: TextStyle(
                      backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(120),
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(90),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor.withAlpha(80)),
                    ),
                    blockquote: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: colorScheme.onSurface.withAlpha(230),
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: colorScheme.primary,
                          width: 3.5,
                        ),
                      ),
                    ),
                    blockquotePadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    tableBorder: TableBorder.all(
                      color: theme.dividerColor.withAlpha(100),
                      width: 0.8,
                    ),
                    tableHead: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    tableBody: const TextStyle(fontSize: 12),
                    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
