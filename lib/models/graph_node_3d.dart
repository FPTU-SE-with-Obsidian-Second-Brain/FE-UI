import 'package:flutter/material.dart';
import 'note_file.dart';

/// Node biểu diễn một môn học trong không gian đồ thị 3D
class GraphNode3D {
  final NoteFile note;
  final String id;
  double x;
  double y;
  double z;
  int degree = 0;
  Color color;

  // Tọa độ chiếu lên màn hình 2D
  double screenX = 0;
  double screenY = 0;
  double depth = 0;
  double radius = 4.0;

  GraphNode3D({
    required this.note,
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    required this.color,
  });
}

/// Cạnh liên kết hai môn học trong mạng lưới đồ thị 3D
class GraphEdge3D {
  final GraphNode3D source;
  final GraphNode3D target;

  GraphEdge3D({required this.source, required this.target});
}
