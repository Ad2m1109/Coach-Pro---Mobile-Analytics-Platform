import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player_match_statistics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/widgets/custom_card.dart';

class PlayerStatisticsView extends StatelessWidget {
  final List<PlayerMatchStatistics> statsHistory;

  const PlayerStatisticsView({super.key, required this.statsHistory});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    statsHistory.sort((a, b) => a.matchId.compareTo(b.matchId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.ratingEvolution,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          CustomCard(
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Theme.of(context).dividerColor.withOpacity(0.1), strokeWidth: 1);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Theme.of(context).dividerColor.withOpacity(0.1), strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2), width: 1),
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
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            appLocalizations.matchHistory,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statsHistory.length,
            itemBuilder: (context, index) {
              final stats = statsHistory[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${appLocalizations.matchId} ${stats.matchId}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${stats.rating?.toStringAsFixed(1) ?? 'N/A'}',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      _buildStatItem(context, Icons.timer, '${appLocalizations.minutesPlayed}: ${stats.minutesPlayed ?? appLocalizations.notAvailable}'),
                      _buildStatItem(context, Icons.sports_soccer, '${appLocalizations.shots}: ${stats.shots ?? appLocalizations.notAvailable} (${stats.shotsOnTarget ?? appLocalizations.notAvailable} ${appLocalizations.onTarget})'),
                      _buildStatItem(context, Icons.swap_calls, '${appLocalizations.passes}: ${stats.passes ?? appLocalizations.notAvailable} (${stats.accuratePasses ?? appLocalizations.notAvailable} ${appLocalizations.accuratePasses.toLowerCase()})'),
                      _buildStatItem(context, Icons.analytics, 'xG: ${stats.playerXg?.toStringAsFixed(2) ?? appLocalizations.notAvailable}'),
                      if (stats.notes != null && stats.notes!.isNotEmpty) ...[
                        const Divider(),
                        Text(
                          '${appLocalizations.notes}: ${stats.notes}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
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

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
