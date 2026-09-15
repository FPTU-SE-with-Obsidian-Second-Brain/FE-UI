import 'package:flutter/material.dart';
import '../models/course_metadata.dart';
import '../models/graph_node_3d.dart';

/// Header và các thông tin cơ bản (Số tín chỉ, liên kết, điều kiện pass) của môn học trong Side Panel
class CourseInfoHeader extends StatelessWidget {
  final GraphNode3D node;
  final CourseMetadata meta;
  final VoidCallback onClose;

  const CourseInfoHeader({
    super.key,
    required this.node,
    required this.meta,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Thanh tiêu đề trên cùng
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
                  color: node.color,
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
                  node.note.folderName,
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
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
        ),

        // 2. Tên đầy đủ & Thẻ tín chỉ + Bậc liên kết
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(60),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_outlined, size: 18, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Số tín chỉ', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                              Text(meta.credits, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(60),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hub_outlined, size: 18, color: Color(0xFFA855F7)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Liên kết', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                              Text('${node.degree} môn', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Điều kiện pass môn
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
                        Icon(Icons.verified_outlined, size: 16, color: Color(0xFF22C55E)),
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
            ],
          ),
        ),
      ],
    );
  }
}
