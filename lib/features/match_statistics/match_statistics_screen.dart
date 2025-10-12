import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/models/match_details.dart';
import 'package:frontend/models/match_event.dart';
import 'package:frontend/models/player_match_statistics.dart';
import 'package:frontend/models/player.dart'; // New import
import 'package:frontend/services/match_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/players/presentation/player_profile_screen.dart'; // New import
import 'package:frontend/services/api_client.dart'; // New import

import 'package:frontend/features/match_statistics/presentation/match_details_overview.dart';
import 'package:frontend/features/match_statistics/presentation/match_lineups_page.dart';
import 'package:frontend/features/match_statistics/presentation/match_statistics_page.dart';

class MatchStatisticsScreen extends StatefulWidget {
  final Match match;

  const MatchStatisticsScreen({super.key, required this.match});

  @override
  State<MatchStatisticsScreen> createState() => _MatchStatisticsScreenState();
}

class _MatchStatisticsScreenState extends State<MatchStatisticsScreen> with SingleTickerProviderStateMixin {
  late Future<MatchDetails> _detailsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _detailsFuture = Provider.of<MatchService>(context, listen: false)
        .getMatchDetails(widget.match.id);
    _tabController = TabController(length: 3, vsync: this); // Event Timeline, Lineups, Statistics
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.matchReport),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: appLocalizations.eventTimeline),
            Tab(text: appLocalizations.lineups),
            Tab(text: appLocalizations.statistics),
          ],
        ),
      ),
      body: FutureBuilder<MatchDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${appLocalizations.errorWithMessage(snapshot.error.toString())}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text(appLocalizations.noDetailsFoundForThisMatch));
          }

          final details = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Event Timeline Tab
                    _buildEventTimeline(details.events, details.homeLineup, details.awayLineup),
                    // Lineups Tab
                    MatchLineupsPage(
                      homeLineup: details.homeLineup,
                      awayLineup: details.awayLineup,
                      playerStats: details.playerStats,
                      events: details.events,
                      showPlayerStatsDialog: _showPlayerStatsDialog,
                    ),
                    // Statistics Tab
                    MatchStatisticsPage(
                      teamStats: details.teamStats,
                      homeLineup: details.homeLineup,
                      awayLineup: details.awayLineup,
                      playerStats: details.playerStats,
                      events: details.events,
                      showPlayerStatsDialog: _showPlayerStatsDialog,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Match match) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${match.homeTeam} ${match.homeScore} - ${match.awayScore} ${match.awayTeam}',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${DateFormat.yMMMMd().format(match.date)} | ${match.eventName ?? appLocalizations.notAvailable} | ${match.status.toUpperCase()}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '${appLocalizations.venue} ${match.venue ?? appLocalizations.notAvailable}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildEventTimeline(List<MatchEvent> events, TeamLineup home, TeamLineup away) {
    final appLocalizations = AppLocalizations.of(context)!;
    String getPlayerName(String? playerId) {
      if (playerId == null) return appLocalizations.notAvailable;
      final allPlayers = [...home.players, ...away.players];
      return allPlayers.firstWhere((p) => p.id == playerId, orElse: () => PlayerWithPosition(id: '', name: appLocalizations.unknown)).name;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildHeader(widget.match), // Use widget.match to get match info
        ),
        Expanded(
          child: _buildSectionCard(
            title: appLocalizations.eventTimeline,
            child: SingleChildScrollView(
              child: Column(
                children: events.map((event) {
                  return ListTile(
                    leading: Text('${event.minute}\''),
                    title: Text('${event.eventType.toUpperCase()} - ${getPlayerName(event.playerId)}'),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPlayerStatsDialog(BuildContext context, PlayerMatchStatistics stats, Player player) {
    final appLocalizations = AppLocalizations.of(context)!;
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    String? imageUrl = player.imageUrl;
    ImageProvider? backgroundImage;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        backgroundImage = NetworkImage(imageUrl);
      } else {
        backgroundImage = NetworkImage('${apiClient.baseUrl.replaceAll('/api', '')}$imageUrl');
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // Remove default padding
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // New Header Section (Clickable)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerProfileScreen(player: player),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: backgroundImage,
                          child: backgroundImage == null
                              ? Text(
                                  player.name.isNotEmpty ? player.name[0] : '?',
                                  style: const TextStyle(fontSize: 24, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                              ),
                              Text(
                                '${player.position ?? appLocalizations.notAvailable} - #${player.jerseyNumber ?? appLocalizations.notAvailable}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
                      ],
                    ),
                  ),
                ),
                // Match Statistics Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${appLocalizations.minutesPlayed} ${stats.minutesPlayed ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.shots} ${stats.shots ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.shotsOnTarget} ${stats.shotsOnTarget ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.passes} ${stats.passes ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.accuratePasses} ${stats.accuratePasses ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.tackles} ${stats.tackles ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.keyPasses} ${stats.keyPasses ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.expectedGoalsXG} ${stats.playerXg?.toStringAsFixed(2) ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.progressiveCarries} ${stats.progressiveCarries ?? appLocalizations.notAvailable}'),
                      Text('${appLocalizations.defensiveCoverage} ${stats.defensiveCoverageKm}${appLocalizations.km}'),
                      Text('${appLocalizations.rating} ${stats.rating?.toStringAsFixed(1) ?? appLocalizations.notAvailable}${appLocalizations.outOf10}'),
                      const SizedBox(height: 10),
                      Text('${appLocalizations.notes}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(stats.notes ?? appLocalizations.noNotesAvailable),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
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
            Expanded(
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}