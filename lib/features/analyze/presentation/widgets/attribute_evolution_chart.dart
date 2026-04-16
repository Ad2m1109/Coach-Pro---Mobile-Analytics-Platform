import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/widgets/custom_card.dart';

enum AttributeMetric {
  defensiveLine,
  width,
  compactness,
  avgSpeed,
  pressingIntensity,
}

class AttributeEvolutionChart extends StatefulWidget {
  final List<AnalysisSegment> segments;
  final Function(double seconds)? onSeek;
  final int? selectedIndex;

  const AttributeEvolutionChart({
    super.key,
    required this.segments,
    this.onSeek,
    this.selectedIndex,
  });

  @override
  State<AttributeEvolutionChart> createState() => _AttributeEvolutionChartState();
}

class _AttributeEvolutionChartState extends State<AttributeEvolutionChart> {
  AttributeMetric _selectedMetric = AttributeMetric.width;

  @override
  Widget build(BuildContext context) {
    if (widget.segments.length < 2) {
      return const CustomCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Text(
              'Awaiting more tactical data for trend analysis...',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TACTICAL EVOLUTION',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attribute progression over time',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              _buildMetricSelector(),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildLegend(),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 220,
            child: LineChart(_buildChartData(context)),
          ),
          const SizedBox(height: AppSpacing.m),
          const Center(
            child: Text(
              'Click any point to jump to that moment in the video',
              style: TextStyle(color: Colors.white10, fontSize: 9, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<AttributeMetric>(
        value: _selectedMetric,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF001630),
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).primaryColor),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (AttributeMetric? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedMetric = newValue;
            });
          }
        },
        items: const [
          DropdownMenuItem(value: AttributeMetric.defensiveLine, child: Text('Defensive Line')),
          DropdownMenuItem(value: AttributeMetric.width, child: Text('Team Width')),
          DropdownMenuItem(value: AttributeMetric.compactness, child: Text('Compactness')),
          DropdownMenuItem(value: AttributeMetric.avgSpeed, child: Text('Average Speed')),
          DropdownMenuItem(value: AttributeMetric.pressingIntensity, child: Text('Pressing')),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _LegendItem(label: 'Team A', color: Colors.blueAccent),
        const SizedBox(width: AppSpacing.m),
        _LegendItem(label: 'Team B', color: AppColors.secondary),
      ],
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final List<FlSpot> spotsA = [];
    final List<FlSpot> spotsB = [];

    for (int i = 0; i < widget.segments.length; i++) {
      final seg = widget.segments[i];
      spotsA.add(FlSpot(i.toDouble(), _getValue(seg, 'team_a', _selectedMetric)));
      spotsB.add(FlSpot(i.toDouble(), _getValue(seg, 'team_b', _selectedMetric)));
    }

    double maxY = 1.0;
    for (var s in spotsA) if (s.y > maxY) maxY = s.y;
    for (var s in spotsB) if (s.y > maxY) maxY = s.y;
    maxY = maxY * 1.25;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withOpacity(0.03),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: (widget.segments.length / 5).ceil().toDouble(),
            getTitlesWidget: (value, meta) {
              int idx = value.toInt();
              if (idx < 0 || idx >= widget.segments.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTime(widget.segments[idx].startSec),
                  style: const TextStyle(fontSize: 8, color: Colors.white24),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 8, color: Colors.white24),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (widget.segments.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF00122D).withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}${_getUnit(_selectedMetric)}',
                TextStyle(
                  color: spot.barIndex == 0 ? Colors.blueAccent : AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            }).toList();
          },
        ),
        touchCallback: (event, response) {
          if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
            final index = response.lineBarSpots![0].spotIndex;
            if (widget.onSeek != null) {
              widget.onSeek!(widget.segments[index].startSec);
            }
          }
        },
      ),
      lineBarsData: [
        _buildBarData(spotsA, Colors.blueAccent),
        _buildBarData(spotsB, AppColors.secondary),
      ],
    );
  }

  LineChartBarData _buildBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          bool isSelected = index == widget.selectedIndex;
          return FlDotCirclePainter(
            radius: isSelected ? 4 : 0,
            color: color,
            strokeWidth: isSelected ? 2 : 0,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  double _getValue(AnalysisSegment segment, String team, AttributeMetric metric) {
    final data = segment.analysisJson?[team] ?? {};
    switch (metric) {
      case AttributeMetric.defensiveLine:
        return (data['defensive_line'] as num?)?.toDouble() ?? 0.0;
      case AttributeMetric.width:
        return (data['width'] as num?)?.toDouble() ?? 0.0;
      case AttributeMetric.compactness:
        return (data['compactness'] as num?)?.toDouble() ?? 0.0;
      case AttributeMetric.avgSpeed:
        return (data['avg_speed'] as num?)?.toDouble() ?? 0.0;
      case AttributeMetric.pressingIntensity:
        return (data['pressing_intensity'] as num?)?.toDouble() ?? 0.0;
    }
  }

  String _getUnit(AttributeMetric metric) {
    switch (metric) {
      case AttributeMetric.defensiveLine:
      case AttributeMetric.width:
      case AttributeMetric.compactness:
        return "m";
      case AttributeMetric.avgSpeed:
        return " m/s";
      case AttributeMetric.pressingIntensity:
        return "";
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
