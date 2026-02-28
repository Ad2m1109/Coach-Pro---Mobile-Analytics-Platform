import 'package:flutter/material.dart';

class PitchDivisionWidget extends StatelessWidget {
  final Map<String, dynamic> zoneData;

  const PitchDivisionWidget({super.key, required this.zoneData});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildZone(context, 'Left', zoneData['left']),
            _buildZone(context, 'Center', zoneData['center']),
            _buildZone(context, 'Right', zoneData['right']),
          ],
        ),
      ),
    );
  }

  Widget _buildZone(BuildContext context, String title, Map<String, dynamic>? data) {
    final attacks = data?['attacks'] ?? 0;
    final shots = data?['shots'] ?? 0;
    
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$attacks Attacks', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('$shots Shots', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
