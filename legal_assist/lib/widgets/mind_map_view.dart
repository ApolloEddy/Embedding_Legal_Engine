import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

/// 思维导图节点数据模型
class MindMapNode {
  final String id;
  final String title;
  final String? subtitle;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;
  final List<MindMapNode> children;
  final bool isExpanded;
  final Map<String, dynamic>? metadata;

  const MindMapNode({
    required this.id,
    required this.title,
    this.subtitle,
    required this.color,
    required this.backgroundColor,
    this.icon,
    this.children = const [],
    this.isExpanded = true,
    this.metadata,
  });

  MindMapNode copyWith({
    String? id,
    String? title,
    String? subtitle,
    Color? color,
    Color? backgroundColor,
    IconData? icon,
    List<MindMapNode>? children,
    bool? isExpanded,
    Map<String, dynamic>? metadata,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: icon ?? this.icon,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 思维导图视图
class MindMapView extends StatefulWidget {
  final MindMapNode rootNode;
  final Function(MindMapNode)? onNodeTap;
  final double nodeWidth;
  final double nodeHeight;
  final double horizontalSpacing;
  final double verticalSpacing;

  const MindMapView({
    super.key,
    required this.rootNode,
    this.onNodeTap,
    this.nodeWidth = 160,
    this.nodeHeight = 55,
    this.horizontalSpacing = 30,
    this.verticalSpacing = 70,
  });

  @override
  State<MindMapView> createState() => MindMapViewState();
}

class MindMapViewState extends State<MindMapView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TransformationController _transformController = TransformationController();
  
  // 存储每个节点的位置
  final Map<String, Offset> _nodePositions = {};
  
  // 展开状态
  final Map<String, bool> _expandedStates = {};
  
  // 用于导出图片
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _initExpandedStates(widget.rootNode);
  }

  void _initExpandedStates(MindMapNode node) {
    _expandedStates[node.id] = node.isExpanded;
    for (final child in node.children) {
      _initExpandedStates(child);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _toggleNode(String nodeId) {
    setState(() {
      _expandedStates[nodeId] = !(_expandedStates[nodeId] ?? true);
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: InteractiveViewer(
        transformationController: _transformController,
        boundaryMargin: const EdgeInsets.all(500),
        minScale: 0.2,
        maxScale: 3.0,
        constrained: false,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              color: Colors.transparent,
              child: CustomPaint(
                painter: _MindMapPainter(
                  rootNode: widget.rootNode,
                  expandedStates: _expandedStates,
                  nodeWidth: widget.nodeWidth,
                  nodeHeight: widget.nodeHeight,
                  horizontalSpacing: widget.horizontalSpacing,
                  verticalSpacing: widget.verticalSpacing,
                  animationValue: _animation.value,
                  nodePositions: _nodePositions,
                ),
                child: SizedBox(
                  width: _calculateTotalWidth(),
                  height: _calculateTotalHeight(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: _buildNodeWidgets(widget.rootNode, 0, 0),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateTotalWidth() {
    int maxLeaves = _countLeaves(widget.rootNode);
    return math.max(600, maxLeaves * (widget.nodeWidth + widget.horizontalSpacing) + 200);
  }

  double _calculateTotalHeight() {
    int depth = _getDepth(widget.rootNode);
    return math.max(400, depth * (widget.nodeHeight + widget.verticalSpacing) + 200);
  }
  
  /// 导出为 PNG 图片
  Future<Uint8List?> exportToPng() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('导出图片失败: $e');
      return null;
    }
  }
  
  /// 获取导出 Key
  GlobalKey get repaintBoundaryKey => _repaintBoundaryKey;

  int _countLeaves(MindMapNode node) {
    if (node.children.isEmpty || !(_expandedStates[node.id] ?? true)) {
      return 1;
    }
    return node.children.fold(0, (sum, child) => sum + _countLeaves(child));
  }

  int _getDepth(MindMapNode node) {
    if (node.children.isEmpty || !(_expandedStates[node.id] ?? true)) {
      return 1;
    }
    return 1 + node.children.map(_getDepth).reduce(math.max);
  }

  List<Widget> _buildNodeWidgets(MindMapNode node, int depth, int siblingIndex) {
    final widgets = <Widget>[];
    
    // 计算节点位置
    final position = _calculateNodePosition(node, depth, siblingIndex);
    _nodePositions[node.id] = position;

    widgets.add(
      Positioned(
        left: position.dx,
        top: position.dy,
        child: _buildNodeCard(node),
      ),
    );

    // 递归构建子节点
    if (_expandedStates[node.id] ?? true) {
      for (int i = 0; i < node.children.length; i++) {
        widgets.addAll(_buildNodeWidgets(node.children[i], depth + 1, i));
      }
    }

    return widgets;
  }

  Offset _calculateNodePosition(MindMapNode node, int depth, int siblingIndex) {
    // 简化的位置计算
    double y = 80 + depth * (widget.nodeHeight + widget.verticalSpacing);
    
    // 计算 x 位置需要考虑所有同级节点
    double totalWidth = _calculateTotalWidth();
    int leaves = _countLeaves(widget.rootNode);
    double leafWidth = (totalWidth - 200) / math.max(1, leaves);
    
    // 找到当前节点应该在的叶子范围
    int leafStart = _countLeavesBefore(widget.rootNode, node.id);
    int nodeLeaves = _countLeaves(node);
    
    double x = 100 + leafStart * leafWidth + (nodeLeaves * leafWidth - widget.nodeWidth) / 2;
    
    return Offset(x, y);
  }

  int _countLeavesBefore(MindMapNode root, String targetId) {
    if (root.id == targetId) return 0;
    
    int count = 0;
    for (final child in root.children) {
      if (_containsNode(child, targetId)) {
        return count + _countLeavesBefore(child, targetId);
      }
      count += _countLeaves(child);
    }
    return count;
  }

  bool _containsNode(MindMapNode node, String targetId) {
    if (node.id == targetId) return true;
    return node.children.any((child) => _containsNode(child, targetId));
  }

  Widget _buildNodeCard(MindMapNode node) {
    final isExpanded = _expandedStates[node.id] ?? true;
    final hasChildren = node.children.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasChildren) {
          _toggleNode(node.id);
        }
        widget.onNodeTap?.call(node);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.nodeWidth,
        constraints: BoxConstraints(minHeight: widget.nodeHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              node.backgroundColor,
              node.backgroundColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: node.color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: node.color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (node.icon != null) ...[
                    Icon(node.icon, color: node.color, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      node.title,
                      style: TextStyle(
                        color: node.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasChildren) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: node.color,
                      size: 16,
                    ),
                  ],
                ],
              ),
              if (node.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  node.subtitle!,
                  style: TextStyle(
                    color: node.color.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 思维导图绘制器（绘制连接线）
class _MindMapPainter extends CustomPainter {
  final MindMapNode rootNode;
  final Map<String, bool> expandedStates;
  final double nodeWidth;
  final double nodeHeight;
  final double horizontalSpacing;
  final double verticalSpacing;
  final double animationValue;
  final Map<String, Offset> nodePositions;

  _MindMapPainter({
    required this.rootNode,
    required this.expandedStates,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.animationValue,
    required this.nodePositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnections(canvas, rootNode);
  }

  void _drawConnections(Canvas canvas, MindMapNode node) {
    final isExpanded = expandedStates[node.id] ?? true;
    if (!isExpanded || node.children.isEmpty) return;

    final parentPos = nodePositions[node.id];
    if (parentPos == null) return;

    final parentCenter = Offset(
      parentPos.dx + nodeWidth / 2,
      parentPos.dy + nodeHeight,
    );

    for (final child in node.children) {
      final childPos = nodePositions[child.id];
      if (childPos == null) continue;

      final childCenter = Offset(
        childPos.dx + nodeWidth / 2,
        childPos.dy,
      );

      // 绘制贝塞尔曲线
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            node.color.withValues(alpha: 0.6 * animationValue),
            child.color.withValues(alpha: 0.6 * animationValue),
          ],
        ).createShader(Rect.fromPoints(parentCenter, childCenter))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(parentCenter.dx, parentCenter.dy)
        ..cubicTo(
          parentCenter.dx,
          parentCenter.dy + verticalSpacing / 2,
          childCenter.dx,
          childCenter.dy - verticalSpacing / 2,
          childCenter.dx,
          childCenter.dy,
        );

      canvas.drawPath(path, paint);

      // 递归绘制子节点连接
      _drawConnections(canvas, child);
    }
  }

  @override
  bool shouldRepaint(covariant _MindMapPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.expandedStates != expandedStates;
  }
}
