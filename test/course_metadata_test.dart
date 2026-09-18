import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_app/models/note_file.dart';
import 'package:obsidian_app/widgets/graph/graph_view_dialog.dart';

void main() {
  group('CourseMetadata Tests', () {
    const samplePro192Content = '''---
id: PRO192
type: subject
tags: [Object-Oriented Programming, PRO192]
---

# Object-Oriented Programming_Lập trình hướng đối tượng

## 1. Thông tin chung
- **Mã môn học (Subject Code):** PRO192
- **Tên tiếng Anh:** Object-Oriented Programming
- **Số tín chỉ (NoCredit):** 3
- **Môn tiên quyết (Pre-Requisite):** [[Pass PRF192]]

## 2. Mô tả môn học (Description)
1. -This subject introduces the student to object-oriented programming. The student learns to build reusable objects, encapsulate data and logic within a class, inherit one class from another and implement polymorphism.
2. - Compose technical documentation of a Java program using internal comments
3. - Adhere to object-oriented programming principles including encapsulation, polymorphism and inheritance when writing program code
4. - Trace the execution of Java program logic to determine what a program does or to validate the correctness of a program

## 7. Đánh giá (Assessments)
- **Assignment:** 20.0% (N/A)
- **Lab:** 10.0% (N/A)
- **Practical Exam:** 30.0%
- **Progress Test:** 10.0%
- **Final Exam:** 30.0% (Multiple choices)
''';

    test(
      'CourseMetadata extracts full description and all 5 assessments without truncation',
      () {
        final note = NoteFile(
          path: 'dummy/PRO192.md',
          fileName: 'PRO192.md',
          title: 'PRO192',
          folderName: 'Kỳ 2',
          rawContent: samplePro192Content,
          links: ['Pass PRF192'],
          lastModified: DateTime.now(),
        );

        final meta = CourseMetadata.fromNote(note);

        expect(meta.code, 'PRO192');
        expect(meta.credits, '3 tín chỉ');

        // Description must not be truncated to 200 chars
        expect(meta.description.length, greaterThan(250));
        expect(meta.description.contains('This subject introduces'), isTrue);
        expect(
          meta.description.contains('Compose technical documentation'),
          isTrue,
        );
        expect(meta.description.contains('Trace the execution'), isTrue);

        // Assessments must have 5 components with correct percentages
        expect(meta.assessments.length, 5);

        final as = meta.assessments.firstWhere(
          (a) => a.category.contains('Assignment'),
        );
        expect(as.weightPercent, 20.0);
        expect(as.criteria, contains('> 0'));

        final lab = meta.assessments.firstWhere(
          (a) => a.category.contains('Lab'),
        );
        expect(lab.weightPercent, 10.0);
        expect(lab.criteria, contains('> 0'));

        final pe = meta.assessments.firstWhere(
          (a) => a.category.contains('Practical'),
        );
        expect(pe.weightPercent, 30.0);

        final pt = meta.assessments.firstWhere(
          (a) => a.category.contains('Progress'),
        );
        expect(pt.weightPercent, 10.0);

        final fe = meta.assessments.firstWhere(
          (a) => a.category.contains('Final'),
        );
        expect(fe.weightPercent, 30.0);
        expect(fe.criteria, contains('4.0'));
      },
    );
  });
}
