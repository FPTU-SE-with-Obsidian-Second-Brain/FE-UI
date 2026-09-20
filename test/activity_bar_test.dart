import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_app/providers/chat_provider.dart';
import 'package:obsidian_app/providers/note_provider.dart';
import 'package:obsidian_app/widgets/obsidian/obsidian_activity_bar.dart';
import 'package:obsidian_app/widgets/obsidian/obsidian_sidebar.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
    NoteProvider? noteProvider,
    ChatProvider? chatProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NoteProvider>(
          create: (_) => noteProvider ?? NoteProvider(),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => chatProvider ?? ChatProvider(),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('ObsidianActivityBar renders icons and triggers tab selection', (
    WidgetTester tester,
  ) async {
    ActivityTab selectedTab = ActivityTab.files;
    bool isFileTreeOpen = true;

    await tester.pumpWidget(
      buildTestWidget(
        child: StatefulBuilder(
          builder: (context, setState) {
            return ObsidianActivityBar(
              isFileTreeOpen: isFileTreeOpen,
              activeTab: selectedTab,
              onTabSelected: (tab) => setState(() => selectedTab = tab),
              onToggleFileTree: () =>
                  setState(() => isFileTreeOpen = !isFileTreeOpen),
              onOpenGraphView: () {},
            );
          },
        ),
      ),
    );

    // Verify activity bar width is 52
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints?.maxWidth ?? 52.0, 52.0);

    // Verify icons exist
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget); // Logo
    expect(find.byIcon(Icons.folder), findsOneWidget); // Files (active)
    expect(find.byIcon(Icons.search_rounded), findsOneWidget); // Search
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget); // Bookmarks
    expect(
      find.byIcon(Icons.bubble_chart_outlined),
      findsOneWidget,
    ); // Graph View
    expect(
      find.byIcon(Icons.auto_awesome_outlined),
      findsOneWidget,
    ); // AI Chatbot
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget); // Reload
    expect(
      find.byIcon(Icons.folder_open_outlined),
      findsNothing,
    ); // Open Folder removed to protect data integrity
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget); // Settings

    // Tap Search tab
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(selectedTab, ActivityTab.search);
  });

  testWidgets('ObsidianSidebar switches title and body per active tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(
        child: SizedBox(
          width: 285,
          child: ObsidianSidebar(
            activeTab: ActivityTab.search,
            onCollapse: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tìm kiếm ghi chú'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
