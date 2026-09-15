import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/graph_node_3d.dart';

/// CustomPainter chiếu và vẽ mạng lưới đồ thị tri thức 3D trong không gian Obsidian
class Graph3DPainter extends CustomPainter {
  final List<GraphNode3D> nodes;
  final List<GraphEdge3D> edges;
  final double rotX;
  final double rotY;
  final double zoom;
  final Offset panOffset;
  final GraphNode3D? focusNode;
  final Set<GraphNode3D> connectedNeighbors;
  final bool showLabels;
  final bool colorBySemester;

  Graph3DPainter({
    required this.nodes,
    required this.edges,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.panOffset,
    required this.focusNode,
    required this.connectedNeighbors,
    required this.showLabels,
    required this.colorBySemester,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final centerX = size.width / 2 + panOffset.dx;
    final centerY = size.height / 2 + panOffset.dy;
    const double cameraDist = 850.0;

    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);

    // 1. Chiếu 3D sang 2D cho từng node
    for (final node in nodes) {
      final x1 = node.x * cosY + node.z * sinY;
      final z1 = -node.x * sinY + node.z * cosY;

      final y2 = node.y * cosX - z1 * sinX;
      final z2 = node.y * sinX + z1 * cosX;

      node.depth = z2;

      final scale = (cameraDist / (cameraDist + z2)) * zoom;
      node.screenX = centerX + x1 * scale;
      node.screenY = centerY + y2 * scale;
    }

    // 2. Vẽ các đường nối (Edges - Mạng nhện)
    final edgePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final hasFocus = focusNode != null;

    for (final edge in edges) {
      final s = edge.source;
      final t = edge.target;

      final isEdgeHighlighted =
          hasFocus &&
          ((s == focusNode && connectedNeighbors.contains(t)) ||
              (t == focusNode && connectedNeighbors.contains(s)));

      if (isEdgeHighlighted) {
        edgePaint
          ..color = const Color(0xFFA855F7).withAlpha(220)
          ..strokeWidth = 2.2;
      } else if (hasFocus) {
        edgePaint
          ..color = const Color(0x1AFFFFFF)
          ..strokeWidth = 0.6;
      } else {
        edgePaint
          ..color = const Color(0x3594A3B8)
          ..strokeWidth = 1.0;
      }

      canvas.drawLine(
        Offset(s.screenX, s.screenY),
        Offset(t.screenX, t.screenY),
        edgePaint,
      );
    }

    // 3. Sắp xếp các node theo độ sâu
    final sortedNodes = List<GraphNode3D>.from(nodes)
      ..sort((a, b) => a.depth.compareTo(b.depth));

    final nodePaint = Paint()..isAntiAlias = true;
    final glowPaint = Paint()..isAntiAlias = true;

    // 4. Vẽ các node (Chấm tròn môn học)
    for (final node in sortedNodes) {
      final isFocus = node == focusNode;
      final isNeighbor = connectedNeighbors.contains(node);

      final depthFactor = ((node.depth + 400.0) / 800.0).clamp(0.3, 1.2);
      final currentRadius =
          node.radius *
          depthFactor *
          (isFocus ? 1.6 : (isNeighbor ? 1.25 : 1.0));

      Color baseColor;
      if (colorBySemester) {
        baseColor = node.color;
      } else {
        baseColor = const Color(0xFFCBD5E1);
      }

      if (hasFocus) {
        if (isFocus) {
          baseColor = const Color(0xFFC084FC); // Tím sáng nổi bật
        } else if (isNeighbor) {
          baseColor = const Color(0xFFE879F9); // Hồng tím liên kết
        } else {
          baseColor = baseColor.withAlpha(50);
        }
      }

      // Vòng phát sáng
      if (isFocus || isNeighbor || node.degree >= 3) {
        glowPaint.color = baseColor.withAlpha(isFocus ? 110 : 40);
        canvas.drawCircle(
          Offset(node.screenX, node.screenY),
          currentRadius + (isFocus ? 6.0 : 2.5),
          glowPaint,
        );
      }

      // Chấm tròn chính
      nodePaint.color = baseColor;
      canvas.drawCircle(
        Offset(node.screenX, node.screenY),
        currentRadius,
        nodePaint,
      );

      // 5. Nhãn tên môn học
      // Tự động hiển thị nhãn cho TẤT CẢ các môn khi người dùng lăn chuột phóng to (zoom in), giống ảnh 2 của Obsidian
      double autoLabelOpacity = 0.0;
      if (showLabels || isFocus || isNeighbor) {
        autoLabelOpacity = 1.0;
      } else if (zoom > 1.02) {
        // Tăng dần độ hiển thị mượt mà từ zoom 1.02 lên 1.15
        autoLabelOpacity = ((zoom - 1.02) / 0.13).clamp(0.0, 1.0);
      }

      if (autoLabelOpacity > 0.05) {
        // Bỏ qua nhãn nằm ngoài vùng nhìn (viewport culling)
        if (node.screenX >= -50 &&
            node.screenX <= size.width + 50 &&
            node.screenY >= -50 &&
            node.screenY <= size.height + 50) {
          final Color textColor;
          if (isFocus) {
            textColor = Colors.white;
          } else if (isNeighbor) {
            textColor = const Color(0xFFF3E8FF);
          } else {
            textColor = Color.fromRGBO(226, 232, 240, 0.88 * autoLabelOpacity);
          }

          final textPainter = TextPainter(
            text: TextSpan(
              text: node.id,
              style: TextStyle(
                color: textColor,
                fontSize: isFocus ? 12.0 : 9.5,
                fontWeight: isFocus ? FontWeight.bold : FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(
                      (230 * autoLabelOpacity).toInt().clamp(0, 255),
                    ),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          textPainter.paint(
            canvas,
            Offset(
              node.screenX + currentRadius + 4,
              node.screenY - textPainter.height / 2,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant Graph3DPainter oldDelegate) => true;
}
