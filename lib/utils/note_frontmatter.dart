/// Parse YAML-like Obsidian frontmatter (`---` ... `---`) without a heavy YAML package.
class NoteFrontmatter {
  final String? id;
  final String? type;
  final List<String> tags;

  const NoteFrontmatter({this.id, this.type, this.tags = const []});

  bool get isSubject =>
      (type ?? '').toLowerCase() == 'subject' || (id != null && id!.isNotEmpty);

  static NoteFrontmatter parse(String rawContent) {
    final trimmed = rawContent.trimLeft();
    if (!trimmed.startsWith('---')) {
      return const NoteFrontmatter();
    }
    final end = trimmed.indexOf('\n---', 3);
    if (end < 0) return const NoteFrontmatter();

    final block = trimmed.substring(3, end).trim();
    String? id;
    String? type;
    final tags = <String>[];

    for (final line in block.split('\n')) {
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final key = line.substring(0, colon).trim().toLowerCase();
      var value = line.substring(colon + 1).trim();
      if (value.startsWith('[') && value.endsWith(']')) {
        final inner = value.substring(1, value.length - 1);
        final parts = inner
            .split(',')
            .map((e) => e.trim().replaceAll(RegExp(r'''^["']|["']$'''), ''))
            .where((e) => e.isNotEmpty)
            .toList();
        if (key == 'tags') {
          tags.addAll(parts);
        }
        continue;
      }
      value = value.replaceAll(RegExp(r'''^["']|["']$'''), '');
      if (key == 'id') id = value;
      if (key == 'type') type = value;
      if (key == 'tags' && value.isNotEmpty) tags.add(value);
    }

    return NoteFrontmatter(id: id, type: type, tags: tags);
  }
}

/// Resolve subject / source_id for RAG: frontmatter.id → CourseMetadata-like code → filename.
String resolveSubjectId({
  required String rawContent,
  required String fileName,
  String? bodyCode,
}) {
  final fm = NoteFrontmatter.parse(rawContent);
  if (fm.id != null && fm.id!.trim().isNotEmpty) {
    return normalizeSubjectCode(fm.id!);
  }
  if (bodyCode != null && bodyCode.trim().isNotEmpty) {
    return normalizeSubjectCode(bodyCode);
  }
  final base = fileName.replaceAll(RegExp(r'\.md$', caseSensitive: false), '');
  return normalizeSubjectCode(base);
}

String normalizeSubjectCode(String code) {
  final match = RegExp(r'([a-zA-Z]+)(\d+)([a-zA-Z]?)').firstMatch(code.trim());
  if (match == null) return code.trim();
  return '${match.group(1)!.toUpperCase()}${match.group(2)}${match.group(3)!.toLowerCase()}';
}

/// Parse @Tag mentions like @PRM393 / @ITE302c from chat text.
List<String> parseAtTags(String text) {
  final matches = RegExp(
    r'\B@([A-Za-z]{2,5}\d{2,3}[A-Za-z]?)',
  ).allMatches(text);
  final codes = <String>{};
  for (final m in matches) {
    codes.add(normalizeSubjectCode(m.group(1)!));
  }
  return codes.toList();
}
