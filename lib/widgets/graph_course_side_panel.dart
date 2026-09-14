import 'package:flutter/material.dart';
import '../models/course_metadata.dart';
import '../models/graph_node_3d.dart';
import '../models/note_file.dart';

/// Widget thanh bên cạnh (Side Panel) hiển thị thông tin chi tiết môn học trên đồ thị 3D
class GraphCourseSidePanel extends StatefulWidget {
  final GraphNode3D node;
  final Map<String, GraphNode3D> nodeMap;
  final VoidCallback onClose;
  final ValueChanged<GraphNode3D> onSelectPrerequisite;
  final ValueChanged<NoteFile> onViewDetails;

  const GraphCourseSidePanel({
    super.key,
    required this.node,
    required this.nodeMap,
    required this.onClose,
    required this.onSelectPrerequisite,
    required this.onViewDetails,
  });

  @override
  State<GraphCourseSidePanel> createState() => _GraphCourseSidePanelState();
}

class _GraphCourseSidePanelState extends State<GraphCourseSidePanel> {
  bool _isDescExpanded = false;

  @override
  void didUpdateWidget(covariant GraphCourseSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node != widget.node) {
      _isDescExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final meta = CourseMetadata.fromNote(widget.node.note);

    return Container(
      color: const Color(0xFF141418), // Nền than chì sang trọng
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header của thanh bên cạnh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withAlpha(80),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.node.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meta.code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.node.note.folderName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Đóng thanh thông tin',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Nội dung cuộn thông tin chi tiết
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Tên đầy đủ môn học
                Text(
                  meta.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Thẻ số tín chỉ & Học kỳ
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(
                            60,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 18,
                              color: Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Số tín chỉ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  meta.credits,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(
                            60,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hub_outlined,
                              size: 18,
                              color: Color(0xFFA855F7),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Liên kết',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${widget.node.degree} môn',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. ĐIỀU KIỆN CẦN ĐỂ PASS MÔN
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withAlpha(90),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 16,
                            color: Color(0xFF22C55E),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ĐIỀU KIỆN ĐỂ PASS MÔN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22C55E),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meta.passCriteria,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. BẢNG THÀNH PHẦN ĐIỂM & TỶ TRỌNG (%)
                if (meta.assessments.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'THÀNH PHẦN ĐIỂM & TỶ TRỌNG (%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tổng: ${meta.assessments.fold<double>(0.0, (sum, i) => sum + i.weightPercent).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Thanh phân bổ tỷ trọng màu trực quan
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: meta.assessments.map((item) {
                          final flex = (item.weightPercent * 10).round().clamp(
                            1,
                            1000,
                          );
                          return Expanded(
                            flex: flex,
                            child: Container(
                              color: item.color,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Danh sách các hàng thành phần điểm
                  Column(
                    children: meta.assessments.map((comp) {
                      final isFinal = comp.criteria.contains('4.0');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(
                            35,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: comp.color.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: comp.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comp.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (comp.details.isNotEmpty &&
                                      comp.details.toLowerCase() != 'n/a')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        comp.details,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: theme.hintColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Badge điều kiện pass môn (VD: > 0 hoặc >= 4.0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isFinal
                                    ? const Color(0xFFEF4444).withAlpha(25)
                                    : const Color(0xFF10B981).withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isFinal
                                      ? const Color(0xFFEF4444).withAlpha(100)
                                      : const Color(0xFF10B981).withAlpha(100),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                comp.criteria,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isFinal
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFF34D399),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Badge tỷ trọng %
                            Container(
                              constraints: const BoxConstraints(minWidth: 46),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: comp.color.withAlpha(35),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: comp.color.withAlpha(90),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${comp.weightPercent.toStringAsFixed(comp.weightPercent.truncateToDouble() == comp.weightPercent ? 0 : 1)}%',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: comp.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Môn tiên quyết & Liên kết sơ đồ
                if (meta.prerequisites.isNotEmpty) ...[
                  const Text(
                    'MÔN TIÊN QUYẾT & LIÊN QUAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: meta.prerequisites.map((link) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          final clean = link
                              .replaceAll(
                                RegExp(r'\.md$', caseSensitive: false),
                                '',
                              )
                              .trim()
                              .toLowerCase();
                          final target = widget.nodeMap[clean];
                          if (target != null) {
                            widget.onSelectPrerequisite(target);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.secondary.withAlpha(90),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.link,
                                size: 12,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '[[$link]]',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 6. MÔ TẢ MÔN HỌC (Có nút Xem thêm / Thu gọn)
                if (meta.description.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MÔ TẢ MÔN HỌC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (meta.description.length > 140)
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            setState(() {
                              _isDescExpanded = !_isDescExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isDescExpanded ? 'Thu gọn' : 'Xem thêm',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _isDescExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 15,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor.withAlpha(60),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.description,
                          maxLines: _isDescExpanded ? null : 3,
                          overflow: _isDescExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: theme.colorScheme.onSurface.withAlpha(220),
                          ),
                        ),
                        if (!_isDescExpanded &&
                            meta.description.length > 140) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isDescExpanded = true;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Show more (Xem tiếp)...',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // NÚT BẤM "VIEW DETAILS" (Chỉ chuyển sang tài liệu khi bấm vào nút này)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withAlpha(80),
                  width: 1,
                ),
              ),
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text(
                'View Details (Xem tài liệu)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () => widget.onViewDetails(widget.node.note),
            ),
          ),
        ],
      ),
    );
  }
}
