import 'package:flutter/material.dart';
import 'file_tree_view.dart';
import 'markdown_viewer.dart';

class SplitView extends StatelessWidget {
  const SplitView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cột danh sách bài học bên trái (khoảng 30%)
        Expanded(
          flex: 3,
          child: FileTreeView(),
        ),
        VerticalDivider(width: 1, thickness: 1),
        // Cột hiển thị nội dung Markdown bên phải (khoảng 70%)
        Expanded(
          flex: 7,
          child: MarkdownViewer(),
        ),
      ],
    );
  }
}
