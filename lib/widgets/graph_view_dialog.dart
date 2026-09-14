import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/note_file.dart';
import '../providers/note_provider.dart';

/// Mô tả một thành phần điểm trong bảng đánh giá môn học (Syllabus Assessment)
class AssessmentComponent {
  final String
  category; // Assignment, Lab, Practical Exam, Progress Test, Final Exam...
  final double weightPercent; // 20.0, 10.0, 30.0...
  final String criteria; // > 0 hoặc ≥ 4.0 / 10.0 (Điểm liệt)
  final String details; // N/A, trắc nghiệm, tự luận, số câu hỏi...
  final Color color;

  const AssessmentComponent({
    required this.category,
    required this.weightPercent,
    required this.criteria,
    required this.details,
    required this.color,
  });
}

/// Lớp trích xuất thông tin chi tiết của môn học từ file markdown
class CourseMetadata {
  final String code;
  final String name;
  final String credits;
  final List<String> prerequisites;
  final String passCriteria;
  final List<AssessmentComponent> assessments;
  final String description;

  CourseMetadata({
    required this.code,
    required this.name,
    required this.credits,
    required this.prerequisites,
    required this.passCriteria,
    required this.assessments,
    required this.description,
  });

  factory CourseMetadata.fromNote(NoteFile note) {
    final content = note.rawContent;

    // 1. Mã môn học
    final codeMatch = RegExp(
      r'\*\*Mã môn học[^*]*\*\*:\s*([^\n\r]+)',
      caseSensitive: false,
    ).firstMatch(content);
    final code =
        codeMatch?.group(1)?.trim() ?? note.fileName.replaceAll('.md', '');

    // 2. Tên môn học
    String name = note.title;
    final h1Match = RegExp(
      r'^#\s+([^\n\r]+)',
      multiLine: true,
    ).firstMatch(content);
    if (h1Match != null) {
      name = h1Match.group(1)!.trim();
    } else {
      final engMatch = RegExp(
        r'\*\*Tên tiếng Anh:\*\*\s*([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(content);
      if (engMatch != null) name = engMatch.group(1)!.trim();
    }

    // 3. Số tín chỉ
    final creditMatch = RegExp(
      r'(?:Số tín chỉ|NoCredit)[^:]*:\s*([0-9]+)',
      caseSensitive: false,
    ).firstMatch(content);
    final credits = creditMatch != null
        ? '${creditMatch.group(1)} tín chỉ'
        : '3 tín chỉ';

    // 4. Môn tiên quyết
    final prereq = note.links;

    // 5. Điều kiện cần để pass môn (Chuẩn học vụ FPTU & trích xuất nội dung)
    final passCriteriaList = <String>[
      '• Chuyên cần: Tham gia tối thiểu 80% số buổi học',
      '• Điểm tổng kết môn: GPA >= 5.0 / 10.0',
      '• Điểm thi cuối kỳ (FE / PE): >= 4.0 / 10.0 (Không bị điểm liệt)',
    ];

    // 6. Đánh giá chi tiết (Assessments & Weights %)
    final assessments = <AssessmentComponent>[];
    final assessSectionMatch = RegExp(
      r'##\s*(?:[0-9]+\.\s*)?Đánh giá[^\r\n]*\r?\n([\s\S]*?)(?=(?:\r?\n##)|$)',
      caseSensitive: false,
    ).firstMatch(content);

    if (assessSectionMatch != null) {
      final lines = assessSectionMatch.group(1)!.split(RegExp(r'\r?\n'));
      for (final rawLine in lines) {
        final clean = rawLine.replaceAll(RegExp(r'^[-*]\s*'), '').trim();
        if (clean.isEmpty || !clean.contains('%')) continue;

        final pctMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*%').firstMatch(clean);
        if (pctMatch != null) {
          final weight = double.tryParse(pctMatch.group(1)!) ?? 0.0;

          // Tên loại đánh giá (nằm trước dấu % hoặc dấu :)
          var category = clean
              .substring(0, pctMatch.start)
              .replaceAll('**', '')
              .replaceAll(':', '')
              .replaceAll('-', '')
              .trim();
          if (category.isEmpty) category = 'Thành phần đánh giá';

          // Ghi chú / Chi tiết phụ (nằm sau %)
          var details = clean
              .substring(pctMatch.end)
              .replaceAll('**', '')
              .trim();
          details = details.replaceAll(RegExp(r'^[()]|[()]$'), '').trim();

          // Xác định điều kiện theo chuẩn FLM FPTU (Hình thức thi & Điểm liệt)
          final isFinal =
              category.toLowerCase().contains('final') ||
              category.toLowerCase().contains('fe') ||
              category.toLowerCase().contains('cuối kỳ');
          final criteria = isFinal ? '≥ 4.0 (Điểm liệt)' : '> 0 (Bắt buộc)';

          // Bảng màu trực quan Obsidian
          Color color;
          final catLower = category.toLowerCase();
          if (catLower.contains('assign')) {
            color = const Color(0xFF38BDF8); // Cyan - Assignment
          } else if (catLower.contains('lab') ||
              catLower.contains('workshop')) {
            color = const Color(0xFF34D399); // Emerald - Lab/Workshop
          } else if (catLower.contains('practical') ||
              catLower.contains('pe')) {
            color = const Color(0xFFA855F7); // Purple - PE
          } else if (catLower.contains('progress') ||
              catLower.contains('pt') ||
              catLower.contains('quiz')) {
            color = const Color(0xFFFBBF24); // Amber - Progress Test
          } else if (catLower.contains('final') ||
              catLower.contains('fe') ||
              catLower.contains('exam')) {
            color = const Color(0xFFF43F5E); // Rose Red - Final Exam
          } else {
            color = const Color(0xFF818CF8); // Indigo
          }

          assessments.add(
            AssessmentComponent(
              category: category,
              weightPercent: weight,
              criteria: criteria,
              details: details,
              color: color,
            ),
          );
        }
      }
    }

    if (assessments.isEmpty) {
      assessments.addAll([
        const AssessmentComponent(
          category: 'Assignment',
          weightPercent: 20.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Bài tập lớn & đồ án',
          color: Color(0xFF38BDF8),
        ),
        const AssessmentComponent(
          category: 'Lab / Workshop',
          weightPercent: 10.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Thực hành trên lớp',
          color: Color(0xFF34D399),
        ),
        const AssessmentComponent(
          category: 'Practical Exam (PE)',
          weightPercent: 30.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Thi thực hành máy tính',
          color: Color(0xFFA855F7),
        ),
        const AssessmentComponent(
          category: 'Progress Test (PT)',
          weightPercent: 10.0,
          criteria: '> 0 (Bắt buộc)',
          details: 'Kiểm tra tiến độ định kỳ',
          color: Color(0xFFFBBF24),
        ),
        const AssessmentComponent(
          category: 'Final Exam (FE)',
          weightPercent: 30.0,
          criteria: '≥ 4.0 (Điểm liệt)',
          details: 'Thi kết thúc môn học',
          color: Color(0xFFF43F5E),
        ),
      ]);
    }

    // 7. Mô tả môn học (Lấy đầy đủ nội dung, không cắt ngắn)
    String desc = '';
    final descMatch = RegExp(
      r'##\s*(?:[0-9]+\.\s*)?(?:Mô tả môn học|Description)[^\r\n]*\r?\n([\s\S]*?)(?=(?:\r?\n##)|$)',
      caseSensitive: false,
    ).firstMatch(content);
    if (descMatch != null) {
      final rawLines = descMatch.group(1)!.split(RegExp(r'\r?\n'));
      final cleanedLines = <String>[];
      for (var l in rawLines) {
        l = l
            .replaceAll(RegExp(r'^[0-9]+\.\s*[-*]?\s*'), '')
            .replaceAll(RegExp(r'^[-*]\s*'), '')
            .trim();
        if (l.isNotEmpty) {
          cleanedLines.add(l);
        }
      }
      if (cleanedLines.length > 1) {
        desc = cleanedLines.map((e) => '• $e').join('\n\n');
      } else if (cleanedLines.isNotEmpty) {
        desc = cleanedLines.first;
      }
    }

    return CourseMetadata(
      code: code,
      name: name,
      credits: credits,
      prerequisites: prereq,
      passCriteria: passCriteriaList.join('\n'),
      assessments: assessments,
      description: desc,
    );
  }
}

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
  GraphNode3D? _selectedNode; // Môn đang được chọn để hiển thị thanh bên cạnh
  bool _isDescExpanded =
      false; // Quản lý trạng thái xem thêm/thu gọn mô tả môn học
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
    if (folderName.contains('3'))
      return const Color(0xFF34D399); // Kỳ 3 emerald
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

