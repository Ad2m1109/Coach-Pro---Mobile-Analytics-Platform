import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/match_details.dart';
import 'package:frontend/models/match_event.dart';
import 'package:frontend/models/match_team_statistics.dart';
import 'package:frontend/models/player_match_statistics.dart';
import 'package:frontend/models/player.dart'; // New import
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/features/match_statistics/widgets/pass_network_visualizer.dart';
import 'package:frontend/features/match_statistics/widgets/pitch_division_widget.dart';

class MatchStatisticsPage extends StatelessWidget {
  final List<MatchTeamStatistics> teamStats;
  final TeamLineup homeLineup;
  final TeamLineup awayLineup;
  final List<PlayerMatchStatistics> playerStats;
  final List<MatchEvent> events;
  final Function(BuildContext context, PlayerMatchStatistics stats, Player player) showPlayerStatsDialog;

  const MatchStatisticsPage({
    super.key,
    required this.teamStats,
    required this.homeLineup,
    required this.awayLineup,
    required this.playerStats,
    required this.events,
    required this.showPlayerStatsDialog,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamComparison(context, teamStats, homeLineup, awayLineup),
          const SizedBox(height: AppSpacing.m),
          _buildPlayerPerformance(context, playerStats, homeLineup, awayLineup),
        ],
      ),
    );
  }

  Widget _buildTeamComparison(BuildContext context, List<MatchTeamStatistics> teamStats, TeamLineup home, TeamLineup away) {
    final appLocalizations = AppLocalizations.of(context)!;
    final homeStats = teamStats.firstWhere((s) => s.teamId == home.teamId);
    final awayStats = teamStats.firstWhere((s) => s.teamId == away.teamId);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.teamComparison,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          _buildStatRowWithPercentage(context, appLocalizations.possession, homeStats.possessionPercentage ?? 0, awayStats.possessionPercentage ?? 0, home, away, unit: '%', isPercentage: true),
          _buildStatRowWithPercentage(context, appLocalizations.totalShots, homeStats.totalShots ?? 0, awayStats.totalShots ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.shotsOnTarget, homeStats.shotsOnTarget ?? 0, awayStats.shotsOnTarget ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.expectedGoalsXG, homeStats.expectedGoals ?? 0.0, awayStats.expectedGoals ?? 0.0, home, away, isPercentage: true), // xG is typically a decimal
          _buildStatRowWithPercentage(context, appLocalizations.pressures, homeStats.pressures ?? 0, awayStats.pressures ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.final3rdPasses, homeStats.finalThirdPasses ?? 0, awayStats.finalThirdPasses ?? 0, home, away),
          const SizedBox(height: AppSpacing.m),
          if (homeStats.passNetworkData != null) ...[
            Text("Pass Network", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            PassNetworkVisualizer(passNetworkData: homeStats.passNetworkData!),
            const SizedBox(height: AppSpacing.m),
          ],
          if (homeStats.zoneAnalysisData != null) ...[
            Text("Pitch Division Power Analysis", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            PitchDivisionWidget(zoneData: homeStats.zoneAnalysisData!),
          ],
        ],
      ),
    );
  }

  DataRow _createStatRow(String metric, String homeValue, String awayValue) {
    return DataRow(
      cells: [
        DataCell(Text(metric)),
        DataCell(Text(homeValue)),
        DataCell(Text(awayValue)),
      ],
    );
  }

  Widget _buildStatRowWithPercentage(
      BuildContext context, String metric, num homeValue, num awayValue, TeamLineup homeLineup, TeamLineup awayLineup,
      {String? unit, bool isPercentage = false}) {
    final total = homeValue + awayValue;
    final homePercentage = total > 0 ? (homeValue / total) : 0.0;
    final awayPercentage = total > 0 ? (awayValue / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isPercentage ? homeValue.toStringAsFixed(1) : homeValue.toStringAsFixed(0)}${unit ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                '${isPercentage ? awayValue.toStringAsFixed(1) : awayValue.toStringAsFixed(0)}${unit ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: homePercentage,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(homePercentage * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
              Text('${(awayPercentage * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPerformance(BuildContext context, List<PlayerMatchStatistics> playerStats, TeamLineup home, TeamLineup away) {
    final appLocalizations = AppLocalizations.of(context)!;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.playerPerformance,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s),
          ...playerStats.map((stat) {
            // Get the Player object
            final allPlayers = [...home.players, ...away.players];
            final player = allPlayers.firstWhere((p) => p.id == stat.playerId, orElse: () => PlayerWithPosition(id: '', name: appLocalizations.unknown));

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(stat.notes ?? appLocalizations.noNotesAvailable, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stat.rating?.toStringAsFixed(1) ?? 'N/A',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
              onTap: () => showPlayerStatsDialog(context, stat, player),
            );
          }).toList(),
        ],
      ),
    );
  }
}
