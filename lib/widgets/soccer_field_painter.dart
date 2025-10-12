import 'package:flutter/material.dart';

class SoccerFieldPainter extends CustomPainter {
  final Color lineColor; // New field

  SoccerFieldPainter({required this.lineColor}); // New constructor

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor // Use the passed color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Field boundaries
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Halfway line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.1, paint);

    // Center mark
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2.0, paint);

    // Penalty areas
    // Top penalty area
    canvas.drawRect(Rect.fromLTWH(
      size.width * 0.15,
      0,
      size.width * 0.7,
      size.height * 0.2,
    ), paint);

    // Bottom penalty area
    canvas.drawRect(Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.8,
      size.width * 0.7,
      size.height * 0.2,
    ), paint);

    // Goal areas
    // Top goal area
    canvas.drawRect(Rect.fromLTWH(
      size.width * 0.35,
      0,
      size.width * 0.3,
      size.height * 0.1,
    ), paint);

    // Bottom goal area
    canvas.drawRect(Rect.fromLTWH(
      size.width * 0.35,
      size.height * 0.9,
      size.width * 0.3,
      size.height * 0.1,
    ), paint);

    // Goals (simplified as lines)
    // Top goal line
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.65, 0), paint);
    // Bottom goal line
    canvas.drawLine(Offset(size.width * 0.35, size.height), Offset(size.width * 0.65, size.height), paint);

    // Corner arcs (simplified as small lines)
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width * 0.05, size.height * 0.05), 0, 1.5708, false, paint); // Top-left
    canvas.drawArc(Rect.fromLTWH(size.width * 0.95, 0, size.width * 0.05, size.height * 0.05), 1.5708, 1.5708, false, paint); // Top-right
    canvas.drawArc(Rect.fromLTWH(0, size.height * 0.95, size.width * 0.05, size.height * 0.05), 4.71239, 1.5708, false, paint); // Bottom-left
    canvas.drawArc(Rect.fromLTWH(size.width * 0.95, size.height * 0.95, size.width * 0.05, size.height * 0.05), 3.14159, 1.5708, false, paint); // Bottom-right

    // Tactical zones (simplified horizontal and vertical lines)
    // Horizontal lines for Defense, Midfield, Attack
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), paint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), paint);

    // Vertical lines for Left, Center, Right
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Goalkeeper zone (small box in front of goal)
    canvas.drawRect(Rect.fromLTWH(
      size.width * 0.4,
      size.height * 0.95, // Adjust as needed for bottom goal
      size.width * 0.2,
      size.height * 0.05,
    ), paint);

    canvas.drawRect(Rect.fromLTWH(
      size.width * 0.4,
      0, // Adjust as needed for top goal
      size.width * 0.2,
      size.height * 0.05,
    ), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
