import 'package:flutter/material.dart';
import 'package:frontend/features/matches/presentation/add_match_screen.dart';
import 'package:frontend/services/event_service.dart';
import 'package:frontend/models/event.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/services/match_service.dart';
import 'package:frontend/features/matches/presentation/add_event_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/l10n/app_localizations.dart'; // New import

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  late Future<List<Event>> _eventsFuture;
  late Future<List<Match>> _matchesFuture;
  Event? _selectedEvent;
  late TabController _tabController;
  Event? _allEventsFilter; // Made nullable

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _eventsFuture = Future.value([]);
    _matchesFuture = Future.value([]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _allEventsFilter = Event(id: 'all', name: AppLocalizations.of(context)!.allMatches);
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
      _matchesFuture = matchService.getMatches(
        eventId: (_selectedEvent?.id == _allEventsFilter!.id) ? null : _selectedEvent?.id,
      );
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.matches),
        bottom: TabBar(
          controller: _tabController,
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
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${appLocalizations.errorLoadingEvents} ${snapshot.error}'));
                }

                final events = [_allEventsFilter!, ...?snapshot.data]; // Use _allEventsFilter!

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: appLocalizations.filterByEvent),
                    value: _selectedEvent?.id,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEvent = events.firstWhere((e) => e.id == newValue, orElse: () => _allEventsFilter!); // Use _allEventsFilter!
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
                  final upcomingMatches = matches.where((m) => m.date.isAfter(now)).toList();
                  final pastMatches = matches.where((m) => !m.date.isAfter(now)).toList();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMatchesList(BuildContext context, List<Match> matches) {
    final appLocalizations = AppLocalizations.of(context)!;
    if (matches.isEmpty) {
      return Center(child: Text(appLocalizations.noMatchesInCategory));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).cardColor,
          child: ListTile(
            onTap: () {
              if (match.status == 'upcoming') {
                context.goNamed('match-details', extra: match);
              } else {
                context.goNamed('match-statistics', extra: match);
              }
            },
            leading: Icon(
              Icons.emoji_events,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${match.homeScore} - ${match.awayScore}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.awayTeam,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMd().add_jm().format(match.date),
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (match.eventName != null)
                    Text(
                      '${appLocalizations.event} ${match.eventName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}