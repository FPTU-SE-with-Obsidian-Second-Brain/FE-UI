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

          // Chuẩn hóa đường dẫn tương đối (ví dụ: "Kỳ 5/SE_COM＊1/React NodeJS" hoặc ".")
          final relativePath = p
              .relative(entity.parent.path, from: folderPath)
              .replaceAll('\\', '/');

          String folderName;
          String? comboTrack;
          String fullFolderPath;

          if (relativePath == '.' || relativePath.isEmpty) {
            folderName = 'Tổng quan';
            comboTrack = null;
            fullFolderPath = 'Tổng quan';
          } else {
            final segments = relativePath.split('/').where((s) => s.isNotEmpty).toList();
            folderName = segments.first; // Luôn gom về thư mục học kỳ chính: "Kỳ 0", "Kỳ 1", ..., "Kỳ 9"

            if (segments.length > 1) {
              final rawTrack = segments.last;
              comboTrack = _cleanTrackName(rawTrack);
              fullFolderPath = segments.join(' › ');
            } else {
              comboTrack = null;
              fullFolderPath = folderName;
            }
          }

          notes.add(NoteFile(
            path: entity.path,
            fileName: fileName,
            title: title,
            folderName: folderName,
            comboTrack: comboTrack,
            fullFolderPath: fullFolderPath,
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

    // Sắp xếp danh sách note: Thứ tự Kỳ 0 -> Kỳ 9 -> Tổng quan
    // Trong mỗi kỳ: Môn cốt lõi/bắt buộc đứng trước, sau đó đến môn chuyên ngành/combo
    notes.sort((a, b) {
      final semA = getSemesterOrder(a.folderName);
      final semB = getSemesterOrder(b.folderName);
      if (semA != semB) {
        return semA.compareTo(semB);
      }
      if (a.folderName != b.folderName) {
        return a.folderName.compareTo(b.folderName);
      }
      // Ưu tiên môn chung (comboTrack == null) trước môn chuyên ngành
      if ((a.comboTrack == null) != (b.comboTrack == null)) {
        return a.comboTrack == null ? -1 : 1;
      }
      if (a.comboTrack != null && b.comboTrack != null && a.comboTrack != b.comboTrack) {
        return a.comboTrack!.compareTo(b.comboTrack!);
      }
      return a.title.compareTo(b.title);
    });

    return notes;
  }

  /// Làm sạch và rút gọn tên chuyên ngành / combo để hiển thị thanh lịch
  static String _cleanTrackName(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('kỹ sư cầu nối')) return 'Tiếng Nhật CNTT';
    if (lower.contains('tiếng hàn')) return 'Tiếng Hàn';
    if (lower.contains('.net')) return '.NET';
    if (lower.contains('react') || lower.contains('node')) return 'React NodeJS';
    if (lower.contains('game')) return 'Game Dev';
    if (lower.contains('vi mạch')) return 'Vi mạch';
    if (lower.contains('devsepops') || lower.contains('devsecops')) return 'DevSecOps';
    if (lower.contains('khdl') || lower.contains('dữ liệu')) return 'Data Science';
    if (lower.contains('java')) return 'Java Pro';
    if (lower.contains('cờ vua')) return 'Cờ vua';
    if (lower.contains('vovinam')) return 'Vovinam';
    if (lower.contains('ai')) return 'AI';
    if (raw.startsWith('SE_COM') || raw.startsWith('Kỳ ')) return 'Combo';
    if (raw.length > 20) return '${raw.substring(0, 18)}...';
    return raw;
  }

  /// Xác định thứ tự sắp xếp học kỳ (Kỳ 0 -> Kỳ 9 -> Tổng quan)
  static int getSemesterOrder(String folderName) {
    final match = RegExp(r'kỳ\s*(\d+)', caseSensitive: false).firstMatch(folderName);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    if (folderName.toLowerCase().contains('tổng quan') ||
        folderName.toLowerCase().contains('chung') ||
        folderName == '.') {
      return 999;
    }
    return 100;
  }

  /// Trích các liên kết dạng [[TenFile]] trong nội dung markdown
  List<String> extractLinks(String content) {
    final regex = RegExp(r'\[\[(.*?)\]\]');
    return regex
        .allMatches(content)
        .map((m) {
          final raw = m.group(1)!.trim();
          // Hỗ trợ cú pháp alias [[Target|Tên hiển thị]]
          return raw.contains('|') ? raw.split('|').first.trim() : raw;
        })
        .where((link) => link.isNotEmpty)
        .toSet() // Loại bỏ các link trùng lặp trong cùng 1 bài
        .toList();
  }
}
