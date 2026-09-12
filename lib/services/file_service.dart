import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/note_file.dart';
import '../utils/markdown_table_converter.dart';

class FileService {
  /// Quét toàn bộ file .md trong thư mục [folderPath] (bao gồm các thư mục con)
  Future<List<NoteFile>> scanDirectory(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final List<NoteFile> notes = [];
    final entities = dir.listSync(recursive: true, followLinks: false);

    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.md')) {
        try {
          final bytes = await entity.readAsBytes();
          final rawText = utf8.decode(bytes, allowMalformed: true);
          final content = MarkdownTableConverter.cleanAllHtml(rawText);
          final fileName = p.basename(entity.path);
          final title = fileName.replaceAll(RegExp(r'\.md$', caseSensitive: false), '');
          final stat = await entity.stat();

          // Xác định tên thư mục chứa tương đối (ví dụ: "Kỳ 1", "Kỳ 2" hoặc "Tổng quan")
          final relativePath = p.relative(entity.parent.path, from: folderPath);
          final folderName = (relativePath == '.' || relativePath.isEmpty)
              ? 'Tổng quan'
              : relativePath;

          notes.add(NoteFile(
            path: entity.path,
            fileName: fileName,
            title: title,
            folderName: folderName,
            rawContent: content,
            links: extractLinks(content),
            lastModified: stat.modified,
          ));
        } catch (e) {
          // Bỏ qua file lỗi, log lại để debug thay vì crash cả app
          // ignore: avoid_print
          print('Lỗi đọc file ${entity.path}: $e');
        }
      }
    }

    // Sắp xếp danh sách note: Ưu tiên Kỳ 0 -> Kỳ 9 rồi đến các file khác, sau đó xếp theo tên môn
    notes.sort((a, b) {
      if (a.folderName != b.folderName) {
        return a.folderName.compareTo(b.folderName);
      }
      return a.title.compareTo(b.title);
    });

    return notes;
  }

  /// Trích các liên kết dạng [[TenFile]] trong nội dung markdown
  List<String> extractLinks(String content) {
    final regex = RegExp(r'\[\[(.*?)\]\]');
    return regex
        .allMatches(content)
        .map((m) => m.group(1)!.trim())
        .where((link) => link.isNotEmpty)
        .toSet() // Loại bỏ các link trùng lặp trong cùng 1 bài
        .toList();
  }
}
