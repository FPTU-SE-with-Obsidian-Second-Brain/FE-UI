import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obsidian_app/services/ai_service.dart';

void main() {
  group('AiService Tests', () {
    test('AiService parses 200 OK response with answer and sources successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/chat');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['question'], 'Mon MLN111 hoc ve nhung noi dung gi?');

        return http.Response(
          jsonEncode({
            'answer': 'Mon MLN111 bao gom cac kien thuc ve Triet hoc Mac - Lenin...',
            'sources': ['MLN111.md'],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AiService();
      final result = await service.ask('Mon MLN111 hoc ve nhung noi dung gi?', client: mockClient);

      expect(result.isUser, false);
      expect(result.isError, false);
      expect(result.text, 'Mon MLN111 bao gom cac kien thuc ve Triet hoc Mac - Lenin...');
      expect(result.sources, ['MLN111.md']);
    });

    test('AiService returns user-friendly error when server returns 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = AiService();
      final result = await service.ask('Test question', client: mockClient);

      expect(result.isError, true);
      expect(result.text.contains('500'), true);
    });
  });
}
