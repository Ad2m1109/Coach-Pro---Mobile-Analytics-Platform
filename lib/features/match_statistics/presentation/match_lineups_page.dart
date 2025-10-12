import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/match_details.dart';
import 'package:frontend/models/player_match_statistics.dart';
import 'package:frontend/widgets/soccer_field_painter.dart';
import 'package:frontend/models/match_event.dart'; // New import
import 'package:frontend/models/player.dart'; // New import

class MatchLineupsPage extends StatefulWidget {
  final TeamLineup homeLineup;
  final TeamLineup awayLineup;
  final List<PlayerMatchStatistics> playerStats;
  final List<MatchEvent> events;
  final Function(BuildContext context, PlayerMatchStatistics stats, Player player) showPlayerStatsDialog;

  const MatchLineupsPage({super.key, required this.homeLineup, required this.awayLineup, required this.playerStats, required this.events, required this.showPlayerStatsDialog});

  @override
  State<MatchLineupsPage> createState() => _MatchLineupsPageState();
}

enum PlayerMetric { rating, age, height, weight }

class _MatchLineupsPageState extends State<MatchLineupsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlayerMetric _selectedMetric = PlayerMetric.rating; // Default
  double? _averageMetric;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged); // Listen for tab changes
    _calculateAverage(); // Calculate initial average
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recalculate average if dependencies change (e.g., data updates)
    _calculateAverage();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _calculateAverage(); // Recalculate average when tab changes
    }
  }

  void _calculateAverage() {
    final currentPlayers = _tabController.index == 0
        ? widget.homeLineup.players
        : widget.awayLineup.players;

    if (currentPlayers.isEmpty) {
      setState(() {
        _averageMetric = null;
      });
      return;
    }

    double sum = 0;
    int count = 0;

    for (final playerWithPos in currentPlayers) {
      final playerStat = widget.playerStats.firstWhere(
        (stat) => stat.playerId == playerWithPos.id,
        orElse: () => PlayerMatchStatistics(id: '', matchId: '', playerId: ''),
      );

      switch (_selectedMetric) {
        case PlayerMetric.rating:
          if (playerStat.rating != null) {
            sum += playerStat.rating!;
            count++;
          }
          break;
        case PlayerMetric.age:
          if (playerWithPos.birthDate != null) {
            final age = DateTime.now().year - playerWithPos.birthDate!.year;
            sum += age;
            count++;
          }
          break;
        case PlayerMetric.height:
          if (playerWithPos.heightCm != null) {
            sum += playerWithPos.heightCm!;
            count++;
          }
          break;
        case PlayerMetric.weight:
          if (playerWithPos.weightKg != null) {
            sum += playerWithPos.weightKg!;
            count++;
          }
          break;
      }
    }

    setState(() {
      _averageMetric = count > 0 ? sum / count : null;
    });
  }

  String _getMetricName(PlayerMetric metric, AppLocalizations localizations) {
    switch (metric) {
      case PlayerMetric.rating:
        return localizations.rating.replaceAll(':', '');
      case PlayerMetric.age:
        return localizations.age;
      case PlayerMetric.height:
        return localizations.height;
      case PlayerMetric.weight:
        return localizations.weight;
    }
  }

  String _getMetricValue(PlayerWithPosition player, PlayerMatchStatistics stats) {
    final appLocalizations = AppLocalizations.of(context)!;
    switch (_selectedMetric) {
      case PlayerMetric.rating:
        return stats.rating?.toStringAsFixed(1) ?? appLocalizations.notAvailable;
      case PlayerMetric.age:
        if (player.birthDate != null) {
          final age = DateTime.now().year - player.birthDate!.year;
          return age.toString();
        }
        return appLocalizations.notAvailable;
      case PlayerMetric.height:
        return player.heightCm?.toString() ?? appLocalizations.notAvailable;
      case PlayerMetric.weight:
        return player.weightKg?.toString() ?? appLocalizations.notAvailable;
    }
  }

  Color _getMetricBadgeColor(PlayerMetric metric) {
    switch (metric) {
      case PlayerMetric.rating: return Colors.red.shade700;
      case PlayerMetric.age: return Colors.blue.shade700;
      case PlayerMetric.height: return Colors.green.shade700;
      case PlayerMetric.weight: return Colors.teal.shade700;
    }
  }

  Color _getPlayerCircleColor(double? rating) {
    if (rating == null) return Colors.grey; // Default color for no rating

    if (rating < 6.0) {
      return Colors.red; // Red for bad
    } else if (rating >= 6.0 && rating <= 6.9) {
      return Colors.orange; // Orange for 6.0-6.9
    } else if (rating >= 7.0 && rating <= 8.4) {
      // Degradation of Green (7.0 to 8.4)
      // Map 7.0-8.4 to 0.0-1.0 for lerp
      final t = (rating - 7.0) / (8.4 - 7.0);
      return Color.lerp(Colors.lightGreen, Colors.green.shade800, t)!;
    } else { // rating > 8.5
      // Degradation of Blue (> 8.5)
      // Map 8.5-10.0 (assuming max 10) to 0.0-1.0 for lerp
      final t = (rating - 8.5) / (10.0 - 8.5);
      return Color.lerp(Colors.lightBlue, Colors.blue.shade800, t)!;
    }
  }

  MatchEvent? _getPlayerCard(String playerId) {
    final cardEvents = widget.events.where((event) =>
        event.playerId == playerId &&
        (event.eventType == 'yellow_card' || event.eventType == 'red_card'));
    // Return the last card event if multiple, or null
    return cardEvents.isNotEmpty ? cardEvents.last : null;
  }

  MatchEvent? _getPlayerSubstitution(String playerId) {
    final subEvents = widget.events.where((event) =>
        event.playerId == playerId &&
        (event.eventType == 'sub_in' || event.eventType == 'sub_out'));
    // Return the last sub event if multiple, or null
    return subEvents.isNotEmpty ? subEvents.last : null;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Builder(
                builder: (BuildContext context) {
                  final isSelected = _tabController.index == 0;
                  final isLightMode = Theme.of(context).brightness == Brightness.light;
                  return Text(
                    widget.homeLineup.teamName,
                    style: TextStyle(
                      color: isSelected && isLightMode ? Theme.of(context).colorScheme.primary : null,
                    ),
                  );
                },
              ),
            ),
            Tab(
              child: Builder(
                builder: (BuildContext context) {
                  final isSelected = _tabController.index == 1;
                  final isLightMode = Theme.of(context).brightness == Brightness.light;
                  return Text(
                    widget.awayLineup.teamName,
                    style: TextStyle(
                      color: isSelected && isLightMode ? Theme.of(context).colorScheme.primary : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: PlayerMetric.values.map((metric) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedMetric = metric;
                        _calculateAverage(); // Recalculate when metric changes
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMetric == metric
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      foregroundColor: _selectedMetric == metric
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    child: Text(_getMetricName(metric, appLocalizations)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _averageMetric != null
                    ? '${appLocalizations.average} ${_getMetricName(_selectedMetric, appLocalizations)}: ${_averageMetric!.toStringAsFixed(1)}'
                    : appLocalizations.averageNA,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFormationAndPlayerList(context, widget.homeLineup, widget.playerStats, true, widget.showPlayerStatsDialog),
              _buildFormationAndPlayerList(context, widget.awayLineup, widget.playerStats, false, widget.showPlayerStatsDialog),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormationAndPlayerList(BuildContext context, TeamLineup teamLineup, List<PlayerMatchStatistics> playerStats, bool isHomeTeam, Function(BuildContext context, PlayerMatchStatistics stats, Player player) showPlayerStatsDialog) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 400,
            child: LayoutBuilder(builder: (context, constraints) {
              final fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                children: [
                  CustomPaint(
                    size: fieldSize,
                    painter: SoccerFieldPainter(
                      lineColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  ...teamLineup.players.map((player) {
                    final position = _getPixelPositionFromNormalizedCoordinates(player.positionInFormation ?? '', fieldSize);
                    final playerStat = widget.playerStats.firstWhere((stat) => stat.playerId == player.id, orElse: () => PlayerMatchStatistics(id: '', matchId: '', playerId: ''));
                    final cardEvent = _getPlayerCard(player.id);
                    final subEvent = _getPlayerSubstitution(player.id);
                    return Positioned(
                      left: position.dx - 25, // Adjust to center the new column
                      top: position.dy - 25, // Adjust to center the new column
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none, // Allow content to overflow
                            children: [
                              GestureDetector(
                                onTap: () => showPlayerStatsDialog(context, playerStat, player),
                                child: Container(
                                  width: 40, // Circle diameter
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getPlayerCircleColor(playerStat.rating),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      player.jerseyNumber?.toString() ?? '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Metric badge
                              if (_getMetricValue(player, playerStat) != 'N/A')
                                Positioned(
                                  top: -5, // Slightly above the circle
                                  right: -5, // Slightly to the right of the circle
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Padding for the text
                                    decoration: BoxDecoration(
                                      color: _getMetricBadgeColor(_selectedMetric), // Dynamic color
                                      borderRadius: BorderRadius.circular(8), // Rounded corners
                                      border: Border.all(color: Colors.white, width: 1), // White border
                                    ),
                                    child: Text(
                                      _getMetricValue(player, playerStat), // Dynamic value
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              // Card Icon (Bottom-Right)
                              if (cardEvent != null)
                                Positioned(
                                  bottom: -5,
                                  right: -5,
                                  child: Icon(
                                    cardEvent.eventType == 'yellow_card'
                                        ? Icons.warning
                                        : Icons.gpp_bad, // Red card icon
                                    color: cardEvent.eventType == 'yellow_card'
                                        ? Colors.yellow.shade700
                                        : Colors.red.shade700,
                                    size: 20,
                                  ),
                                ),
                              // Substitution Icon (Bottom-Left)
                              if (subEvent != null)
                                Positioned(
                                  bottom: -5,
                                  left: -5,
                                  child: Icon(
                                    subEvent.eventType == 'sub_in'
                                        ? Icons.swap_horiz
                                        : Icons.swap_horiz, // Same icon for in/out for simplicity
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            player.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black,
                                  offset: Offset(1.0, 1.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                ],
              );
            }),
          ),
          const Divider(),
          _buildPlayerList(context, teamLineup.players, playerStats, showPlayerStatsDialog),
        ],
      ),
    );
  }

  Widget _buildPlayerList(BuildContext context, List<PlayerWithPosition> players, List<PlayerMatchStatistics> playerStats, Function(BuildContext context, PlayerMatchStatistics stats, Player player) showPlayerStatsDialog) {
    final appLocalizations = AppLocalizations.of(context)!;
    String getPlayerNationalityFlag(String? countryCode) {
      if (countryCode == null || countryCode.isEmpty) return '';
      return countryCode.toUpperCase().replaceAllMapped(RegExp(r'.'), (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397));
    }

    String getPlayerName(String playerId) {
      final allPlayers = [...widget.homeLineup.players, ...widget.awayLineup.players];
      return allPlayers.firstWhere((p) => p.id == playerId, orElse: () => PlayerWithPosition(id: '', name: appLocalizations.unknown)).name;
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final stat = playerStats.firstWhere((s) => s.playerId == player.id, orElse: () => PlayerMatchStatistics(id: '', matchId: '', playerId: ''));
        return ListTile(
          leading: Text('${player.jerseyNumber ?? '?'} ${getPlayerNationalityFlag(player.countryCode)}'),
          title: Text(player.name),
          subtitle: Text('${appLocalizations.minutesPlayed} ${stat.minutesPlayed ?? appLocalizations.notAvailable} | ${appLocalizations.rating} ${stat.rating?.toStringAsFixed(1) ?? appLocalizations.notAvailable}${appLocalizations.outOf10}'),
          onTap: () => showPlayerStatsDialog(context, stat, player),
        );
      },
    );
  }

  Offset _getPixelPositionFromNormalizedCoordinates(String normalizedCoords, Size fieldSize) {
    try {
      final parts = normalizedCoords.split(',');
      if (parts.length == 2) {
        final normalizedDx = double.parse(parts[0]);
        final normalizedDy = double.parse(parts[1]);
        return Offset(normalizedDx * fieldSize.width, normalizedDy * fieldSize.height);
      }
    } catch (e) {
      print('Error parsing normalized coordinates: $e');
    }
    // Fallback to center if parsing fails
    return Offset(fieldSize.width / 2, fieldSize.height / 2);
  }
}