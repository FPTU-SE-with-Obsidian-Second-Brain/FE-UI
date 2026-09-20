import 'package:html/parser.dart' as html_parser;

class MarkdownTableConverter {
  /// Dọn dẹp thẻ HTML nội dòng (chuyển b->**, i->*, dọn b rỗng, đổi * đầu dòng thành •, giải mã entity)
  static String cleanHtmlFormatting(String html) {
    var text = html;

    // 1. Chuẩn hóa thẻ <br>
    text = text.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '<br>');

    // 2. Xóa các cặp thẻ rỗng: <b></b>, <strong></strong>, <i></i>, <em></em>
    text = text.replaceAll(
      RegExp(r'<(b|strong|i|em|u|span|p|div)\b[^>]*>\s*<\/\1>', caseSensitive: false),
      '',
    );

    // 3. Chuyển đổi cặp thẻ <b>...</b> và <strong>...</strong> có nội dung sang **...**
    text = text.replaceAllMapped(
      RegExp(r'<(b|strong)\b[^>]*>(.*?)<\/\1>', caseSensitive: false, dotAll: true),
      (match) {
        final inner = match.group(2)?.trim() ?? '';
        return inner.isEmpty ? '' : '**$inner**';
      },
    );

    // 4. Chuyển đổi cặp thẻ <i>...</i> và <em>...</em> có nội dung sang *...*
    text = text.replaceAllMapped(
      RegExp(r'<(i|em)\b[^>]*>(.*?)<\/\1>', caseSensitive: false, dotAll: true),
      (match) {
        final inner = match.group(2)?.trim() ?? '';
        return inner.isEmpty ? '' : '*$inner*';
      },
    );

    // 5. Bỏ các thẻ còn sót lại như <span>, <div>, <u>, <font>, <p>, <b> lẻ (dùng \b để không xóa <br>)
    text = text.replaceAll(
      RegExp(r'<\/?(span|div|u|font|p|b|strong|i|em)\b[^>]*>', caseSensitive: false),
      '',
    );

    // 6. Xóa các chuỗi **** rỗng nếu còn sót
    text = text.replaceAll('****', '');

    // 7. Chuyển đổi các dấu đầu dòng dạng "* " hoặc "<br>* " thành bullet "• " chuyên nghiệp
    text = text.replaceAllMapped(
      RegExp(r'(^|<br\s*\/?>)\s*\*\s+', caseSensitive: false),
      (match) => '${match.group(1)}• ',
    );

    // 8. Bỏ xuống dòng thô để tránh vỡ cấu trúc bảng Markdown
    text = text.replaceAll('\r', '').replaceAll('\n', ' ');

    // 9. Escape ký tự pipe |
    text = text.replaceAll('|', '\\|');

    // 10. Giải mã các entity phổ biến
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');

