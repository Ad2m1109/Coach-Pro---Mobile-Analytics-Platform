import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/widgets/custom_card.dart';

class AlertCountersPanel extends StatelessWidget {
  final List<TacticalAlert> alerts;

  const AlertCountersPanel({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final counts = _calculateCounts();

    return Row(
      children: [
        _CounterItem(label: 'CRITICAL', count: counts['CRITICAL'] ?? 0, color: Colors.red),
        const SizedBox(width: AppSpacing.s),
        _CounterItem(label: 'HIGH', count: counts['HIGH'] ?? 0, color: Colors.orange),
        const SizedBox(width: AppSpacing.s),
        _CounterItem(label: 'MODERATE', count: counts['MODERATE'] ?? 0, color: Colors.yellow),
        const SizedBox(width: AppSpacing.s),
        _CounterItem(label: 'LOW', count: counts['LOW'] ?? 0, color: Colors.green),
      ],
    );
  }

  Map<String, int> _calculateCounts() {
    final Map<String, int> counts = {};
    for (var alert in alerts) {
      final label = alert.severityLabel.toUpperCase();
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }
}

class _CounterItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CounterItem({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
