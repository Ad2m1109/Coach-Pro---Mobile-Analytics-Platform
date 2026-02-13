import 'package:flutter/material.dart';
import 'package:frontend/features/matches/presentation/add_match_screen.dart';
import 'package:frontend/services/event_service.dart';
import 'package:frontend/models/event.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/services/match_service.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/services/api_client.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Event>> _eventsFuture;
  late Future<List<Match>> _matchesFuture;
  Event? _selectedEvent;
  late TabController _tabController;
  Event? _allEventsFilter;
  final Map<String, Future<Map<String, dynamic>?>> _analysisStatusFutures = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _eventsFuture = Future.value([]);
    _matchesFuture = Future.value([]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _allEventsFilter = Event(
          id: 'all',
          name: AppLocalizations.of(context)!.allMatches,
        );
        if (_selectedEvent == null) {
          _selectedEvent = _allEventsFilter;
        }
        _loadEventsAndMatches();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadEventsAndMatches() {
    final eventService = Provider.of<EventService>(context, listen: false);
    _eventsFuture = eventService.getEvents();
    setState(() {
      _selectedEvent = _allEventsFilter;
      _loadMatches();
    });
  }

  void _loadMatches() {
    final matchService = Provider.of<MatchService>(context, listen: false);
    setState(() {
      _analysisStatusFutures.clear();
      _matchesFuture = matchService.getMatches(
        eventId: (_selectedEvent?.id == _allEventsFilter!.id)
            ? null
            : _selectedEvent?.id,
      );
    });
  }

  Future<Map<String, dynamic>?> _loadAnalysisForMatch(String matchId) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final response =
        await apiClient.get('/matches/$matchId/analysis')
            as Map<String, dynamic>;
    if ((response['status'] ?? '').toString().toUpperCase() == 'NO_ANALYSIS') {
      return null;
    }
    return response;
  }

  Future<Map<String, dynamic>?> _analysisFutureForMatch(String matchId) {
    return _analysisStatusFutures.putIfAbsent(
      matchId,
      () => _loadAnalysisForMatch(matchId),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.grey;
      case 'PROCESSING':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMatchScreen()),
    );

    if (result == true) {
      _loadEventsAndMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final canEdit = authService.hasPermission('edit');

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.matches),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: appLocalizations.upcoming),
            Tab(text: appLocalizations.past),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.m),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${appLocalizations.errorLoadingEvents} ${snapshot.error}',
                    ),
                  );
                }

                final events = [_allEventsFilter!, ...?snapshot.data];

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: appLocalizations.filterByEvent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                    ),
                    value: _selectedEvent?.id,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEvent = events.firstWhere(
                          (e) => e.id == newValue,
                          orElse: () => _allEventsFilter!,
                        );
                        _loadMatches();
                      });
                    },
                    items: events.map<DropdownMenuItem<String>>((Event event) {
                      return DropdownMenuItem<String>(
                        value: event.id,
                        child: Text(event.name),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            Expanded(
              child: FutureBuilder<List<Match>>(
                future: _matchesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(appLocalizations.noMatchesFound));
                  }

                  final matches = snapshot.data!;
                  final now = DateTime.now();
                  final upcomingMatches = matches
                      .where((m) => m.date.isAfter(now))
                      .toList();
                  final pastMatches = matches
                      .where((m) => !m.date.isAfter(now))
                      .toList();
                  pastMatches.sort((a, b) => b.date.compareTo(a.date));

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMatchesList(context, upcomingMatches),
                      _buildMatchesList(context, pastMatches),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: _navigateAndRefresh,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMatchesList(BuildContext context, List<Match> matches) {
    final appLocalizations = AppLocalizations.of(context)!;
    if (matches.isEmpty) {
      return Center(child: Text(appLocalizations.noMatchesInCategory));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          child: CustomCard(
            onTap: () {
              if (match.status == 'upcoming') {
                context.goNamed('match-details', extra: match);
              } else {
                context.goNamed('match-statistics', extra: match);
              }
            },
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      match.homeTeam,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                    ),
                    child: Text(
                      '${match.homeScore} - ${match.awayScore}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.awayTeam,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat.yMd().add_jm().format(match.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (match.eventName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${appLocalizations.event} ${match.eventName}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _analysisFutureForMatch(match.id),
                      builder: (context, analysisSnapshot) {
                        if (!analysisSnapshot.hasData ||
                            analysisSnapshot.data == null) {
                          return const SizedBox.shrink();
                        }
                        final analysis = analysisSnapshot.data!;
                        final status = (analysis['status'] ?? '').toString();
                        final progress = ((analysis['progress'] ?? 0) as num)
                            .toDouble();

                        return Row(
                          children: [
                            Chip(
                              label: Text(status),
                              backgroundColor: _getStatusColor(
                                status,
                              ).withOpacity(0.12),
                              side: BorderSide(color: _getStatusColor(status)),
                            ),
                            if (progress > 0 && progress < 1) ...[
                              const SizedBox(width: AppSpacing.s),
                              Text('${(progress * 100).toStringAsFixed(0)}%'),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
