import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/chat_request_context.dart';
import '../models/study_plan.dart';

class AiService {
  final String baseUrl;

  AiService({this.baseUrl = 'http://127.0.0.1:8000'});

  /// Gửi câu hỏi tới endpoint POST /chat của Backend Python RAG.
  /// Khi [context] null hoặc không có field phụ → body chỉ `question` (luồng cũ).
  Future<ChatMessage> ask(
    String question, {
    ChatRequestContext? context,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$baseUrl/chat');

    try {
      final body = <String, dynamic>{'question': question};
      if (context != null) {
        body.addAll(context.toJsonFields());
      }

      final response = await httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final answer = data['answer'] as String? ?? 'Không có câu trả lời.';
        final rawSources = data['sources'] as List<dynamic>? ?? [];
        final sources = rawSources.map((s) => s.toString()).toList();

        StudyPlan? studyPlan;
        final rawPlan = data['study_plan'];
        if (rawPlan is Map<String, dynamic>) {
          studyPlan = StudyPlan.fromJson(rawPlan);
        } else if (rawPlan is Map) {
          studyPlan = StudyPlan.fromJson(Map<String, dynamic>.from(rawPlan));
        }

        return ChatMessage.ai(answer, sources: sources, studyPlan: studyPlan);
      } else {
        return ChatMessage.error(
          'Lỗi từ AI Server (Mã lỗi ${response.statusCode}): ${response.body}',
        );
      }
    } on SocketException {
      return ChatMessage.error(
        '⚠️ Không thể kết nối tới Backend AI tại $baseUrl.\n\n'
        'Hãy chắc chắn rằng bạn đã khởi động Server Python bằng lệnh:\n'
        '```powershell\n'
        'uvicorn main:app --reload --port 8000\n'
        '```',
      );
    } on http.ClientException catch (e) {
      return ChatMessage.error(
        '⚠️ Lỗi kết nối mạng: ${e.message}.\n'
        'Vui lòng kiểm tra xem Backend AI tại $baseUrl có đang chạy không.',
      );
    } on TimeoutException {
      return ChatMessage.error(
        '⚠️ Quá thời gian chờ phản hồi từ AI Server (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      return ChatMessage.error('Đã xảy ra lỗi không xác định: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
