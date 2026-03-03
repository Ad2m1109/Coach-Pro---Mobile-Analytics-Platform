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

class MatchStatisticsPage extends StatefulWidget {
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
  State<MatchStatisticsPage> createState() => _MatchStatisticsPageState();
}

class _MatchStatisticsPageState extends State<MatchStatisticsPage> {
  int _selectedTeamIndex = 0; // 0 for home, 1 for away

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamComparison(context, widget.teamStats, widget.homeLineup, widget.awayLineup),
          const SizedBox(height: AppSpacing.m),
          _buildPlayerPerformance(context, widget.playerStats, widget.homeLineup, widget.awayLineup),
        ],
      ),
    );
  }

  Widget _buildTeamComparison(BuildContext context, List<MatchTeamStatistics> teamStats, TeamLineup home, TeamLineup away) {
    final appLocalizations = AppLocalizations.of(context)!;
    final homeStats = teamStats.firstWhere((s) => s.teamId == home.teamId);
    final awayStats = teamStats.firstWhere((s) => s.teamId == away.teamId);

    final selectedStats = _selectedTeamIndex == 0 ? homeStats : awayStats;
    final selectedTeamName = _selectedTeamIndex == 0 ? home.teamName : away.teamName;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appLocalizations.teamComparison,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _buildStatRowWithPercentage(context, appLocalizations.possession, homeStats.possessionPercentage ?? 0, awayStats.possessionPercentage ?? 0, home, away, unit: '%', isPercentage: true),
          _buildStatRowWithPercentage(context, appLocalizations.totalShots, homeStats.totalShots ?? 0, awayStats.totalShots ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.shotsOnTarget, homeStats.shotsOnTarget ?? 0, awayStats.shotsOnTarget ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.expectedGoalsXG, homeStats.expectedGoals ?? 0.0, awayStats.expectedGoals ?? 0.0, home, away, isPercentage: true),
          _buildStatRowWithPercentage(context, appLocalizations.pressures, homeStats.pressures ?? 0, awayStats.pressures ?? 0, home, away),
          _buildStatRowWithPercentage(context, appLocalizations.final3rdPasses, homeStats.finalThirdPasses ?? 0, awayStats.finalThirdPasses ?? 0, home, away),
          const SizedBox(height: AppSpacing.l),
          
          // Advanced Analysis Section with Team Toggle
          Text(
            "Advanced Analysis",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.s),
          Center(
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text("Home"), icon: const Icon(Icons.home_outlined)),
                ButtonSegment(value: 1, label: Text("Away"), icon: const Icon(Icons.outbound_outlined)),
              ],
              selected: {_selectedTeamIndex},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedTeamIndex = newSelection.first;
                });
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            "Viewing analysis for: $selectedTeamName",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.m),

          if (selectedStats.passNetworkData != null) ...[
            Text("Pass Network", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            PassNetworkVisualizer(passNetworkData: selectedStats.passNetworkData!),
            const SizedBox(height: AppSpacing.m),
          ],
          if (selectedStats.zoneAnalysisData != null) ...[
            Text("Pitch Division Power Analysis", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            PitchDivisionWidget(zoneData: selectedStats.zoneAnalysisData!),
            const SizedBox(height: AppSpacing.m),
          ],
          if (selectedStats.tacticalWeaknessData != null) ...[
            Text("Tactical Insights", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTacticalInsight(
              context,
              "Detected Formation",
              selectedStats.defensiveBlockPatterns?['out_of_possession_formation'] ?? "Unknown",
              Icons.grid_3x3,
            ),
            const SizedBox(height: 8),
            _buildTacticalInsight(
              context,
              "Defensive Weakness",
              "${selectedStats.tacticalWeaknessData!['exposed_defender'] ?? 'None'} (${selectedStats.tacticalWeaknessData!['weak_side'] ?? ''})",
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTacticalInsight(BuildContext context, String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRowWithPercentage(
      BuildContext context, String metric, num homeValue, num awayValue, TeamLineup homeLineup, TeamLineup awayLineup,
      {String? unit, bool isPercentage = false}) {
    final total = homeValue + awayValue;
    final homePercentage = total > 0 ? (homeValue / total) : 0.0;

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
              onTap: () => widget.showPlayerStatsDialog(context, stat, player),
            );
          }).toList(),
        ],
      ),
    );
  }
}
