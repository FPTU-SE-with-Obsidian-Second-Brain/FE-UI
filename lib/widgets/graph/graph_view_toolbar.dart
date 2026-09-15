import 'package:flutter/material.dart';

/// Thanh công cụ phía trên (Floating Toolbar) của cửa sổ Graph View 3D
class GraphViewToolbar extends StatelessWidget {
  final int nodeCount;
  final int edgeCount;
  final bool autoRotate;
  final bool showLabels;
  final bool colorBySemester;
  final bool isNodeSelected;
  final VoidCallback onToggleAutoRotate;
  final VoidCallback onToggleShowLabels;
  final VoidCallback onToggleColorBySemester;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetCamera;
  final VoidCallback onClose;

  const GraphViewToolbar({
    super.key,
    required this.nodeCount,
    required this.edgeCount,
    required this.autoRotate,
    required this.showLabels,
    required this.colorBySemester,
    required this.isNodeSelected,
    required this.onToggleAutoRotate,
    required this.onToggleShowLabels,
    required this.onToggleColorBySemester,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetCamera,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Tiêu đề + Badge đếm số môn & liên kết
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B).withAlpha(220),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hub_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Graph View — Mạng Lưới Tri Thức 3D',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$nodeCount môn • $edgeCount liên kết',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Bộ nút điều khiển chức năng (Buttons)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B).withAlpha(220),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: autoRotate ? 'Dừng tự xoay' : 'Bật tự động xoay 3D',
                    icon: Icon(
                      autoRotate ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 18,
                      color: autoRotate ? colorScheme.primary : Colors.grey,
                    ),
                    onPressed: onToggleAutoRotate,
                  ),
                  IconButton(
                    tooltip: showLabels ? 'Ẩn tất cả tên môn' : 'Hiện tất cả tên môn',
                    icon: Icon(
                      showLabels ? Icons.label : Icons.label_outline,
                      size: 18,
                      color: showLabels ? colorScheme.primary : Colors.grey,
                    ),
                    onPressed: onToggleShowLabels,
                  ),
                  IconButton(
                    tooltip: colorBySemester ? 'Chế độ Trắng xám Obsidian' : 'Màu theo học kỳ',
                    icon: Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: colorBySemester ? const Color(0xFFA855F7) : Colors.grey,
                    ),
                    onPressed: onToggleColorBySemester,
                  ),
                  IconButton(
                    tooltip: 'Phóng to (+)',
                    icon: const Icon(Icons.zoom_in, size: 18),
                    onPressed: onZoomIn,
                  ),
                  IconButton(
                    tooltip: 'Thu nhỏ (-)',
                    icon: const Icon(Icons.zoom_out, size: 18),
                    onPressed: onZoomOut,
                  ),
                  IconButton(
                    tooltip: 'Đặt lại góc nhìn',
                    icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
                    onPressed: onResetCamera,
                  ),
                ],
              ),
            ),
            if (!isNodeSelected) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B).withAlpha(220),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
