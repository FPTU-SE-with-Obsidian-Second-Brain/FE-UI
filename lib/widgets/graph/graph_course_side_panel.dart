import 'package:flutter/material.dart';
import '../models/course_metadata.dart';
import '../models/graph_node_3d.dart';
import '../models/note_file.dart';
import 'course_assessment_view.dart';
import 'course_info_header.dart';
import 'course_prerequisites_view.dart';

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
          // 1. Header & Thông tin tổng quan (Component tách rời)
          CourseInfoHeader(
            node: widget.node,
            meta: meta,
            onClose: widget.onClose,
          ),

          // 2. Nội dung chi tiết cuộn được
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bảng thành phần điểm & tỷ trọng (%) (Component tách rời)
                  CourseAssessmentView(assessments: meta.assessments),

                  // Môn tiên quyết & Liên kết sơ đồ (Component tách rời)
                  CoursePrerequisitesView(
                    prerequisites: meta.prerequisites,
                    nodeMap: widget.nodeMap,
                    onSelectPrerequisite: widget.onSelectPrerequisite,
                  ),

                  // Mô tả môn học (Có toggle Xem thêm / Thu gọn)
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
                      child: Text(
                        _isDescExpanded
                            ? meta.description
                            : (meta.description.length > 140
                                ? '${meta.description.substring(0, 140)}...'
                                : meta.description),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // 3. Nút hành động xem tài liệu chi tiết (View Details)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withAlpha(80),
                  width: 1,
                ),
              ),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
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
