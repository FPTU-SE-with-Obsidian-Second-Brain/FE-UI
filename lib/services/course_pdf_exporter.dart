import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/course_metadata.dart';
import '../models/note_file.dart';

/// Xuất đề cương môn học ra PDF đẹp (bìa + thông tin + đánh giá + nội dung).
class CoursePdfExporter {
  // Palette học thuật: navy + teal (không dùng purple mặc định AI)
  static const _navy = PdfColor.fromInt(0xFF0B1F33);
  static const _navyMid = PdfColor.fromInt(0xFF143A52);
  static const _teal = PdfColor.fromInt(0xFF0F766E);
  static const _tealSoft = PdfColor.fromInt(0xFFCCFBF1);
  static const _sand = PdfColor.fromInt(0xFFF7F4EF);
  static const _ink = PdfColor.fromInt(0xFF1C1917);
  static const _muted = PdfColor.fromInt(0xFF57534E);
  static const _line = PdfColor.fromInt(0xFFD6D3D1);
  static const _card = PdfColor.fromInt(0xFFFFFFFF);
  static const _accent = PdfColor.fromInt(0xFFEA580C);

  Future<Uint8List> buildPdf(NoteFile note) async {
    final meta = CourseMetadata.fromNote(note);
    final sections = _parseSections(note.rawContent);

    // Font hỗ trợ tiếng Việt (Noto Sans)
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final medium = await PdfGoogleFonts.notoSansMedium();

    final doc = pw.Document(
      title: '${meta.code} — ${meta.name}',
      author: 'FPTU SE Second Brain',
      subject: 'Đề cương môn học ${meta.code}',
      creator: 'Obsidian Second Brain · PRM393',
    );

    final theme = pw.ThemeData.withFont(
      base: base,
      bold: bold,
      italic: base,
      boldItalic: bold,
    );

    // —— Trang bìa ——
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (context) => _buildCover(note, meta, medium),
      ),
    );

    // —— Nội dung ——
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        theme: theme,
        header: (context) => _pageHeader(meta),
        footer: (context) => _pageFooter(context, meta),
        build: (context) => [
          _sectionTitle('Thông tin chung', IconsStyle.info),
          pw.SizedBox(height: 10),
          _infoGrid(note, meta),
          pw.SizedBox(height: 18),
          if (meta.prerequisites.isNotEmpty) ...[
            _sectionTitle('Môn tiên quyết', IconsStyle.link),
            pw.SizedBox(height: 8),
            _chipRow(meta.prerequisites),
            pw.SizedBox(height: 18),
          ],
          _sectionTitle('Điều kiện hoàn thành', IconsStyle.check),
          pw.SizedBox(height: 8),
          _passBox(meta.passCriteria),
          pw.SizedBox(height: 18),
          if (meta.assessments.isNotEmpty) ...[
            _sectionTitle('Cấu trúc đánh giá', IconsStyle.chart),
            pw.SizedBox(height: 10),
            ...meta.assessments.map(_assessmentRow),
            pw.SizedBox(height: 8),
            _totalBar(meta.assessments),
            pw.SizedBox(height: 18),
          ],
          if (meta.description.trim().isNotEmpty) ...[
            _sectionTitle('Mô tả môn học', IconsStyle.book),
            pw.SizedBox(height: 8),
            ..._spanningBody(meta.description),
            pw.SizedBox(height: 18),
          ],
          ..._contentSections(sections),
        ],
      ),
    );

    return doc.save();
  }

  /// Xuất PDF: lưu file về máy (dialog Save As). Không bắt buộc mở hộp thoại in.
  Future<String?> export(
    BuildContext context,
    NoteFile note, {
    bool showPreview = false,
  }) async {
    final bytes = await buildPdf(note);
    final meta = CourseMetadata.fromNote(note);
    final safeCode = meta.code.replaceAll(RegExp(r'[^\w\-]+'), '_');

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Tải về đề cương PDF — ${meta.code}',
      fileName: '${safeCode}_de_cuong.pdf',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );

    if (path == null) return null;

    final filePath = path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
    await File(filePath).writeAsBytes(bytes, flush: true);

    if (showPreview && context.mounted) {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${safeCode}_syllabus',
      );
    }
    return filePath;
  }

  // ─── Cover ─────────────────────────────────────────────

  pw.Widget _buildCover(NoteFile note, CourseMetadata meta, pw.Font medium) {
    return pw.Stack(
      children: [
        // Nền
        pw.Container(color: _sand),
        // Band trên
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            height: 220,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [_navy, _navyMid, _teal],
              ),
            ),
          ),
        ),
        // Accent stripe
        pw.Positioned(
          top: 220,
          left: 0,
          right: 0,
          child: pw.Container(height: 6, color: _accent),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FPT UNIVERSITY · SOFTWARE ENGINEERING',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      letterSpacing: 1.4,
                      font: medium,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0x33FFFFFF),
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      note.folderName.isEmpty ? 'Syllabus' : note.folderName,
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 36),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: _accent,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  meta.code.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                meta.name,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  height: 1.25,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Đề cương môn học · Course Syllabus',
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFFCCFBF1),
                  fontSize: 12,
                ),
              ),
              pw.Spacer(),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: _card,
                  borderRadius: pw.BorderRadius.circular(14),
                  border: pw.Border.all(color: _line, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _coverStat('Tín chỉ', meta.credits.replaceAll(' tín chỉ', '')),
                    _vDivider(),
                    _coverStat(
                      'Tiên quyết',
                      meta.prerequisites.isEmpty
                          ? '—'
                          : '${meta.prerequisites.length}',
                    ),
                    _vDivider(),
                    _coverStat(
                      'Đánh giá',
                      '${meta.assessments.length} TP',
                    ),
                    _vDivider(),
                    _coverStat('Nguồn', 'Second Brain'),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Xuất từ FPTU SE Second Brain  ·  ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                style: const pw.TextStyle(color: _muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _coverStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          label,
          style: const pw.TextStyle(color: _muted, fontSize: 8.5),
        ),
      ],
    );
  }

  pw.Widget _vDivider() => pw.Container(width: 1, height: 28, color: _line);

  // ─── Body widgets ──────────────────────────────────────

  pw.Widget _pageHeader(CourseMetadata meta) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${meta.code}  ·  ${meta.name}',
            style: const pw.TextStyle(color: _muted, fontSize: 8.5),
          ),
          pw.Text(
            'FPTU SE',
            style: pw.TextStyle(
              color: _teal,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter(pw.Context context, CourseMetadata meta) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Đề cương ${meta.code}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
          pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title, IconsStyle icon) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: _teal,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            color: _navy,
            fontSize: 13.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _infoGrid(NoteFile note, CourseMetadata meta) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _tealSoft,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          _infoRow('Mã môn học', meta.code),
          _infoRow('Tên môn học', meta.name),
          _infoRow('Số tín chỉ', meta.credits),
          _infoRow('Học kỳ / thư mục', note.folderName),
          _infoRow('Tệp nguồn', note.fileName),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: _teal,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(color: _ink, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _chipRow(List<String> items) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((e) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.circular(14),
          ),
          child: pw.Text(
            e,
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _passBox(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: _ink, fontSize: 9.5, height: 1.45),
      ),
    );
  }

  pw.Widget _assessmentRow(AssessmentComponent a) {
    final color = PdfColor(
      a.color.r,
      a.color.g,
      a.color.b,
      a.color.a,
    );
    final pct = a.weightPercent.clamp(0, 100) / 100.0;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  a.category,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                '${a.weightPercent.toStringAsFixed(a.weightPercent % 1 == 0 ? 0 : 1)}%',
                style: pw.TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.ClipRRect(
            horizontalRadius: 4,
            verticalRadius: 4,
            child: pw.Container(
              height: 7,
              color: PdfColor.fromInt(0xFFE7E5E4),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: (pct * 1000).round().clamp(1, 1000),
                    child: pw.Container(color: color),
                  ),
                  pw.Expanded(
                    flex: ((1 - pct) * 1000).round().clamp(0, 1000),
                    child: pw.SizedBox(),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${a.criteria}${a.details.isNotEmpty ? '  ·  ${a.details}' : ''}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _totalBar(List<AssessmentComponent> items) {
    final total = items.fold<double>(0, (s, e) => s + e.weightPercent);
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Tổng trọng số: ${total.toStringAsFixed(0)}%',
        style: pw.TextStyle(
          color: _navy,
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Nội dung dài: mỗi dòng Markdown → widget nhỏ (cắt trang được), format gần preview.
  List<pw.Widget> _spanningBody(String text) {
    final raw = _preprocessMarkdown(text);
    if (raw.trim().isEmpty) return const [];

    final lines = raw.split(RegExp(r'\r?\n'));
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      // ### heading
      final h3 = RegExp(r'^###\s+(.+)$').firstMatch(trimmed.trim());
      if (h3 != null) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
            child: pw.Text(
              h3.group(1)!.trim(),
              style: pw.TextStyle(
                color: _navy,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );
        continue;
      }

      // List item: - / * / •
      final bullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(trimmed.trim());
      if (bullet != null) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 14,
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Text(
                    '•',
                    style: pw.TextStyle(
                      color: _teal,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(child: _richParagraph(bullet.group(1)!)),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered: 1. / 1)
      final numbered =
          RegExp(r'^(\d+)[\.\)]\s+(.*)$').firstMatch(trimmed.trim());
      if (numbered != null) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 18,
                  child: pw.Text(
                    '${numbered.group(1)}.',
                    style: pw.TextStyle(
                      color: _teal,
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(child: _richParagraph(numbered.group(2)!)),
              ],
            ),
          ),
        );
        continue;
      }

      // Paragraph thường
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: _richParagraph(trimmed.trim()),
        ),
      );
    }

    return widgets;
  }

  /// Rich text giống preview: **bold**, [[wiki]], [text](url)
  pw.Widget _richParagraph(String mdLine) {
    final spans = <pw.InlineSpan>[];
    final s = mdLine;
    var i = 0;

    while (i < s.length) {
      // Bold **...**
      if (s.startsWith('**', i)) {
        final end = s.indexOf('**', i + 2);
        if (end > i) {
          spans.add(
            pw.TextSpan(
              text: s.substring(i + 2, end),
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          );
          i = end + 2;
          continue;
        }
      }

      // Wiki [[PRO192]]
      if (s.startsWith('[[', i)) {
        final end = s.indexOf(']]', i + 2);
        if (end > i) {
          spans.add(
            pw.TextSpan(
              text: s.substring(i + 2, end),
              style: pw.TextStyle(
                color: _teal,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          i = end + 2;
          continue;
        }
      }

      // Markdown link [label](url)
      final link = RegExp(r'^\[([^\]]+)\]\(([^)]+)\)').matchAsPrefix(s, i);
      if (link != null) {
        spans.add(
          pw.TextSpan(
            text: link.group(1),
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFF2563EB),
              decoration: pw.TextDecoration.underline,
            ),
          ),
        );
        i = link.end;
        continue;
      }

      // Plain run until next special (or orphan char at i)
      final next = _nextSpecialIndex(s, i);
      if (next == i) {
        spans.add(
          pw.TextSpan(
            text: s[i],
            style: const pw.TextStyle(color: _ink),
          ),
        );
        i++;
      } else {
        spans.add(
          pw.TextSpan(
            text: s.substring(i, next),
            style: const pw.TextStyle(color: _ink),
          ),
        );
        i = next;
      }
    }

    if (spans.isEmpty) {
      return pw.Text(
        mdLine,
        style: const pw.TextStyle(color: _ink, fontSize: 9.5, height: 1.45),
      );
    }

    return pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(color: _ink, fontSize: 9.5, height: 1.45),
        children: spans,
      ),
    );
  }

  static int _nextSpecialIndex(String s, int from) {
    var best = s.length;
    for (final token in ['**', '[[', '[']) {
      final idx = s.indexOf(token, from);
      if (idx >= from && idx < best) best = idx;
    }
    return best;
  }

  List<pw.Widget> _contentSections(List<_MdSection> sections) {
    final out = <pw.Widget>[];
    const skip = {
      'thông tin chung',
      'mô tả môn học',
      'description',
      'đánh giá',
      'assessment',
    };
    for (final s in sections) {
      final key = s.title.toLowerCase();
      if (skip.any(key.contains)) continue;
      if (s.body.trim().isEmpty) continue;
      out.add(_sectionTitle(s.title, IconsStyle.book));
      out.add(pw.SizedBox(height: 8));
      out.addAll(_spanningBody(s.body));
      out.add(pw.SizedBox(height: 14));
    }
    return out;
  }

  // ─── Markdown helpers ──────────────────────────────────

  static String _stripFrontmatter(String raw) {
    final trimmed = raw.trimLeft();
    if (!trimmed.startsWith('---')) return raw;
    final end = trimmed.indexOf('\n---', 3);
    if (end < 0) return raw;
    return trimmed.substring(end + 4).trimLeft();
  }

  static List<_MdSection> _parseSections(String raw) {
    final body = _stripFrontmatter(raw);
    final lines = body.split(RegExp(r'\r?\n'));
    final sections = <_MdSection>[];
    String? currentTitle;
    final buf = StringBuffer();

    void flush() {
      final title = currentTitle;
      if (title == null) return;
      sections.add(_MdSection(title, buf.toString().trim()));
      buf.clear();
    }

    for (final line in lines) {
      final h2 = RegExp(r'^##\s+(.+)$').firstMatch(line);
      if (h2 != null) {
        flush();
        currentTitle = h2.group(1)!.trim();
        continue;
      }
      if (currentTitle != null) {
        buf.writeln(line);
      }
    }
    flush();
    return sections;
  }

  /// Chuẩn hóa nhẹ — không dùng r'$1' (Dart replaceAll không expand backref).
  static String _preprocessMarkdown(String text) {
    var t = text;
    t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    t = t.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);
    // Giữ **bold**, [[wiki]], [link](url) cho _richParagraph
    return t.trim();
  }
}

class _MdSection {
  final String title;
  final String body;
  _MdSection(this.title, this.body);
}

/// Placeholder cho icon style (chỉ semantic trong code).
enum IconsStyle { info, link, check, chart, book }

/// Helper gọi từ UI.
Future<void> exportCoursePdf(BuildContext context, NoteFile note) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Đang tạo PDF đề cương…'),
      duration: Duration(seconds: 2),
    ),
  );

  try {
    final path = await CoursePdfExporter().export(context, note);
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (path != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã lưu PDF: $path'),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã hủy tải PDF.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Lỗi xuất PDF: $e'),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }
}
