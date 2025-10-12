import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/match_details.dart';
import 'package:frontend/models/match_event.dart';
import 'package:frontend/models/match_team_statistics.dart';
import 'package:frontend/models/player_match_statistics.dart';
import 'package:frontend/models/player.dart'; // New import

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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamComparison(context, teamStats, homeLineup, awayLineup),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTeamComparison(BuildContext context, List<MatchTeamStatistics> teamStats, TeamLineup home, TeamLineup away) {
    final appLocalizations = AppLocalizations.of(context)!;
    final homeStats = teamStats.firstWhere((s) => s.teamId == home.teamId);
    final awayStats = teamStats.firstWhere((s) => s.teamId == away.teamId);

    return _buildSectionCard(context,
      title: appLocalizations.teamComparison,
      child: Column( // Changed from SingleChildScrollView with DataTable
        children: [
          _buildStatRowWithPercentage(context, appLocalizations.possession, homeStats.possessionPercentage ?? 0, awayStats.possessionPercentage ?? 0, home, away, unit: '%', isPercentage: true),
          _buildStatRowWithPercentage(context, appLocalizations.totalShots, homeStats.totalShots ?? 0, awayStats.totalShots ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.shotsOnTarget, homeStats.shotsOnTarget ?? 0, awayStats.shotsOnTarget ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.expectedGoalsXG, homeStats.expectedGoals ?? 0.0, awayStats.expectedGoals ?? 0.0, home, away, isPercentage: true), // xG is typically a decimal
          _buildStatRowWithPercentage(context, appLocalizations.pressures, homeStats.pressures ?? 0, awayStats.pressures ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.final3rdPasses, homeStats.finalThirdPasses ?? 0, awayStats.finalThirdPasses ?? 0, home, away),
          // Add more metrics as needed, e.g., from JSON data if parsed
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  '${homeLineup.teamName}: ${isPercentage ? homeValue.toStringAsFixed(1) : homeValue.toStringAsFixed(0)}${unit ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  '${awayLineup.teamName}: ${isPercentage ? awayValue.toStringAsFixed(1) : awayValue.toStringAsFixed(0)}${unit ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: homePercentage,
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            minHeight: 8,
          ),
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
    return _buildSectionCard(context,
      title: appLocalizations.playerPerformance,
      child: Column(
        children: playerStats.map((stat) {
          // Get the Player object
          final allPlayers = [...home.players, ...away.players];
          final player = allPlayers.firstWhere((p) => p.id == stat.playerId, orElse: () => PlayerWithPosition(id: '', name: appLocalizations.unknown));

          return ListTile(
            title: Text(player.name),
            subtitle: Text(stat.notes ?? appLocalizations.noNotesAvailable, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => showPlayerStatsDialog(context, stat, player),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
