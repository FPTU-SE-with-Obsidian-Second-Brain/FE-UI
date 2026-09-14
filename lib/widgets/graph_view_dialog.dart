import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/graph_node_3d.dart';
import '../models/note_file.dart';
import '../providers/note_provider.dart';
import 'graph_3d_painter.dart';
import 'graph_course_side_panel.dart';

// Re-export models for backward compatibility with existing tests & consumers
export '../models/course_metadata.dart';
export '../models/graph_node_3d.dart';

class GraphViewDialog extends StatefulWidget {
  const GraphViewDialog({super.key});

  @override
  State<GraphViewDialog> createState() => _GraphViewDialogState();
}

class _GraphViewDialogState extends State<GraphViewDialog>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<GraphNode3D> _nodes = [];
  final List<GraphEdge3D> _edges = [];
  final Map<String, GraphNode3D> _nodeMap = {};

  // Điều khiển góc xoay 3D và camera
  double _rotX = 0.25;
  double _rotY = 0.35;
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;

  bool _autoRotate = true;
  bool _showLabels = false;
  bool _colorBySemester = true;

  GraphNode3D? _hoveredNode;
  GraphNode3D? _selectedNode; // Môn đang được chọn để hiển thị thanh bên cạnh
  final Set<GraphNode3D> _connectedNeighbors = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildGraphData();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_autoRotate && mounted) {
      setState(() {
        _rotY += 0.003; // Tự động xoay chậm quanh trục Y
      });
    }
  }

  Color _getSemesterColor(String folderName) {
    if (folderName.contains('0')) return const Color(0xFF94A3B8); // Kỳ 0 xám
    if (folderName.contains('1')) return const Color(0xFF38BDF8); // Kỳ 1 cyan
    if (folderName.contains('2')) return const Color(0xFF60A5FA); // Kỳ 2 blue
    if (folderName.contains('3')) {
      return const Color(0xFF34D399); // Kỳ 3 emerald
    }
    if (folderName.contains('4')) return const Color(0xFFA3E635); // Kỳ 4 lime
    if (folderName.contains('5')) return const Color(0xFFFBBF24); // Kỳ 5 amber
    if (folderName.contains('6')) return const Color(0xFFFB923C); // Kỳ 6 orange
    if (folderName.contains('7')) return const Color(0xFFF472B6); // Kỳ 7 rose
    if (folderName.contains('8')) return const Color(0xFFA78BFA); // Kỳ 8 purple
    if (folderName.contains('9')) return const Color(0xFFC084FC); // Kỳ 9 violet
    return const Color(0xFFE2E8F0); // Mặc định trắng xám Obsidian
  }

  void _buildGraphData() {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final notes = noteProvider.notes;
    if (notes.isEmpty) return;

    _nodes.clear();
    _edges.clear();
    _nodeMap.clear();

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
        color: _getSemesterColor(note.folderName),
      );

      _nodes.add(node);
      _nodeMap[id.toLowerCase()] = node;
      _nodeMap[note.title.toLowerCase().trim()] = node;
    }

    // 2. Tạo các đường liên kết (Edges) từ cú pháp [[...]]
    for (final node in _nodes) {
      for (final link in node.note.links) {
        final cleanLink = link
            .replaceAll(RegExp(r'\.md$', caseSensitive: false), '')
            .trim()
            .toLowerCase();
        final targetNode = _nodeMap[cleanLink];

        if (targetNode != null && targetNode != node) {
          _edges.add(GraphEdge3D(source: node, target: targetNode));
          node.degree++;
          targetNode.degree++;
        }
      }
    }

    // 3. Chạy thuật toán co giãn lò xo 3D (Force-directed relaxation)
    for (int iter = 0; iter < 45; iter++) {
      for (final edge in _edges) {
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

      for (int i = 0; i < _nodes.length; i++) {
        for (int j = i + 1; j < _nodes.length; j++) {
          final n1 = _nodes[i];
          final n2 = _nodes[j];
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

    for (final node in _nodes) {
      node.radius = (3.5 + math.min(node.degree * 0.9, 7.5));
    }

    if (mounted) setState(() {});
  }

  void _onHover(Offset localPos) {
    GraphNode3D? closest;
    double minDist = 18.0;

    for (final node in _nodes) {
      final dist = (Offset(node.screenX, node.screenY) - localPos).distance;
      if (dist < minDist) {
        minDist = dist;
        closest = node;
      }
    }

    if (closest != _hoveredNode) {
      setState(() {
        _hoveredNode = closest;
        // Nếu không có môn nào đang được chọn, cập nhật danh sách liên kết theo node đang hover
        if (_selectedNode == null) {
          _updateConnectedNeighbors(closest);
        }
      });
    }
  }

  void _updateConnectedNeighbors(GraphNode3D? centerNode) {
    _connectedNeighbors.clear();
    if (centerNode != null) {
      for (final edge in _edges) {
        if (edge.source == centerNode) _connectedNeighbors.add(edge.target);
        if (edge.target == centerNode) _connectedNeighbors.add(edge.source);
      }
    }
  }

  /// Khi nhấn vào một node: Mở thanh bên cạnh hiển thị thông tin, VẪN Ở NGUYÊN SƠ ĐỒ OBSIDIAN
  void _onNodeSelected(GraphNode3D node) {
    setState(() {
      _selectedNode = node;
      _updateConnectedNeighbors(node);
    });
  }

  /// Chỉ chuyển sang trang tài liệu khi người dùng BẤM VÀO BUTTON "View Details"
  void _viewDetailsAndNavigate(NoteFile note) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    noteProvider.selectNote(note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeFocusNode = _selectedNode ?? _hoveredNode;

    return ExcludeSemantics(
      child: Dialog(
        backgroundColor: const Color(0xFF0F0F12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF27272A).withAlpha(120),
            width: 1,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 1200,
            height: 750,
            child: Row(
              children: [
                // 1. Vùng hiển thị sơ đồ 3D Obsidian Canvas (Bên trái)
                Expanded(
                  child: Stack(
                    children: [
                      // Canvas vẽ mạng nhện đồ thị 3D tương tác
                      Positioned.fill(
                        child: Listener(
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent) {
                              setState(() {
                                if (pointerSignal.scrollDelta.dy > 0) {
                                  _zoom = (_zoom * 0.92).clamp(0.35, 4.0);
                                } else {
                                  _zoom = (_zoom * 1.08).clamp(0.35, 4.0);
                                }
                              });
                            }
                          },
                          child: MouseRegion(
                            cursor: _hoveredNode != null
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.grab,
                            onHover: (e) => _onHover(e.localPosition),
                            child: GestureDetector(
                              onPanStart: (_) {
                                setState(() => _autoRotate = false);
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  _rotY += details.delta.dx * 0.006;
                                  _rotX -= details.delta.dy * 0.006;
                                });
                              },
                              onTap: () {
                                if (_hoveredNode != null) {
                                  // Nhấn vào môn: Mở thanh bên cạnh, không chuyển trang
                                  _onNodeSelected(_hoveredNode!);
                                }
                              },
                              child: CustomPaint(
                                painter: Graph3DPainter(
                                  nodes: _nodes,
                                  edges: _edges,
                                  rotX: _rotX,
                                  rotY: _rotY,
                                  zoom: _zoom,
                                  panOffset: _panOffset,
                                  focusNode: activeFocusNode,
                                  connectedNeighbors: _connectedNeighbors,
                                  showLabels: _showLabels,
                                  colorBySemester: _colorBySemester,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Thanh công cụ phía trên (Toolbar)
                      Positioned(
                        top: 14,
                        left: 18,
                        right: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181B).withAlpha(220),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF27272A),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hub_outlined,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Graph View — Mạng Lưới Tri Thức 3D',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withAlpha(
                                          40,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_nodes.length} môn • ${_edges.length} liên kết',
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

                            // Bộ nút điều khiển Toolbar
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF18181B,
                                    ).withAlpha(220),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF27272A),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: _autoRotate
                                            ? 'Dừng tự xoay'
                                            : 'Bật tự động xoay 3D',
                                        icon: Icon(
                                          _autoRotate
                                              ? Icons.pause_circle_outline
                                              : Icons.play_circle_outline,
                                          size: 18,
                                          color: _autoRotate
                                              ? colorScheme.primary
                                              : Colors.grey,
                                        ),
                                        onPressed: () => setState(
                                          () => _autoRotate = !_autoRotate,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: _showLabels
                                            ? 'Ẩn tất cả tên môn'
                                            : 'Hiện tất cả tên môn',
                                        icon: Icon(
                                          _showLabels
                                              ? Icons.label
                                              : Icons.label_outline,
                                          size: 18,
                                          color: _showLabels
                                              ? colorScheme.primary
                                              : Colors.grey,
                                        ),
                                        onPressed: () => setState(
                                          () => _showLabels = !_showLabels,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: _colorBySemester
                                            ? 'Chế độ Trắng xám Obsidian'
                                            : 'Màu theo học kỳ',
                                        icon: Icon(
                                          Icons.palette_outlined,
                                          size: 18,
                                          color: _colorBySemester
                                              ? const Color(0xFFA855F7)
                                              : Colors.grey,
                                        ),
                                        onPressed: () => setState(
                                          () => _colorBySemester =
                                              !_colorBySemester,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Phóng to (+)',
                                        icon: const Icon(
                                          Icons.zoom_in,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () => _zoom = (_zoom * 1.15).clamp(
                                            0.35,
                                            4.0,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Thu nhỏ (-)',
                                        icon: const Icon(
                                          Icons.zoom_out,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () => _zoom = (_zoom * 0.85).clamp(
                                            0.35,
                                            4.0,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Đặt lại góc nhìn',
                                        icon: const Icon(
                                          Icons.center_focus_strong_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _rotX = 0.25;
                                            _rotY = 0.35;
                                            _zoom = 1.0;
                                            _panOffset = Offset.zero;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedNode == null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF18181B,
                                      ).withAlpha(220),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF27272A),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Hướng dẫn ở góc dưới bên trái nếu chưa chọn môn
                      if (_selectedNode == null)
                        Positioned(
                          left: 20,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141416).withAlpha(200),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF27272A).withAlpha(80),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Icons.touch_app_outlined,
                                    size: 14,
                                    color: Color(0xFFA855F7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Nhấn vào môn học để xem thông tin (Tín chỉ, Điều kiện Pass...)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. Thanh bên cạnh (Side Panel) hiển thị thông tin môn học & Button "View Details"
                if (_selectedNode != null) ...[
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: const Color(0xFF27272A).withAlpha(120),
                  ),
                  SizedBox(
                    width: 360,
                    child: GraphCourseSidePanel(
                      node: _selectedNode!,
                      nodeMap: _nodeMap,
                      onClose: () {
                        setState(() {
                          _selectedNode = null;
                          _connectedNeighbors.clear();
                        });
                      },
                      onSelectPrerequisite: (targetNode) {
                        _onNodeSelected(targetNode);
                      },
                      onViewDetails: (note) {
                        _viewDetailsAndNavigate(note);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
