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
import 'package:frontend/features/match_statistics/presentation/match_details_overview.dart';
import 'package:frontend/features/match_statistics/presentation/match_lineups_page.dart';
import 'package:frontend/features/match_statistics/presentation/match_statistics_page.dart';
import 'package:frontend/models/match_note.dart';
import 'package:frontend/services/note_service.dart';
import 'package:frontend/services/api_client.dart';

import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/widgets/custom_card.dart';

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
    _detailsFuture = Provider.of<MatchService>(context, listen: false).getMatchDetails(widget.match.id);
    _tabController = TabController(length: 4, vsync: this);
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
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: appLocalizations.eventTimeline),
            Tab(text: appLocalizations.lineups),
            Tab(text: appLocalizations.statistics),
            Tab(text: appLocalizations.notes),
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventTimeline(details.events, details.homeLineup, details.awayLineup),
              MatchLineupsPage(
                homeLineup: details.homeLineup,
                awayLineup: details.awayLineup,
                playerStats: details.playerStats,
                events: details.events,
                showPlayerStatsDialog: _showPlayerStatsDialog,
              ),
              MatchStatisticsPage(
                teamStats: details.teamStats,
                homeLineup: details.homeLineup,
                awayLineup: details.awayLineup,
                playerStats: details.playerStats,
                events: details.events,
                showPlayerStatsDialog: _showPlayerStatsDialog,
              ),
              _buildNotesTab(appLocalizations),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Match match) {
    final appLocalizations = AppLocalizations.of(context)!;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  match.homeTeam,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.s),
                  ),
                  child: Text(
                    '${match.homeScore} - ${match.awayScore}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  match.awayTeam,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(),
          const SizedBox(height: AppSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: AppSpacing.xs),
              Text(
                DateFormat.yMMMMd().format(match.date),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: AppSpacing.m),
              const Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
              const SizedBox(width: AppSpacing.xs),
              Text(
                match.eventName ?? appLocalizations.notAvailable,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: AppSpacing.xs),
              Text(
                match.venue ?? appLocalizations.notAvailable,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTimeline(List<MatchEvent> events, TeamLineup home, TeamLineup away) {
    final appLocalizations = AppLocalizations.of(context)!;
    String getPlayerName(String? playerId) {
      if (playerId == null) return appLocalizations.notAvailable;
      final allPlayers = [...home.players, ...away.players];
      return allPlayers.firstWhere((p) => p.id == playerId, orElse: () => PlayerWithPosition(id: '', name: appLocalizations.unknown)).name;
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        _buildHeader(widget.match),
        const SizedBox(height: AppSpacing.m),
        Text(
          appLocalizations.eventTimeline,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.s),
        ...events.map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${event.minute}\'',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.eventType.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          getPlayerName(event.playerId),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _getEventIcon(event.eventType),
                    color: _getEventColor(event.eventType),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Icons.sports_soccer;
      case 'yellow_card':
        return Icons.square;
      case 'red_card':
        return Icons.square;
      case 'substitution':
        return Icons.swap_horiz;
      default:
        return Icons.event_note;
    }
  }

  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Colors.green;
      case 'yellow_card':
        return Colors.amber;
      case 'red_card':
        return Colors.red;
      case 'substitution':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.m)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerProfileScreen(player: player),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.m)),
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
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${player.position ?? appLocalizations.notAvailable} - #${player.jerseyNumber ?? appLocalizations.notAvailable}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatRow(appLocalizations.minutesPlayed, stats.minutesPlayed?.toString()),
                      _buildStatRow(appLocalizations.shots, stats.shots?.toString()),
                      _buildStatRow(appLocalizations.shotsOnTarget, stats.shotsOnTarget?.toString()),
                      _buildStatRow(appLocalizations.passes, stats.passes?.toString()),
                      _buildStatRow(appLocalizations.accuratePasses, stats.accuratePasses?.toString()),
                      _buildStatRow(appLocalizations.tackles, stats.tackles?.toString()),
                      _buildStatRow(appLocalizations.keyPasses, stats.keyPasses?.toString()),
                      _buildStatRow(appLocalizations.expectedGoalsXG, stats.playerXg?.toStringAsFixed(2)),
                      _buildStatRow(appLocalizations.progressiveCarries, stats.progressiveCarries?.toString()),
                      _buildStatRow(appLocalizations.defensiveCoverage, '${stats.defensiveCoverageKm}${appLocalizations.km}'),
                      _buildStatRow(appLocalizations.rating, '${stats.rating?.toStringAsFixed(1)}${appLocalizations.outOf10}', isBold: true),
                      const SizedBox(height: AppSpacing.m),
                      Text(appLocalizations.notes, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        stats.notes ?? appLocalizations.noNotesAvailable,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      ),
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

  Widget _buildNotesTab(AppLocalizations appLocalizations) {
    return FutureBuilder<List<MatchNote>>(
      future: Provider.of<NoteService>(context, listen: false).getMatchNotes(widget.match.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${appLocalizations.errorWithMessage(snapshot.error.toString())}'));
        }
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return Center(child: Text(appLocalizations.noNotesAvailable));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return CustomCard(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getNoteTypeColor(note.noteType, context).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          note.noteType.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getNoteTypeColor(note.noteType, context),
                          ),
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().add_Hm().format(note.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(note.content, style: Theme.of(context).textTheme.bodyMedium),
                  if (note.authorName != null) ...[
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      '${note.authorName} (${note.authorRole ?? "Staff"})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getNoteTypeColor(NoteType type, BuildContext context) {
    switch (type) {
      case NoteType.preMatch:
        return Colors.blue;
      case NoteType.liveReaction:
        return Colors.orange;
      case NoteType.tactical:
        return Colors.purple;
    }
  }

  Widget _buildStatRow(String label, String? value, {bool isBold = false}) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value ?? appLocalizations.notAvailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isBold ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}