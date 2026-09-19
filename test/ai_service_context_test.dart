import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obsidian_app/models/chat_request_context.dart';
import 'package:obsidian_app/services/ai_service.dart';
import 'package:obsidian_app/utils/note_frontmatter.dart';

void main() {
  group('AiService context (additive)', () {
    test('without context body only has question (legacy)', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.keys, ['question']);
        expect(body['question'], 'Hello');
        return http.Response(
          jsonEncode({'answer': 'Hi', 'sources': <String>[]}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result =
          await AiService().ask('Hello', client: mockClient);
      expect(result.isError, false);
      expect(result.text, 'Hi');
      expect(result.studyPlan, isNull);
    });

    test('with source_ids sends subject_focus fields', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['question'], 'Tóm tắt môn này');
        expect(body['source_ids'], ['DBA103']);
        expect(body['mode'], 'subject_focus');
        return http.Response(
          jsonEncode({
            'answer': 'Tóm tắt DBA103...',
            'sources': ['Kỳ 0/DBA103.md'],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await AiService().ask(
        'Tóm tắt môn này',
        context: const ChatRequestContext(
          sourceIds: ['DBA103'],
          mode: 'subject_focus',
          sourceFile: 'Kỳ 0/DBA103.md',
        ),
        client: mockClient,
      );
      expect(result.sources, ['Kỳ 0/DBA103.md']);
    });

    test('parses study_plan from response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'answer': 'Đã lập lộ trình.',
            'sources': ['BIT_SE_K19B.md'],
            'study_plan': {
              'current_semester': 3,
              'goal': 'AI Engineer',
              'semesters': [
                {
                  'semester': 3,
                  'label': 'Kỳ 3',
                  'courses': [
                    {
                      'code': 'CSD201',
                      'name': 'Data Structures',
                      'credits': 3,
                      'type': 'core',
                      'note': 'Nền tảng',
                    }
                  ],
                }
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await AiService().ask(
        'Lộ trình',
        context: const ChatRequestContext(
          mode: 'study_plan',
          currentSemester: 3,
          goal: 'AI Engineer',
        ),
        client: mockClient,
      );
      expect(result.studyPlan, isNotNull);
      expect(result.studyPlan!.goal, 'AI Engineer');
      expect(result.studyPlan!.semesters.first.courses.first.code, 'CSD201');
    });
  });

  group('note_frontmatter helpers', () {
    test('parse frontmatter id and tags', () {
      const raw = '''---
id: DBA103
type: subject
tags: [music, DBA103]
---

# Title
''';
      final fm = NoteFrontmatter.parse(raw);
      expect(fm.id, 'DBA103');
      expect(fm.type, 'subject');
      expect(fm.tags, contains('DBA103'));
    });

    test('parseAtTags extracts codes', () {
      expect(parseAtTags('Hỏi @PRM393 và @ite302c'), ['PRM393', 'ITE302c']);
    });

    test('normalizeSubjectCode', () {
      expect(normalizeSubjectCode('ite302c'), 'ITE302c');
      expect(normalizeSubjectCode('DBA103'), 'DBA103');
    });
  });
}
