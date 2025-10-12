import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player_match_statistics.dart';
import 'package:fl_chart/fl_chart.dart';

class PlayerStatisticsView extends StatelessWidget {
  final List<PlayerMatchStatistics> statsHistory;

  const PlayerStatisticsView({super.key, required this.statsHistory});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    // Sort stats by date to ensure the chart is chronological
    statsHistory.sort((a, b) => a.matchId.compareTo(b.matchId)); // Assuming matchId is sortable and chronological for now

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.ratingEvolution,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(color: Colors.white10, strokeWidth: 1);
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(color: Colors.white10, strokeWidth: 1);
                  },
                ),
                titlesData: const FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minX: 0,
                maxX: (statsHistory.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: statsHistory.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.rating ?? 0);
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            appLocalizations.matchHistory,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statsHistory.length,
            itemBuilder: (context, index) {
              final stats = statsHistory[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${appLocalizations.matchId} ${stats.matchId}', style: Theme.of(context).textTheme.titleMedium),
                      Text('${appLocalizations.minutesPlayed} ${stats.minutesPlayed ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.rating} ${stats.rating?.toStringAsFixed(1) ?? appLocalizations.notAvailable}${appLocalizations.outOf10}'),
                      Text('${appLocalizations.shots} ${stats.shots ?? appLocalizations.notAvailable} (${stats.shotsOnTarget ?? appLocalizations.notAvailable} ${appLocalizations.onTarget})'),
                      Text('${appLocalizations.passes} ${stats.passes ?? appLocalizations.notAvailable} (${stats.accuratePasses ?? appLocalizations.notAvailable} ${appLocalizations.accuratePasses.toLowerCase()})'),
                      Text('xG: ${stats.playerXg?.toStringAsFixed(2) ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.notes} ${stats.notes ?? appLocalizations.noNotesAvailable}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
