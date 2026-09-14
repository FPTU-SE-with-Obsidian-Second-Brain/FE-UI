import 'package:flutter/material.dart';
import 'note_file.dart';

/// Mô tả một thành phần điểm trong bảng đánh giá môn học (Syllabus Assessment)
class AssessmentComponent {
  final String category; // Assignment, Lab, Practical Exam, Progress Test, Final Exam...
  final double weightPercent; // 20.0, 10.0, 30.0...
  final String criteria; // > 0 hoặc ≥ 4.0 / 10.0 (Điểm liệt)
  final String details; // N/A, trắc nghiệm, tự luận, số câu hỏi...
  final Color color;

  const AssessmentComponent({
    required this.category,
    required this.weightPercent,
    required this.criteria,
    required this.details,
    required this.color,
  });
}

/// Lớp trích xuất thông tin chi tiết của môn học từ file markdown
class CourseMetadata {
  final String code;
  final String name;
  final String credits;
  final List<String> prerequisites;
  final String passCriteria;
  final List<AssessmentComponent> assessments;
  final String description;

  CourseMetadata({
    required this.code,
    required this.name,
    required this.credits,
    required this.prerequisites,
    required this.passCriteria,
    required this.assessments,
    required this.description,
  });

  factory CourseMetadata.fromNote(NoteFile note) {
    final content = note.rawContent;

    // 1. Mã môn học
    final codeMatch = RegExp(
      r'\*\*Mã môn học[^*]*\*\*:\s*([^\n\r]+)',
      caseSensitive: false,
    ).firstMatch(content);
    final code =
        codeMatch?.group(1)?.trim() ?? note.fileName.replaceAll('.md', '');

    // 2. Tên môn học
    String name = note.title;
    final h1Match = RegExp(
      r'^#\s+([^\n\r]+)',
      multiLine: true,
    ).firstMatch(content);
    if (h1Match != null) {
      name = h1Match.group(1)!.trim();
    } else {
      final engMatch = RegExp(
        r'\*\*Tên tiếng Anh:\*\*\s*([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(content);
      if (engMatch != null) name = engMatch.group(1)!.trim();
    }

    // 3. Số tín chỉ
    final creditMatch = RegExp(
      r'(?:Số tín chỉ|NoCredit)[^:]*:\s*([0-9]+)',
      caseSensitive: false,
    ).firstMatch(content);
    final credits = creditMatch != null
        ? '${creditMatch.group(1)} tín chỉ'
        : '3 tín chỉ';

    // 4. Môn tiên quyết
    final prereq = note.links;

    // 5. Điều kiện cần để pass môn (Chuẩn học vụ FPTU & trích xuất nội dung)
    final passCriteriaList = <String>[
      '• Chuyên cần: Tham gia tối thiểu 80% số buổi học',
      '• Điểm tổng kết môn: GPA >= 5.0 / 10.0',
      '• Điểm thi cuối kỳ (FE / PE): >= 4.0 / 10.0 (Không bị điểm liệt)',
    ];

    // 6. Đánh giá chi tiết (Assessments & Weights %)
    final assessments = <AssessmentComponent>[];
    final assessSectionMatch = RegExp(
      r'##\s*(?:[0-9]+\.\s*)?Đánh giá[^\r\n]*\r?\n([\s\S]*?)(?=(?:\r?\n##)|$)',
      caseSensitive: false,
    ).firstMatch(content);

    if (assessSectionMatch != null) {
      final lines = assessSectionMatch.group(1)!.split(RegExp(r'\r?\n'));
      for (final rawLine in lines) {
        final clean = rawLine.replaceAll(RegExp(r'^[-*]\s*'), '').trim();
        if (clean.isEmpty || !clean.contains('%')) continue;

        final pctMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*%').firstMatch(clean);
        if (pctMatch != null) {
          final weight = double.tryParse(pctMatch.group(1)!) ?? 0.0;

          // Tên loại đánh giá (nằm trước dấu % hoặc dấu :)
          var category = clean
              .substring(0, pctMatch.start)
              .replaceAll('**', '')
              .replaceAll(':', '')
              .replaceAll('-', '')
              .trim();
          if (category.isEmpty) category = 'Thành phần đánh giá';

          // Ghi chú / Chi tiết phụ (nằm sau %)
          var details = clean
              .substring(pctMatch.end)
              .replaceAll('**', '')
              .trim();
          details = details.replaceAll(RegExp(r'^[()]|[()]$'), '').trim();

          // Xác định điều kiện theo chuẩn FLM FPTU (Hình thức thi & Điểm liệt)
          final isFinal =
              category.toLowerCase().contains('final') ||
              category.toLowerCase().contains('fe') ||
              category.toLowerCase().contains('cuối kỳ');
          final criteria = isFinal ? '≥ 4.0 (Điểm liệt)' : '> 0 (Bắt buộc)';

          // Bảng màu trực quan Obsidian
          Color color;
          final catLower = category.toLowerCase();
          if (catLower.contains('assign')) {
            color = const Color(0xFF38BDF8); // Cyan - Assignment
          } else if (catLower.contains('lab') ||
              catLower.contains('workshop')) {
            color = const Color(0xFF34D399); // Emerald - Lab/Workshop
          } else if (catLower.contains('practical') ||
              catLower.contains('pe')) {
            color = const Color(0xFFA855F7); // Purple - PE
          } else if (catLower.contains('progress') ||
              catLower.contains('pt') ||
              catLower.contains('quiz')) {
            color = const Color(0xFFFBBF24); // Amber - Progress Test
          } else if (catLower.contains('final') ||
              catLower.contains('fe') ||
              catLower.contains('exam')) {
            color = const Color(0xFFF43F5E); // Rose Red - Final Exam
          } else {
            color = const Color(0xFF818CF8); // Indigo
          }

          assessments.add(
            AssessmentComponent(
              category: category,
              weightPercent: weight,
              criteria: criteria,
              details: details,
              color: color,
            ),
          );
        }
      }
    }

    if (assessments.isEmpty) {
      assessments.addAll([
        const AssessmentComponent(
          category: 'Assignment',
          weightPercent: 20.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Bài tập lớn & đồ án',
          color: Color(0xFF38BDF8),
        ),
        const AssessmentComponent(
          category: 'Lab / Workshop',
          weightPercent: 10.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Thực hành trên lớp',
          color: Color(0xFF34D399),
        ),
        const AssessmentComponent(
          category: 'Practical Exam (PE)',
          weightPercent: 30.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Thi thực hành máy tính',
          color: Color(0xFFA855F7),
        ),
        const AssessmentComponent(
          category: 'Progress Test (PT)',
          weightPercent: 10.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Kiểm tra tiến độ định kỳ',
          color: Color(0xFFFBBF24),
        ),
        const AssessmentComponent(
          category: 'Final Exam (FE)',
          weightPercent: 30.0,
          criteria: '≥ 4.0 (Điểm liệt)',
          details: 'Thi kết thúc môn học',
          color: Color(0xFFF43F5E),
        ),
      ]);
    }

    // 7. Mô tả môn học (Lấy đầy đủ nội dung, không cắt ngắn)
    String desc = '';
    final descMatch = RegExp(
      r'##\s*(?:[0-9]+\.\s*)?(?:Mô tả môn học|Description)[^\r\n]*\r?\n([\s\S]*?)(?=(?:\r?\n##)|$)',
      caseSensitive: false,
    ).firstMatch(content);
    if (descMatch != null) {
      final rawLines = descMatch.group(1)!.split(RegExp(r'\r?\n'));
      final cleanedLines = <String>[];
      for (var l in rawLines) {
        l = l
            .replaceAll(RegExp(r'^[0-9]+\.\s*[-*]?\s*'), '')
            .replaceAll(RegExp(r'^[-*]\s*'), '')
            .trim();
        if (l.isNotEmpty) {
          cleanedLines.add(l);
        }
      }
      if (cleanedLines.length > 1) {
        desc = cleanedLines.map((e) => '• $e').join('\n\n');
      } else if (cleanedLines.isNotEmpty) {
        desc = cleanedLines.first;
      }
    }

    return CourseMetadata(
      code: code,
      name: name,
      credits: credits,
      prerequisites: prereq,
      passCriteria: passCriteriaList.join('\n'),
      assessments: assessments,
      description: desc,
    );
  }
}
