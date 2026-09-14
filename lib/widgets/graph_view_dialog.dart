import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/note_file.dart';
import '../providers/note_provider.dart';

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

class GraphEdge3D {
  final GraphNode3D source;
  final GraphNode3D target;

  GraphEdge3D({required this.source, required this.target});
}

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
    if (folderName.contains('3')) return const Color(0xFF34D399); // Kỳ 3 emerald
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
      final id = note.fileName.replaceAll(RegExp(r'\.md$', caseSensitive: false), '').trim();

      final double y = 1 - (i / (count - 1.0 == 0 ? 1 : count - 1.0)) * 2; // từ 1 đến -1
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
        final cleanLink = link.replaceAll(RegExp(r'\.md$', caseSensitive: false), '').trim().toLowerCase();
        final targetNode = _nodeMap[cleanLink];

        if (targetNode != null && targetNode != node) {
          _edges.add(GraphEdge3D(source: node, target: targetNode));
          node.degree++;
          targetNode.degree++;
        }
      }
    }

    // 3. Chạy thuật toán co giãn lò xo 3D (Force-directed relaxation)
    // Kéo các node có liên kết lại gần nhau trong không gian 3D
    for (int iter = 0; iter < 45; iter++) {
      // Lực hút giữa các node có liên kết
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

      // Lực đẩy giữa các node quá gần nhau
      for (int i = 0; i < _nodes.length; i++) {
        for (int j = i + 1; j < _nodes.length; j++) {
          final n1 = _nodes[i];
          final n2 = _nodes[j];
          final dx = n2.x - n1.x;
          final dy = n2.y - n1.y;
          final dz = n2.z - n1.z;
          final distSq = dx * dx + dy * dy + dz * dz + 0.1;
          if (distSq < 4500) { // khoảng cách < 67px
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

    // Định kích thước bán kính node dựa vào số liên kết
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
        _connectedNeighbors.clear();
        if (closest != null) {
          for (final edge in _edges) {
            if (edge.source == closest) _connectedNeighbors.add(edge.target);
            if (edge.target == closest) _connectedNeighbors.add(edge.source);
          }
        }
      });
    }
  }

  void _selectNodeAndClose(GraphNode3D node) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    noteProvider.selectNote(node.note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: const Color(0xFF0F0F12), // Nền than chì sâu thẳm chuẩn Obsidian
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF27272A).withAlpha(120), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 1100,
          height: 720,
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
                    cursor: _hoveredNode != null ? SystemMouseCursors.click : SystemMouseCursors.grab,
                    onHover: (e) => _onHover(e.localPosition),
                    child: GestureDetector(
                      onPanStart: (_) {
                        setState(() => _autoRotate = false); // Dừng tự xoay khi người dùng thao tác chuột
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _rotY += details.delta.dx * 0.006;
                          _rotX -= details.delta.dy * 0.006;
                        });
                      },
                      onDoubleTap: () {
                        if (_hoveredNode != null) {
                          _selectNodeAndClose(_hoveredNode!);
                        }
                      },
                      onTap: () {
                        if (_hoveredNode != null) {
                          _selectNodeAndClose(_hoveredNode!);
                        }
                      },
                      child: CustomPaint(
                        painter: _Graph3DPainter(
                          nodes: _nodes,
                          edges: _edges,
                          rotX: _rotX,
                          rotY: _rotY,
                          zoom: _zoom,
                          panOffset: _panOffset,
                          hoveredNode: _hoveredNode,
                          connectedNeighbors: _connectedNeighbors,
                          showLabels: _showLabels,
                          colorBySemester: _colorBySemester,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Thanh điều khiển phía trên (Header & Toolbars)
              Positioned(
                top: 14,
                left: 18,
                right: 18,
                child: Row(
                  children: [
                    // Tiêu đề & Logo Obsidian
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hub_outlined, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Graph View — Mạng Lưới Tri Thức 3D',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(40),
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

                    const Spacer(),

                    // Nhóm nút điều khiển nhanh (Controls Toolbar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        children: [
                          // Bật/tắt tự động xoay (Auto-rotation)
                          IconButton(
                            tooltip: _autoRotate ? 'Dừng tự xoay' : 'Bật tự động xoay 3D',
                            icon: Icon(
                              _autoRotate ? Icons.pause_circle_outline : Icons.play_circle_outline,
                              size: 18,
                              color: _autoRotate ? colorScheme.primary : Colors.grey,
                            ),
                            onPressed: () => setState(() => _autoRotate = !_autoRotate),
                          ),

                          // Bật/tắt hiển thị nhãn chữ
                          IconButton(
                            tooltip: _showLabels ? 'Ẩn tất cả tên môn' : 'Hiện tất cả tên môn',
                            icon: Icon(
                              _showLabels ? Icons.label : Icons.label_outline,
                              size: 18,
                              color: _showLabels ? colorScheme.primary : Colors.grey,
                            ),
                            onPressed: () => setState(() => _showLabels = !_showLabels),
                          ),

                          // Bật/tắt màu sắc theo học kỳ
                          IconButton(
                            tooltip: _colorBySemester ? 'Chế độ Trắng xám Obsidian' : 'Màu theo học kỳ',
                            icon: Icon(
                              Icons.palette_outlined,
                              size: 18,
                              color: _colorBySemester ? const Color(0xFFA855F7) : Colors.grey,
                            ),
                            onPressed: () => setState(() => _colorBySemester = !_colorBySemester),
                          ),

                          // Phóng to
                          IconButton(
                            tooltip: 'Phóng to (+)',
                            icon: const Icon(Icons.zoom_in, size: 18),
                            onPressed: () => setState(() => _zoom = (_zoom * 1.15).clamp(0.35, 4.0)),
                          ),

                          // Thu nhỏ
                          IconButton(
                            tooltip: 'Thu nhỏ (-)',
                            icon: const Icon(Icons.zoom_out, size: 18),
                            onPressed: () => setState(() => _zoom = (_zoom * 0.85).clamp(0.35, 4.0)),
                          ),

                          // Đặt lại góc nhìn (Reset View)
                          IconButton(
                            tooltip: 'Đặt lại góc nhìn',
                            icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
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

                    const SizedBox(width: 8),

                    // Nút Đóng
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),

              // Thẻ thông tin môn học đang được rê chuột (Hover Card Preview)
              if (_hoveredNode != null)
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withAlpha(240),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withAlpha(120), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(40),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _hoveredNode!.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _hoveredNode!.id,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _hoveredNode!.note.folderName,
                                style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hoveredNode!.note.title,
                          style: TextStyle(fontSize: 12.5, color: theme.hintColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_hoveredNode!.degree} liên kết môn học ${_connectedNeighbors.isNotEmpty ? '(${_connectedNeighbors.map((n) => n.id).take(4).join(', ')}${_connectedNeighbors.length > 4 ? '...' : ''})' : ''}',
                          style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('Mở tài liệu môn học', style: TextStyle(fontSize: 12)),
                            onPressed: () => _selectNodeAndClose(_hoveredNode!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Hướng dẫn tương tác nhanh ở góc dưới bên phải
              Positioned(
                right: 20,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141416).withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF27272A).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        'Rê chuột để xoay 3D • Cuộn chuột để Zoom • Click đúp để mở môn',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Graph3DPainter extends CustomPainter {
  final List<GraphNode3D> nodes;
  final List<GraphEdge3D> edges;
  final double rotX;
  final double rotY;
  final double zoom;
  final Offset panOffset;
  final GraphNode3D? hoveredNode;
  final Set<GraphNode3D> connectedNeighbors;
  final bool showLabels;
  final bool colorBySemester;

  _Graph3DPainter({
    required this.nodes,
    required this.edges,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.panOffset,
    required this.hoveredNode,
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
      // Xoay quanh trục Y (Yaw)
      final x1 = node.x * cosY + node.z * sinY;
      final z1 = -node.x * sinY + node.z * cosY;

      // Xoay quanh trục X (Pitch)
      final y2 = node.y * cosX - z1 * sinX;
      final z2 = node.y * sinX + z1 * cosX;

      node.depth = z2;

      // Phép chiếu phối cảnh (Perspective Projection)
      final scale = (cameraDist / (cameraDist + z2)) * zoom;
      node.screenX = centerX + x1 * scale;
      node.screenY = centerY + y2 * scale;
    }

    // 2. Vẽ các đường nối (Edges - Mạng nhện)
    final edgePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final hasHover = hoveredNode != null;

    for (final edge in edges) {
      final s = edge.source;
      final t = edge.target;

      final isEdgeHighlighted = hasHover &&
          ((s == hoveredNode && connectedNeighbors.contains(t)) ||
              (t == hoveredNode && connectedNeighbors.contains(s)));

      if (isEdgeHighlighted) {
        // Đường nối sáng rực màu tím Obsidian khi đang hover
        edgePaint
          ..color = const Color(0xFFA855F7).withAlpha(220)
          ..strokeWidth = 2.2;
      } else if (hasHover) {
        // Các đường khác mờ hẳn đi
        edgePaint
          ..color = const Color(0x1AFFFFFF)
          ..strokeWidth = 0.6;
      } else {
        // Trạng thái bình thường: đường mờ tinh tế kiểu Obsidian
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

    // 3. Sắp xếp các node theo độ sâu (Depth sorting: từ xa đến gần)
    final sortedNodes = List<GraphNode3D>.from(nodes)
      ..sort((a, b) => a.depth.compareTo(b.depth));

    final nodePaint = Paint()..isAntiAlias = true;
    final glowPaint = Paint()..isAntiAlias = true;

    // 4. Vẽ các node (Các chấm tròn môn học)
    for (final node in sortedNodes) {
      final isHovered = node == hoveredNode;
      final isNeighbor = connectedNeighbors.contains(node);

      final depthFactor = ((node.depth + 400.0) / 800.0).clamp(0.3, 1.2);
      final currentRadius = node.radius * depthFactor * (isHovered ? 1.5 : (isNeighbor ? 1.2 : 1.0));

      Color baseColor;
      if (colorBySemester) {
        baseColor = node.color;
      } else {
        baseColor = const Color(0xFFCBD5E1); // Bạc sáng phong cách gốc Obsidian
      }

      if (hasHover) {
        if (isHovered) {
          baseColor = const Color(0xFFC084FC); // Tím sáng nổi bật
        } else if (isNeighbor) {
          baseColor = const Color(0xFFE879F9); // Hồng tím liên kết
        } else {
          baseColor = baseColor.withAlpha(50); // Các môn khác mờ đi
        }
      }

      // Vẽ vòng phát sáng (Glow halo) quanh node
      if (isHovered || isNeighbor || node.degree >= 3) {
        glowPaint.color = baseColor.withAlpha(isHovered ? 100 : 40);
        canvas.drawCircle(
          Offset(node.screenX, node.screenY),
          currentRadius + (isHovered ? 5.0 : 2.5),
          glowPaint,
        );
      }

      // Vẽ chấm tròn chính
      nodePaint.color = baseColor;
      canvas.drawCircle(
        Offset(node.screenX, node.screenY),
        currentRadius,
        nodePaint,
      );

      // 5. Vẽ nhãn tên môn học (Labels)
      if (showLabels || isHovered || isNeighbor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.id,
            style: TextStyle(
              color: isHovered ? Colors.white : (isNeighbor ? const Color(0xFFF3E8FF) : const Color(0xCCFFFFFF)),
              fontSize: isHovered ? 11.5 : 9.5,
              fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(node.screenX + currentRadius + 3, node.screenY - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Graph3DPainter oldDelegate) => true;
}
