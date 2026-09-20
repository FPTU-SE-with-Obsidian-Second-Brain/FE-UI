import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_app/models/note_file.dart';
import 'package:obsidian_app/widgets/AI%20Chat/ai_chat_input_bar.dart';

void main() {
  final testNotes = <NoteFile>[
    NoteFile(
      path: 'd:/notes/PRM393.md',
      fileName: 'PRM393.md',
      title: 'PRM393',
      folderName: 'Kỳ 5',
      rawContent: '---\ncode: PRM393\n---\nMobile Programming',
      links: const [],
      lastModified: DateTime.now(),
    ),
    NoteFile(
      path: 'd:/notes/PRN212.md',
      fileName: 'PRN212.md',
      title: 'PRN212',
      folderName: 'Kỳ 5',
      rawContent: '---\ncode: PRN212\n---\nBasic Cross-Platform',
      links: const [],
      lastModified: DateTime.now(),
    ),
  ];

  testWidgets('AiChatInputBar autocomplete tag with Enter does not send chat', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String? sentText;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isLoading: false,
            onSend: (text) => sentText = text,
            suggestions: const [],
            showSuggestions: false,
            notes: testNotes,
          ),
        ),
      ),
    );

    // Gõ @prm
    await tester.enterText(find.byType(TextField), '@prm');
    await tester.pumpAndSettle();

    // Xác minh popup gợi ý hiện ra và có @PRM393
    expect(find.text('@PRM393'), findsOneWidget);
    expect(find.text('Enter để chọn ↵'), findsOneWidget);

    // Nhấn Enter để chọn môn
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // Xác minh: KHÔNG gửi tin nhắn, tag được chèn vào TextField
    expect(sentText, isNull);
    expect(controller.text, '@PRM393 ');

    // Gõ tiếp nội dung câu hỏi sau khi chọn môn
    await tester.enterText(find.byType(TextField), '@PRM393 môn này học gì?');
    await tester.pumpAndSettle();

    // Nhấn Enter lần này (khi không còn popup gợi ý) -> Gửi tin nhắn
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(sentText, '@PRM393 môn này học gì?');
  });

  testWidgets('AiChatInputBar autocomplete tag with Tab selects tag', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String? sentText;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isLoading: false,
            onSend: (text) => sentText = text,
            suggestions: const [],
            showSuggestions: false,
            notes: testNotes,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '@prn');
    await tester.pumpAndSettle();

    expect(find.text('@PRN212'), findsOneWidget);

    // Nhấn Tab để chọn
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(sentText, isNull);
    expect(controller.text, '@PRN212 ');
  });

  testWidgets('AiChatInputBar clicking suggestion with mouse selects tag and keeps focus', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String? sentText;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isLoading: false,
            onSend: (text) => sentText = text,
            suggestions: const [],
            showSuggestions: false,
            notes: testNotes,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '@prm');
    await tester.pumpAndSettle();

    expect(find.text('@PRM393'), findsOneWidget);

    // Nhấp chuột vào @PRM393
    await tester.tap(find.text('@PRM393'));
    await tester.pumpAndSettle();

    expect(sentText, isNull);
    expect(controller.text, '@PRM393 ');
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('AiChatInputBar renders leadingChips and left tools button on the left', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    bool toggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isLoading: false,
            onSend: (_) {},
            suggestions: const [],
            showSuggestions: false,
            notes: testNotes,
            isScopeActive: true,
            currentSubjectId: 'PRM393',
            onToggleScope: () => toggled = true,
            leadingChips: const Text('Filter Chip Left Sample'),
          ),
        ),
      ),
    );

    expect(find.text('Filter Chip Left Sample'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.text('PRM393'), findsOneWidget);

    // Mở popup menu công cụ bên trái
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Chỉ hỏi trong môn này (PRM393)'), findsOneWidget);
    await tester.tap(find.text('Chỉ hỏi trong môn này (PRM393)'));
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });
}
