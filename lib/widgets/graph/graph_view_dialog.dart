import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/graph_node_3d.dart';
import '../models/note_file.dart';
import '../providers/note_provider.dart';
import '../utils/graph_3d_physics.dart';
import 'graph_3d_painter.dart';
import 'graph_course_side_panel.dart';
import 'graph_view_toolbar.dart';

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
  List<GraphNode3D> _nodes = [];
  List<GraphEdge3D> _edges = [];
  Map<String, GraphNode3D> _nodeMap = {};

  double _rotX = 0.25;
  double _rotY = 0.35;
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;

  bool _autoRotate = true;
  bool _showLabels = false;
  bool _colorBySemester = true;

  GraphNode3D? _hoveredNode;
  GraphNode3D? _selectedNode;
  final Set<GraphNode3D> _connectedNeighbors = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_autoRotate && mounted) {
        setState(() => _rotY += 0.003);
      }
    });
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) => _buildGraphData());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _buildGraphData() {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    if (noteProvider.notes.isEmpty) return;

    final data = Graph3DPhysics.buildGraph(noteProvider.notes);
    _nodes = data.nodes;
    _edges = data.edges;
    _nodeMap = data.nodeMap;

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
        if (_selectedNode == null) _updateNeighbors(closest);
      });
    }
  }

  void _updateNeighbors(GraphNode3D? center) {
    _connectedNeighbors.clear();
    if (center != null) {
      for (final edge in _edges) {
        if (edge.source == center) _connectedNeighbors.add(edge.target);
        if (edge.target == center) _connectedNeighbors.add(edge.source);
      }
    }
  }

  void _onNodeSelected(GraphNode3D node) {
    setState(() {
      _selectedNode = node;
      _updateNeighbors(node);
    });
  }

  void _viewDetailsAndNavigate(NoteFile note) {
    Provider.of<NoteProvider>(context, listen: false).selectNote(note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activeFocusNode = _selectedNode ?? _hoveredNode;

    return ExcludeSemantics(
      child: Dialog(
        backgroundColor: const Color(0xFF0F0F12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF27272A).withAlpha(120), width: 1),
        ),
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 1200,
            height: 750,
            child: Row(
              children: [
                // 1. Canvas 3D & Toolbar (Bên trái)
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Listener(
                          onPointerSignal: (e) {
                            if (e is PointerScrollEvent) {
                              setState(() {
                                _zoom = (_zoom * (e.scrollDelta.dy > 0 ? 0.92 : 1.08))
                                    .clamp(0.35, 4.0);
                              });
                            }
                          },
                          child: MouseRegion(
                            cursor: _hoveredNode != null
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.grab,
                            onHover: (e) => _onHover(e.localPosition),
                            child: GestureDetector(
                              onPanStart: (_) => setState(() => _autoRotate = false),
                              onPanUpdate: (d) {
                                setState(() {
                                  _rotY += d.delta.dx * 0.006;
                                  _rotX -= d.delta.dy * 0.006;
                                });
                              },
                              onTap: () {
                                if (_hoveredNode != null) _onNodeSelected(_hoveredNode!);
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

                      // Thanh công cụ Toolbar
                      Positioned(
                        top: 14,
                        left: 18,
                        right: 18,
                        child: GraphViewToolbar(
                          nodeCount: _nodes.length,
                          edgeCount: _edges.length,
                          autoRotate: _autoRotate,
                          showLabels: _showLabels,
                          colorBySemester: _colorBySemester,
                          isNodeSelected: _selectedNode != null,
                          onToggleAutoRotate: () => setState(() => _autoRotate = !_autoRotate),
                          onToggleShowLabels: () => setState(() => _showLabels = !_showLabels),
                          onToggleColorBySemester: () =>
                              setState(() => _colorBySemester = !_colorBySemester),
                          onZoomIn: () => setState(() => _zoom = (_zoom * 1.15).clamp(0.35, 4.0)),
                          onZoomOut: () => setState(() => _zoom = (_zoom * 0.85).clamp(0.35, 4.0)),
                          onResetCamera: () {
                            setState(() {
                              _rotX = 0.25;
                              _rotY = 0.35;
                              _zoom = 1.0;
                              _panOffset = Offset.zero;
                            });
                          },
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),

                      // Hướng dẫn ở góc dưới bên trái
                      if (_selectedNode == null) _buildBottomHint(),
                    ],
                  ),
                ),

                // 2. Side Panel thông tin môn học (Bên phải)
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
                      onSelectPrerequisite: _onNodeSelected,
                      onViewDetails: _viewDetailsAndNavigate,
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

  Widget _buildBottomHint() {
    return Positioned(
      left: 20,
      bottom: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF141416).withAlpha(200),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF27272A).withAlpha(80)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFFA855F7)),
            SizedBox(width: 6),
            Text(
              'Nhấn vào môn học để xem thông tin (Tín chỉ, Điều kiện Pass...)',
              style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
    );
  }
}