  /// Khi nhấn vào một node: CHỈ mở thanh bên cạnh hiển thị thông tin, VẪN Ở NGUYÊN SƠ ĐỒ OBSIDIAN
  void _onNodeSelected(GraphNode3D node) {
    setState(() {
      _selectedNode = node;
      _isDescExpanded = false; // Mặc định thu gọn mô tả khi chọn môn mới
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
                                painter: _Graph3DPainter(
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
                    child: _buildCourseSidePanel(context, _selectedNode!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Xây dựng thanh bên cạnh (Side Panel) theo đúng yêu cầu của người dùng
  Widget _buildCourseSidePanel(BuildContext context, GraphNode3D node) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final meta = CourseMetadata.fromNote(node.note);

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
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Đóng thanh thông tin',
                  onPressed: () {
                    setState(() {
                      _selectedNode = null;
                      _isDescExpanded = false;
                      _updateConnectedNeighbors(_hoveredNode);
                    });
                  },
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
                                  '${node.degree} môn',
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

                // 3. ĐIỀU KIỆN CẦN ĐỂ PASS MÔN (Yêu cầu trọng tâm)
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
                          // Nếu nhấp vào chip tiên quyết: Focus ngay node đó trên sơ đồ 3D!
                          final clean = link
                              .replaceAll(
                                RegExp(r'\.md$', caseSensitive: false),
                                '',
                              )
                              .trim()
                              .toLowerCase();
                          final target = _nodeMap[clean];
                          if (target != null) {
                            _onNodeSelected(target);
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
              onPressed: () => _viewDetailsAndNavigate(node.note),
            ),
          ),
        ],
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
  final GraphNode3D? focusNode;
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
      if (showLabels || isFocus || isNeighbor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.id,
            style: TextStyle(
              color: isFocus
                  ? Colors.white
                  : (isNeighbor
                        ? const Color(0xFFF3E8FF)
                        : const Color(0xCCFFFFFF)),
              fontSize: isFocus ? 12.0 : 9.5,
              fontWeight: isFocus ? FontWeight.bold : FontWeight.w500,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            node.screenX + currentRadius + 3,
            node.screenY - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Graph3DPainter oldDelegate) => true;
}
