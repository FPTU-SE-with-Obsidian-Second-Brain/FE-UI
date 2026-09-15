import 'package:flutter/material.dart';
import 'file_tree_view.dart';
import 'obsidian_activity_bar.dart';
import 'obsidian_bookmarks_view.dart';
import 'obsidian_search_view.dart';

class ObsidianSidebar extends StatelessWidget {
  final ActivityTab activeTab;
  final VoidCallback onCollapse;

  const ObsidianSidebar({
    super.key,
    required this.activeTab,
    required this.onCollapse,
  });

  String _getTabTitle() {
    switch (activeTab) {
      case ActivityTab.files:
        return 'Tài liệu môn học';
      case ActivityTab.search:
        return 'Tìm kiếm ghi chú';
      case ActivityTab.bookmarks:
        return 'Môn học trọng tâm';
      case ActivityTab.graph:
        return 'Đồ thị tri thức';
    }
  }

  IconData _getTabIcon() {
    switch (activeTab) {
      case ActivityTab.files:
        return Icons.folder_outlined;
      case ActivityTab.search:
        return Icons.search_rounded;
      case ActivityTab.bookmarks:
        return Icons.bookmark_outline;
      case ActivityTab.graph:
        return Icons.bubble_chart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: const Color(0xFF161619), // Nền Sidebar tối phong cách Obsidian
      child: Column(
        children: [
          // Header của Sidebar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withAlpha(70), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(_getTabIcon(), size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTabTitle(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Nút thu gọn Sidebar (Collapse)
                Tooltip(
                  message: 'Thu gọn thanh bên (Ctrl+B)',
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(Icons.chevron_left, size: 20, color: theme.hintColor),
                    onPressed: onCollapse,
                  ),
                ),
              ],
            ),
          ),

          // Nội dung Sidebar thay đổi linh hoạt theo Tab
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _buildTabBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (activeTab) {
      case ActivityTab.files:
        return const FileTreeView(key: ValueKey('tab_files'));
      case ActivityTab.search:
        return const ObsidianSearchView(key: ValueKey('tab_search'));
      case ActivityTab.bookmarks:
        return const ObsidianBookmarksView(key: ValueKey('tab_bookmarks'));
      case ActivityTab.graph:
        return const Center(
          child: Text('Đang hiển thị Graph View...'),
        );
    }
  }
}
