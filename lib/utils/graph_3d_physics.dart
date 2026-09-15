import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/graph_node_3d.dart';
import '../models/note_file.dart';

/// Chứa kết quả cấu trúc mạng lưới đồ thị 3D sau khi tính toán
class Graph3DData {
  final List<GraphNode3D> nodes;
  final List<GraphEdge3D> edges;
  final Map<String, GraphNode3D> nodeMap;

  const Graph3DData({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
  });
}

/// Bộ thuật toán mô phỏng vật lý và bố trí không gian 3D cho đồ thị
class Graph3DPhysics {
  /// Xác định màu sắc trực quan theo học kỳ FPTU
  static Color getSemesterColor(String folderName) {
    if (folderName.contains('0')) return const Color(0xFF94A3B8); // Kỳ 0 xám
    if (folderName.contains('1')) return const Color(0xFF38BDF8); // Kỳ 1 cyan
    if (folderName.contains('2')) return const Color(0xFF60A5FA); // Kỳ 2 blue
    if (folderName.contains('3')) return const Color(0xFF34D399); // Kỳ 3 emerald
    if (folderName.contains('4')) return const Color(0xFFA3E635); // Kỳ 4 lime
    if (folderName.contains('5')) return const Color(0xFFFBBF24); // Kỳ 5 amber
    if (folderName.contains('6')) return const Color(0xFFFB923C); // Kỳ 6 orange
    if (folderName.contains('7')) return const Color(0xFFF472B6); // Kỳ 7 rose
    if (folderName.contains('8')) return const Color(0xFFA78BFA); // Kỳ 8 purple
    if (folderName.contains('9')) return const Color(0xFFC084FC); // Kỳ 9 violet
    return const Color(0xFFE2E8F0); // Mặc định trắng xám Obsidian
  }

  /// Xây dựng các node, liên kết edges và áp dụng thuật toán lò xo lực 3D
  static Graph3DData buildGraph(List<NoteFile> notes) {
    final List<GraphNode3D> nodes = [];
    final List<GraphEdge3D> edges = [];
    final Map<String, GraphNode3D> nodeMap = {};

    if (notes.isEmpty) {
      return Graph3DData(nodes: nodes, edges: edges, nodeMap: nodeMap);
    }

    final count = notes.length;
    final rand = math.Random(42);

    // 1. Phân bố các node theo khối cầu 3D (Fibonacci Sphere Distribution)
    final double phi = math.pi * (3 - math.sqrt(5)); // Tỉ lệ vàng góc xoay

    for (int i = 0; i < count; i++) {
      final note = notes[i];
      final id = note.fileName
          .replaceAll(RegExp(r'\.md$', caseSensitive: false), '')
          .trim();

      final double y = 1 - (i / (count - 1.0 == 0 ? 1 : count - 1.0)) * 2;
      final double radiusAtY = math.sqrt(math.max(0, 1 - y * y));
      final double theta = phi * i;

      final double baseRadius = 240.0 + (rand.nextDouble() * 40.0 - 20.0);
      final double x = math.cos(theta) * radiusAtY * baseRadius;
      final double z = math.sin(theta) * radiusAtY * baseRadius;

      final node = GraphNode3D(
        note: note,
        id: id,
        x: x,
        y: y * baseRadius,
        z: z,
        color: getSemesterColor(note.folderName),
      );

      nodes.add(node);
      nodeMap[id.toLowerCase()] = node;
      nodeMap[note.title.toLowerCase().trim()] = node;
    }

    // 2. Tạo các đường liên kết (Edges) từ cú pháp [[...]]
    for (final node in nodes) {
      for (final link in node.note.links) {
        final cleanLink = link
            .replaceAll(RegExp(r'\.md$', caseSensitive: false), '')
            .trim()
            .toLowerCase();
        final targetNode = nodeMap[cleanLink];

        if (targetNode != null && targetNode != node) {
          edges.add(GraphEdge3D(source: node, target: targetNode));
          node.degree++;
          targetNode.degree++;
        }
      }
    }

    // 3. Chạy thuật toán co giãn lò xo 3D (Force-directed relaxation)
    for (int iter = 0; iter < 45; iter++) {
      for (final edge in edges) {
        final dx = edge.target.x - edge.source.x;
        final dy = edge.target.y - edge.source.y;
        final dz = edge.target.z - edge.source.z;
        final dist = math.sqrt(dx * dx + dy * dy + dz * dz) + 0.1;
        final force = (dist - 110.0) * 0.04;

        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;
        final fz = (dz / dist) * force;

        edge.source.x += fx;
        edge.source.y += fy;
        edge.source.z += fz;
        edge.target.x -= fx;
        edge.target.y -= fy;
        edge.target.z -= fz;
      }

      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final n1 = nodes[i];
          final n2 = nodes[j];
          final dx = n2.x - n1.x;
          final dy = n2.y - n1.y;
          final dz = n2.z - n1.z;
          final distSq = dx * dx + dy * dy + dz * dz + 0.1;
          if (distSq < 4500) {
            final dist = math.sqrt(distSq);
            final force = (67.0 - dist) * 0.05;
            final fx = (dx / dist) * force;
            final fy = (dy / dist) * force;
            final fz = (dz / dist) * force;
            n1.x -= fx;
            n1.y -= fy;
            n1.z -= fz;
            n2.x += fx;
            n2.y += fy;
            n2.z += fz;
          }
        }
      }
    }

    for (final node in nodes) {
      node.radius = (3.5 + math.min(node.degree * 0.9, 7.5));
    }

    return Graph3DData(nodes: nodes, edges: edges, nodeMap: nodeMap);
  }
}
