import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'dart:math' as math;

class PassNetworkVisualizer extends StatelessWidget {
  final Map<String, dynamic> passNetworkData;

  const PassNetworkVisualizer({super.key, required this.passNetworkData});

  @override
  Widget build(BuildContext context) {
    final nodes = (passNetworkData['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final edges = (passNetworkData['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (nodes.isEmpty) {
      return const Center(child: Text('No pass network data available'));
    }

    return AspectRatio(
      aspectRatio: 0.66, // Football pitch aspect ratio
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CustomPaint(
          painter: PassNetworkPainter(nodes: nodes, edges: edges),
        ),
      ),
    );
  }
}

class PassNetworkPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;

  PassNetworkPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw pitch lines (simple)
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, paint);

    // Map player IDs to positions (for edges)
    // In a real app, these would come from average positions in the tracking data
    // Here we'll distribute nodes for visualization if positions aren't provided
    final Map<String, Offset> nodePositions = {};
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // Dummy positions if not present in data
      double x = (node['avg_x'] ?? (0.2 + (i % 3) * 0.3)) * size.width;
      double y = (node['avg_y'] ?? (0.1 + (i / 3) * 0.2)) * size.height;
      nodePositions[node['id'].toString()] = Offset(x, y);
    }

    // Draw Edges
    for (final edge in edges) {
      final source = nodePositions[edge['source'].toString()];
      final target = nodePositions[edge['target'].toString()];
      final count = edge['count'] as int? ?? 1;

      if (source != null && target != null) {
        final edgePaint = Paint()
          ..color = Colors.yellow.withOpacity(math.min(1.0, count / 10))
          ..strokeWidth = math.min(5.0, count.toDouble())
          ..style = PaintingStyle.stroke;
        canvas.drawLine(source, target, edgePaint);
      }
    }

    // Draw Nodes
    for (final node in nodes) {
      final pos = nodePositions[node['id'].toString()];
      if (pos != null) {
        final nodePaint = Paint()..color = (node['team'] == 'team_a' ? Colors.blue : Colors.red);
        canvas.drawCircle(pos, 8, nodePaint);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: node['id'].toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