    return text.trim();
  }

  /// Chuyển đổi các thẻ <table>...</table> dạng HTML sang Markdown Table chuẩn (GFM)
  static String convertHtmlTablesToMarkdown(String raw) {
    if (!raw.contains('<table')) return raw;

    final tableRegex = RegExp(r'<table[\s\S]*?<\/table>', caseSensitive: false);

    return raw.replaceAllMapped(tableRegex, (match) {
      final tableHtml = match.group(0)!;
      try {
        final doc = html_parser.parseFragment(tableHtml);
        final table = doc.querySelector('table');
        if (table == null) return tableHtml;

        final rows = table.querySelectorAll('tr');
        if (rows.isEmpty) return '';

        final List<List<String>> tableData = [];
        int maxCols = 0;
        bool hasExplicitHeaders = false;

        for (final row in rows) {
          final cells = row.querySelectorAll('th, td');
          if (cells.isEmpty) continue;

          if (row.querySelector('th') != null) {
            hasExplicitHeaders = true;
          }

          final rowData = cells.map((cell) => cleanHtmlFormatting(cell.innerHtml)).toList();

          if (rowData.length > maxCols) {
            maxCols = rowData.length;
          }
          tableData.add(rowData);
        }

        if (tableData.isEmpty || maxCols == 0) return '';

        // Đồng bộ số cột cho tất cả các hàng
        for (final row in tableData) {
          while (row.length < maxCols) {
            row.add('');
          }
        }

        final StringBuffer sb = StringBuffer();
        sb.writeln();

        if (hasExplicitHeaders) {
          final header = tableData[0];
          sb.writeln('| ${header.join(' | ')} |');
          sb.writeln('| ${List.filled(maxCols, '---').join(' | ')} |');
          for (int i = 1; i < tableData.length; i++) {
            sb.writeln('| ${tableData[i].join(' | ')} |');
          }
        } else {
          // Nếu bảng dạng 2 cột không có thẻ <th> (như bảng Syllabus Details)
          if (maxCols == 2) {
            sb.writeln('| Thông tin | Nội dung chi tiết |');
            sb.writeln('| --- | --- |');
            for (final row in tableData) {
              sb.writeln('| ${row.join(' | ')} |');
            }
          } else {
            final header = tableData[0];
            sb.writeln('| ${header.join(' | ')} |');
            sb.writeln('| ${List.filled(maxCols, '---').join(' | ')} |');
            for (int i = 1; i < tableData.length; i++) {
              sb.writeln('| ${tableData[i].join(' | ')} |');
            }
          }
        }
        sb.writeln();
        return sb.toString();
      } catch (e) {
        return tableHtml;
      }
    });
  }

  /// Dọn dẹp toàn bộ thẻ HTML còn sót lại cả trong và ngoài bảng
  static String cleanAllHtml(String raw) {
    var result = convertHtmlTablesToMarkdown(raw);

    // 1. Xóa các cặp thẻ rỗng ngoài bảng
    result = result.replaceAll(
      RegExp(r'<(b|strong|i|em|u|span|p|div)\b[^>]*>\s*<\/\1>', caseSensitive: false),
      '',
    );

    // 2. Chuyển đổi các thẻ <b>, <strong> ngoài bảng
    result = result.replaceAllMapped(
      RegExp(r'<(b|strong)\b[^>]*>(.*?)<\/\1>', caseSensitive: false, dotAll: true),
      (match) {
        final inner = match.group(2)?.trim() ?? '';
        return inner.isEmpty ? '' : '**$inner**';
      },
    );

    // 3. Chuyển đổi các thẻ <i>, <em> ngoài bảng
    result = result.replaceAllMapped(
      RegExp(r'<(i|em)\b[^>]*>(.*?)<\/\1>', caseSensitive: false, dotAll: true),
      (match) {
        final inner = match.group(2)?.trim() ?? '';
        return inner.isEmpty ? '' : '*$inner*';
      },
    );

    // 4. Bỏ các thẻ còn sót lại
    result = result.replaceAll(
      RegExp(r'<\/?(span|div|u|font|p|b|strong|i|em)\b[^>]*>', caseSensitive: false),
      '',
    );

    // 5. Xóa chuỗi **** rỗng
    result = result.replaceAll('****', '');

    // 6. Chuyển đổi các dấu đầu dòng "* " ngoài bảng thành "• "
    result = result.replaceAllMapped(
      RegExp(r'(^|\n)\s*\*\s+'),
      (match) => '${match.group(1)}• ',
    );

    // 7. Giải mã entities
    result = result
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');

    return result;
  }

  /// Chuyển đổi liên kết hai chiều [[Page]] hoặc [[Page|Alias]] sang dạng markdown link chuẩn [Alias](Page)
  /// Giúp giao diện Markdown hiển thị gọn gàng không bị dính ký tự [[ ]] và vẫn click chuyển trang mượt mà.
  static String formatWikiLinks(String content) {
    return content.replaceAllMapped(
      RegExp(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]'),
      (match) {
        final target = match.group(1)!.trim();
        final alias = match.group(2)?.trim();
        final display = (alias != null && alias.isNotEmpty) ? alias : target;
        return '[$display]($target)';
      },
    );
  }
}
