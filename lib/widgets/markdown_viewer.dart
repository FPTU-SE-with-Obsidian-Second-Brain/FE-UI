import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../utils/markdown_table_converter.dart';

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
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          note.folderName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        note.fileName,
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
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
                        Text(
                          'Liên kết [[ ]]:',
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                        ...note.links.map((link) {
                          return ActionChip(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            label: Text('[[$link]]'),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: colorScheme.primary.withAlpha(25),
                            side: BorderSide(color: colorScheme.primary.withAlpha(80)),
                            onPressed: () {
                              final found = provider.selectNoteByLink(link);
                              if (!found) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Không tìm thấy môn học: $link'),
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

            // Khu vực hiển thị Markdown đã render
            Expanded(
              child: Markdown(
                data: MarkdownTableConverter.cleanAllHtml(note.rawContent),
                selectable: true,
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
          ],
        );
      },
    );
  }
}
