import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/note_provider.dart';

enum ActivityTab { files, search, bookmarks, graph }

class ObsidianActivityBar extends StatelessWidget {
  final bool isFileTreeOpen;
  final ActivityTab activeTab;
  final ValueChanged<ActivityTab> onTabSelected;
  final VoidCallback onToggleFileTree;
  final VoidCallback onOpenGraphView;

  const ObsidianActivityBar({
    super.key,
    required this.isFileTreeOpen,
    required this.activeTab,
    required this.onTabSelected,
    required this.onToggleFileTree,
    required this.onOpenGraphView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatProvider = Provider.of<ChatProvider>(context);
    final noteProvider = Provider.of<NoteProvider>(context);

    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF121214), // Nền Ribbon tối phong cách Obsidian
        border: Border(
          right: BorderSide(color: theme.dividerColor.withAlpha(80), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Logo biểu tượng Obsidian Second Brain ở đầu thanh
          Tooltip(
            message: 'FPTU SE Second Brain',
            preferBelow: false,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withAlpha(90),
                    const Color(0xFFA855F7).withAlpha(50),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(120),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.hub_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            indent: 10,
            endIndent: 10,
            color: theme.dividerColor.withAlpha(70),
          ),
          const SizedBox(height: 8),

          // 1. Nút Cây thư mục (Files Explorer)
          _buildIconButton(
            context: context,
            icon: isFileTreeOpen && activeTab == ActivityTab.files
                ? Icons.folder
                : Icons.folder_outlined,
            tooltip: 'Tài liệu môn học (Files Explorer)',
            isActive: isFileTreeOpen && activeTab == ActivityTab.files,
            onPressed: () {
              if (isFileTreeOpen && activeTab == ActivityTab.files) {
                onToggleFileTree();
              } else {
                if (!isFileTreeOpen) onToggleFileTree();
                onTabSelected(ActivityTab.files);
              }
            },
          ),

          // 2. Nút Tìm kiếm (Search View)
          _buildIconButton(
            context: context,
            icon: Icons.search_rounded,
            tooltip: 'Tìm kiếm toàn văn (Search)',
            isActive: isFileTreeOpen && activeTab == ActivityTab.search,
            onPressed: () {
              if (isFileTreeOpen && activeTab == ActivityTab.search) {
                onToggleFileTree();
              } else {
                if (!isFileTreeOpen) onToggleFileTree();
                onTabSelected(ActivityTab.search);
              }
            },
          ),

          // 3. Nút Môn học trọng tâm (Bookmarks)
          _buildIconButton(
            context: context,
            icon: isFileTreeOpen && activeTab == ActivityTab.bookmarks
                ? Icons.bookmark
                : Icons.bookmark_outline,
            tooltip: 'Môn học trọng tâm & Đã ghim (Bookmarks)',
            isActive: isFileTreeOpen && activeTab == ActivityTab.bookmarks,
            accentColor: const Color(0xFFEAB308),
            onPressed: () {
              if (isFileTreeOpen && activeTab == ActivityTab.bookmarks) {
                onToggleFileTree();
              } else {
                if (!isFileTreeOpen) onToggleFileTree();
                onTabSelected(ActivityTab.bookmarks);
              }
            },
          ),

          // 4. Nút Đồ thị tri thức (Graph View - Phase 4)
          _buildIconButton(
            context: context,
            icon: Icons.bubble_chart_outlined,
            tooltip: 'Đồ thị tri thức (Graph View)',
            isActive: activeTab == ActivityTab.graph,
            badge: '4',
            onPressed: onOpenGraphView,
          ),

          // 5. Nút Trợ lý AI (RAG Chatbot)
          _buildIconButton(
            context: context,
            icon: chatProvider.isOpen
                ? Icons.auto_awesome
                : Icons.auto_awesome_outlined,
            tooltip: 'Trợ lý AI RAG Chatbot',
            isActive: chatProvider.isOpen,
            accentColor: const Color(0xFFA855F7),
            onPressed: () => chatProvider.toggleChat(),
          ),

          const Spacer(),

          // 6. Nút Quét lại thư mục (Reload Vault)
          _buildIconButton(
            context: context,
            icon: Icons.refresh_rounded,
            tooltip: 'Quét lại thư mục dữ liệu chuẩn',
            isActive: false,
            onPressed: () => noteProvider.init(),
          ),

          // 7. Cài đặt & Thống kê Vault
          _buildIconButton(
            context: context,
            icon: Icons.settings_outlined,
            tooltip: 'Cài đặt & Thống số Vault',
            isActive: false,
            onPressed: () => _showVaultStatsModal(context, noteProvider),
          ),

          // 9. Nút thu gọn / mở rộng Sidebar ở chân dải Ribbon
          _buildIconButton(
            context: context,
            icon: isFileTreeOpen
                ? Icons.keyboard_double_arrow_left_rounded
                : Icons.keyboard_double_arrow_right_rounded,
            tooltip: isFileTreeOpen
                ? 'Thu gọn thanh bên (Ctrl+B)'
                : 'Mở rộng thanh bên (Ctrl+B)',
            isActive: false,
            onPressed: onToggleFileTree,
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback? onPressed,
    Color? accentColor,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = accentColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Thanh gạch chỉ thị trạng thái active ở mép trái (Chuẩn Obsidian Left Ribbon)
            if (isActive)
              Positioned(
                left: 0,
                child: Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(150),
                        blurRadius: 4,
                        offset: const Offset(1, 0),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? primaryColor.withAlpha(35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? primaryColor
                      : theme.iconTheme.color?.withAlpha(190),
                ),
                onPressed: onPressed,
              ),
            ),
            if (badge != null)
              Positioned(
                top: 2,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showVaultStatsModal(BuildContext context, NoteProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.query_stats_rounded, color: Color(0xFF9333EA)),
            SizedBox(width: 10),
            Text(
              'Thông số Vault & Cài đặt',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(
                'Thư mục lưu trữ:',
                provider.currentFolderPath ?? 'Chưa chọn',
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                'Tổng số môn học/ghi chú:',
                '${provider.totalNotesCount} file .md',
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                'Tổng liên kết môn học:',
                '${provider.totalLinksCount} liên kết',
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                'Số kỳ học / thư mục:',
                '${provider.totalSemestersCount} thư mục',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
