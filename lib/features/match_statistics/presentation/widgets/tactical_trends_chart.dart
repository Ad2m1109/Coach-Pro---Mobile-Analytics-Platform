import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/widgets/custom_card.dart';

enum TacticalMetricType {
  width,
  compactness,
  verticality,
  uniformity,
  intensity,
}

class TacticalTrendsChart extends StatefulWidget {
  final List<TacticalAlert> alerts;

  const TacticalTrendsChart({super.key, required this.alerts});

  @override
  State<TacticalTrendsChart> createState() => _TacticalTrendsChartState();
}

class _TacticalTrendsChartState extends State<TacticalTrendsChart> {
  TacticalMetricType _selectedMetric = TacticalMetricType.width;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tactical Evolution', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildMetricSelector(),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _buildLegend(),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 200,
            child: widget.alerts.length < 2
                ? const Center(child: Text('Insufficient data for trend chart', style: TextStyle(color: Colors.grey, fontSize: 12)))
                : LineChart(_buildChartData(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    return DropdownButton<TacticalMetricType>(
      value: _selectedMetric,
      underline: const SizedBox(),
      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
      onChanged: (TacticalMetricType? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedMetric = newValue;
          });
        }
      },
      items: [
        const DropdownMenuItem(value: TacticalMetricType.width, child: Text('Width')),
        const DropdownMenuItem(value: TacticalMetricType.compactness, child: Text('Compactness')),
        const DropdownMenuItem(value: TacticalMetricType.verticality, child: Text('Verticality')),
        const DropdownMenuItem(value: TacticalMetricType.uniformity, child: Text('Uniformity')),
        const DropdownMenuItem(value: TacticalMetricType.intensity, child: Text('Intensity')),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _LegendItem(label: 'Team A', color: Colors.blue),
        const SizedBox(width: AppSpacing.m),
        _LegendItem(label: 'Team B', color: Colors.red),
      ],
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final List<FlSpot> spotsA = [];
    final List<FlSpot> spotsB = [];

    for (int i = 0; i < widget.alerts.length; i++) {
      final alert = widget.alerts[i];
      final analysis = alert.analysis ?? {};
      final teamA = analysis['team_a'] ?? {};
      final teamB = analysis['team_b'] ?? {};

      double valA = 0.0;
      double valB = 0.0;

      switch (_selectedMetric) {
        case TacticalMetricType.width:
          valA = (teamA['width'] as num?)?.toDouble() ?? 0.0;
          valB = (teamB['width'] as num?)?.toDouble() ?? 0.0;
          break;
        case TacticalMetricType.compactness:
          valA = (teamA['compactness'] as num?)?.toDouble() ?? 0.0;
          valB = (teamB['compactness'] as num?)?.toDouble() ?? 0.0;
          break;
        case TacticalMetricType.verticality:
          valA = (teamA['verticality'] as num?)?.toDouble() ?? 0.0;
          valB = (teamB['verticality'] as num?)?.toDouble() ?? 0.0;
          break;
        case TacticalMetricType.uniformity:
          valA = (teamA['uniformity'] as num?)?.toDouble() ?? 0.0;
          valB = (teamB['uniformity'] as num?)?.toDouble() ?? 0.0;
          break;
        case TacticalMetricType.intensity:
          valA = (teamA['pressing_intensity'] as num?)?.toDouble() ?? 0.0;
          valB = (teamB['pressing_intensity'] as num?)?.toDouble() ?? 0.0;
          break;
      }

      spotsA.add(FlSpot(i.toDouble(), valA));
      spotsB.add(FlSpot(i.toDouble(), valB));
    }

    // Auto-scale Y axis based on metric type
    double maxY = 100.0;
    if (_selectedMetric == TacticalMetricType.verticality) maxY = 2.0;
    if (_selectedMetric == TacticalMetricType.uniformity) maxY = 20.0;
    if (_selectedMetric == TacticalMetricType.intensity) maxY = 1000.0;

    // Actually find the max in data for better zoom
    double dataMax = 0.0;
    for (var s in spotsA) if (s.y > dataMax) dataMax = s.y;
    for (var s in spotsB) if (s.y > dataMax) dataMax = s.y;
    maxY = dataMax * 1.2;
    if (maxY == 0) maxY = 1.0;

    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 2,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= widget.alerts.length) return const SizedBox();
              return Text(
                widget.alerts[value.toInt()].timestamp.split('-')[0],
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (widget.alerts.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spotsA,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: spotsB,
          isCurved: true,
          color: Colors.red,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
