import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/widgets/custom_card.dart';

class SeverityLineChart extends StatelessWidget {
  final List<TacticalAlert> alerts;

  const SeverityLineChart({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Severity Over Time', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 180,
            child: alerts.length < 2
                ? const Center(child: Text('Insufficient data for trend chart', style: TextStyle(color: Colors.grey, fontSize: 12)))
                : LineChart(_buildChartData(context)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    // Collect points
    final List<FlSpot> spots = [];
    for (int i = 0; i < alerts.length; i++) {
      spots.add(FlSpot(i.toDouble(), alerts[i].severityScore));
    }

    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() % 2 != 0) return const SizedBox(); // Show every 2nd title
              if (value.toInt() >= alerts.length) return const SizedBox();
              return Text(
                alerts[value.toInt()].timestamp.split('-')[0],
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.25,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (alerts.length - 1).toDouble(),
      minY: 0,
      maxY: 1.0,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}
