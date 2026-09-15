import 'package:flutter/material.dart';
import '../models/course_metadata.dart';

/// Widget hiển thị bảng thành phần điểm và tỷ trọng (%) của môn học
class CourseAssessmentView extends StatelessWidget {
  final List<AssessmentComponent> assessments;

  const CourseAssessmentView({
    super.key,
    required this.assessments,
  });

  @override
  Widget build(BuildContext context) {
    if (assessments.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalWeight = assessments
        .fold<double>(0.0, (sum, i) => sum + i.weightPercent)
        .toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề phần đánh giá + Tổng %
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Tổng: $totalWeight%',
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
              children: assessments.map((item) {
                final flex = (item.weightPercent * 10).round().clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: Container(
                    color: item.color,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Danh sách các hàng thành phần điểm
        Column(
          children: assessments.map((comp) {
            final isFinal = comp.criteria.contains('4.0');
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(35),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: comp.color.withAlpha(35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: comp.color.withAlpha(90)),
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
    );
  }
}
