import 'package:flutter/material.dart';
import '../models/graph_node_3d.dart';

/// Widget hiển thị danh sách môn tiên quyết và liên kết sơ đồ tri thức
class CoursePrerequisitesView extends StatelessWidget {
  final List<String> prerequisites;
  final Map<String, GraphNode3D> nodeMap;
  final ValueChanged<GraphNode3D> onSelectPrerequisite;

  const CoursePrerequisitesView({
    super.key,
    required this.prerequisites,
    required this.nodeMap,
    required this.onSelectPrerequisite,
  });

  @override
  Widget build(BuildContext context) {
    if (prerequisites.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          children: prerequisites.map((link) {
            final clean = link
                .replaceAll(RegExp(r'\.md$', caseSensitive: false), '')
                .trim()
                .toLowerCase();
            final target = nodeMap[clean];

            return InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: target != null ? () => onSelectPrerequisite(target) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}
