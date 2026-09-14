import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/note_provider.dart';
import '../widgets/ai_chat_panel.dart';
import '../widgets/graph_view_dialog.dart';
import '../widgets/markdown_viewer.dart';
import '../widgets/obsidian_activity_bar.dart';
import '../widgets/obsidian_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFileTreeOpen = true;
  ActivityTab _activeTab = ActivityTab.files;

  void _toggleSidebar() {
    setState(() => _isFileTreeOpen = !_isFileTreeOpen);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): _toggleSidebar,
      },
      child: Focus(
        autofocus: true,
        child: Consumer2<NoteProvider, ChatProvider>(
          builder: (context, noteProvider, chatProvider, _) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: const Color(0xFF141416),
                titleSpacing: 16,
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'FPTU SE Second Brain',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (noteProvider.currentFolderPath != null)
                            Text(
                              'Vault: ${noteProvider.currentFolderPath}',
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (noteProvider.notes.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${noteProvider.notes.length} môn học/tài liệu',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                  // Nút bật/tắt Trợ lý AI trên AppBar
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: chatProvider.isOpen
                            ? colorScheme.primaryContainer
                            : colorScheme.primary,
                        foregroundColor: chatProvider.isOpen
                            ? colorScheme.onPrimaryContainer
                            : Colors.white,
                      ),
                      onPressed: () => chatProvider.toggleChat(),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(chatProvider.isOpen ? 'Đóng AI' : '🤖 Trợ lý AI'),
                    ),
                  ),
                ],
              ),
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Thanh điều hướng Ribbon phong cách Obsidian (52px)
                  ObsidianActivityBar(
                    isFileTreeOpen: _isFileTreeOpen,
                    activeTab: _activeTab,
                    onTabSelected: (tab) {
                      setState(() => _activeTab = tab);
                    },
                    onToggleFileTree: _toggleSidebar,
                    onOpenGraphView: () {
                      showDialog(
                        context: context,
                        builder: (_) => const GraphViewDialog(),
                      );
                    },
                  ),

                  // 2. Cột thanh bên động theo tab (285px, có thể thu gọn / mở rộng)
                  if (_isFileTreeOpen) ...[
                    SizedBox(
                      width: 285,
                      child: ObsidianSidebar(
                        activeTab: _activeTab,
                        onCollapse: () => setState(() => _isFileTreeOpen = false),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.dividerColor.withAlpha(80),
                    ),
                  ],

                  // 3. Màn hình đọc Markdown chính (chiếm toàn bộ không gian còn lại)
                  const Expanded(
                    child: MarkdownViewer(),
                  ),

                  // 4. Khung Chat AI RAG ở cạnh phải khi được kích hoạt
                  if (chatProvider.isOpen) const AiChatPanel(),
                ],
              ),

              // Nút tròn nổi mở AI Chat khi khung đang đóng
              floatingActionButton: chatProvider.isOpen
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: () => chatProvider.openChat(),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Hỏi AI RAG'),
                    ),
            );
          },
        ),
      ),
    );
  }
}
