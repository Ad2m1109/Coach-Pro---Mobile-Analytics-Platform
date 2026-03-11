import 'package:flutter/material.dart';
import 'package:frontend/models/tactical_alert.dart';

class TacticalMinimap extends StatelessWidget {
  final List<TacticalPlayerSnapshot> players;
  final TacticalBallSnapshot? ball;
  final TacticalZoneSnapshot? zone;

  const TacticalMinimap({
    super.key,
    required this.players,
    this.ball,
    this.zone,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 105 / 68,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF154734),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(width, height),
                  painter: _PitchPainter(),
                ),
                if (_hasValidZone(zone))
                  Positioned(
                    left: _scaleX(_clamp(zone!.xMin, 0, 105), width),
                    top: _scaleY(_clamp(zone!.yMin, 0, 68), height),
                    width: _scaleX(_clamp(zone!.xMax, 0, 105), width) -
                        _scaleX(_clamp(zone!.xMin, 0, 105), width),
                    height: _scaleY(_clamp(zone!.yMax, 0, 68), height) -
                        _scaleY(_clamp(zone!.yMin, 0, 68), height),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                    ),
                  ),
                ...players.map((p) {
                  final x = _scaleX(_clamp(p.x, 0, 105), width);
                  final y = _scaleY(_clamp(p.y, 0, 68), height);
                  final color = p.team.toUpperCase() == 'A'
                      ? Colors.blueAccent
                      : Colors.redAccent;
                  return Positioned(
                    left: x - 4,
                    top: y - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  );
                }),
                if (ball != null)
                  Positioned(
                    left: _scaleX(_clamp(ball!.x, 0, 105), width) - 3,
                    top: _scaleY(_clamp(ball!.y, 0, 68), height) - 3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static double _scaleX(double x, double width) => (x / 105.0) * width;
  static double _scaleY(double y, double height) => (y / 68.0) * height;
  static double _clamp(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  static bool _hasValidZone(TacticalZoneSnapshot? zone) {
    if (zone == null) return false;
    if (zone.xMax <= zone.xMin) return false;
    if (zone.yMax <= zone.yMin) return false;
    return true;
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), linePaint);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.12,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
