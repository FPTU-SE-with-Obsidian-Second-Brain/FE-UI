import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_app/services/file_service.dart';
import 'package:obsidian_app/utils/markdown_table_converter.dart';

void main() {
  test('FileService scans crawled Obsidian second brain folder successfully', () async {
    final service = FileService();
    final dataDir = Directory('Obsidian second brain');

    if (await dataDir.exists()) {
      final notes = await service.scanDirectory(dataDir.path);
      expect(notes.isNotEmpty, true);

      // Kiểm tra xem có quét được các môn cơ bản không
      final prf192 = notes.where((n) => n.fileName == 'PRF192.md');
      expect(prf192.isNotEmpty, true);
      expect(prf192.first.folderName, 'Kỳ 1');
      expect(prf192.first.rawContent.contains('Programming Fundamentals'), true);

      // Kiểm tra xem DTB103.md có được chuyển đổi bảng HTML không
      final dtb103 = notes.where((n) => n.fileName == 'DTB103.md');
      expect(dtb103.isNotEmpty, true);
      expect(dtb103.first.rawContent.contains('| Thông tin | Nội dung chi tiết |'), true);
      expect(dtb103.first.rawContent.contains('Nhạc cụ truyền thống- Đàn Tỳ bà'), true);
    }
  });

  test('MarkdownTableConverter converts HTML tables to Markdown GFM tables', () {
    const htmlTable = '''
<table>
<tr><td><b>Syllabus ID:</b></td><td>11838</td></tr>
<tr><td><b>Syllabus Name:</b></td><td><b>Nhạc cụ truyền thống</b></td></tr>
</table>
''';
    final converted = MarkdownTableConverter.convertHtmlTablesToMarkdown(htmlTable);
    expect(converted.contains('| Thông tin | Nội dung chi tiết |'), true);
    expect(converted.contains('| **Syllabus ID:** | 11838 |'), true);
  });

  test('FileService extractLinks extracts [[...]] correctly', () {
    final service = FileService();
    const sample = 'Học xong môn [[PRF192]] rồi sẽ học [[PRO192]] và [[CSD201|Data Structures]]. Không lấy [link thường].';
    final links = service.extractLinks(sample);
    expect(links, ['PRF192', 'PRO192', 'CSD201']);
  });

  test('FileService.getSemesterOrder orders semesters chronologically', () {
    final folders = ['Tổng quan', 'Kỳ 5', 'Kỳ 1', 'Kỳ 0', 'Kỳ 9', 'Kỳ 2'];
    folders.sort((a, b) => FileService.getSemesterOrder(a).compareTo(FileService.getSemesterOrder(b)));
    expect(folders, ['Kỳ 0', 'Kỳ 1', 'Kỳ 2', 'Kỳ 5', 'Kỳ 9', 'Tổng quan']);
  });

  test('MarkdownTableConverter.formatWikiLinks formats wikilinks to clean markdown links', () {
    const raw = 'Môn học [[COV121]] và [[PRM393|Mobile Programming]].';
    final formatted = MarkdownTableConverter.formatWikiLinks(raw);
    expect(formatted, 'Môn học [COV121](COV121) và [Mobile Programming](PRM393).');
  });
}
