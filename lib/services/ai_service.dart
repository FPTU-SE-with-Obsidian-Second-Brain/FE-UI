import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class AiService {
  final String baseUrl;

  AiService({this.baseUrl = 'http://127.0.0.1:8000'});

  /// Gửi câu hỏi tới endpoint POST /chat của Backend Python RAG
  Future<ChatMessage> ask(String question, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$baseUrl/chat');

    try {
      final response = await httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'question': question}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final answer = data['answer'] as String? ?? 'Không có câu trả lời.';
        final rawSources = data['sources'] as List<dynamic>? ?? [];
        final sources = rawSources.map((s) => s.toString()).toList();

        return ChatMessage.ai(answer, sources: sources);
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
        '⚠️ Quá thời gian chờ phản hồi từ AI Server (Timeout 30s). Vui lòng thử lại.',
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
