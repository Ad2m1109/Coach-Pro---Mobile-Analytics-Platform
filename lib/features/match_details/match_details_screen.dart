import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/services/player_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/match_lineup.dart';
import 'package:frontend/services/match_lineup_service.dart';
import 'package:frontend/models/formation.dart' as model;
import 'package:frontend/services/formation_service.dart';
import 'package:frontend/widgets/soccer_field_painter.dart';

// Data for preset formations
class FormationPresets {
  static Map<String, List<Offset>> presets = {
    '4-3-3': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.3, 0.5), // LCM
      const Offset(0.5, 0.55), // CM
      const Offset(0.7, 0.5), // RCM
      const Offset(0.2, 0.25), // LW
      const Offset(0.8, 0.25), // RW
      const Offset(0.5, 0.15), // ST
    ],
    '4-4-2': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.2, 0.5), // LM
      const Offset(0.4, 0.5), // LCM
      const Offset(0.6, 0.5), // RCM
      const Offset(0.8, 0.5), // RM
      const Offset(0.35, 0.2), // LST
      const Offset(0.65, 0.2), // RST
    ],
    '3-5-2': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.25, 0.8), // LCB
      const Offset(0.5, 0.85), // CB
      const Offset(0.75, 0.8), // RCB
      const Offset(0.1, 0.5), // LWB
      const Offset(0.9, 0.5), // RWB
      const Offset(0.3, 0.55), // LCM
      const Offset(0.5, 0.6), // CDM
      const Offset(0.7, 0.55), // RCM
      const Offset(0.35, 0.25), // LF
      const Offset(0.65, 0.25), // RF
    ],
    '3-4-3': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.25, 0.8), // LCB
      const Offset(0.5, 0.85), // CB
      const Offset(0.75, 0.8), // RCB
      const Offset(0.15, 0.55), // LM
      const Offset(0.4, 0.6), // LCM
      const Offset(0.6, 0.6), // RCM
      const Offset(0.85, 0.55), // RM
      const Offset(0.2, 0.2), // LW
      const Offset(0.5, 0.15), // ST
      const Offset(0.8, 0.2), // RW
    ],
    '4-2-4': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.4, 0.5), // CDM1
      const Offset(0.6, 0.5), // CDM2
      const Offset(0.15, 0.2), // LW
      const Offset(0.35, 0.15), // LST
      const Offset(0.65, 0.15), // RST
      const Offset(0.85, 0.2), // RW
    ],
    '4-2-3-1': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.4, 0.6), // CDM1
      const Offset(0.6, 0.6), // CDM2
      const Offset(0.2, 0.35), // LAM
      const Offset(0.5, 0.3), // CAM
      const Offset(0.8, 0.35), // RAM
      const Offset(0.5, 0.15), // ST
    ],
    '4-4-1-1': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.15, 0.5), // LM
      const Offset(0.35, 0.55), // LCM
      const Offset(0.65, 0.55), // RCM
      const Offset(0.85, 0.5), // RM
      const Offset(0.5, 0.3), // CAM
      const Offset(0.5, 0.15), // ST
    ],
    '4-2-2-2 (Narrow)': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.4, 0.55), // CM1
      const Offset(0.6, 0.55), // CM2
      const Offset(0.3, 0.35), // AM1
      const Offset(0.7, 0.35), // AM2
      const Offset(0.35, 0.15), // ST1
      const Offset(0.65, 0.15), // ST2
    ],
    '5-3-2': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.1, 0.75), // LWB
      const Offset(0.3, 0.8), // LCB
      const Offset(0.5, 0.85), // CB
      const Offset(0.7, 0.8), // RCB
      const Offset(0.9, 0.75), // RWB
      const Offset(0.3, 0.55), // LCM
      const Offset(0.5, 0.6), // CM
      const Offset(0.7, 0.55), // RCM
      const Offset(0.35, 0.2), // ST1
      const Offset(0.65, 0.2), // ST2
    ],
    '5-4-1': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.1, 0.75), // LWB
      const Offset(0.3, 0.8), // LCB
      const Offset(0.5, 0.85), // CB
      const Offset(0.7, 0.8), // RCB
      const Offset(0.9, 0.75), // RWB
      const Offset(0.15, 0.5), // LM
      const Offset(0.4, 0.55), // LCM
      const Offset(0.6, 0.55), // RCM
      const Offset(0.85, 0.5), // RM
      const Offset(0.5, 0.15), // ST
    ],
    '4-5-1': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.15, 0.5), // LM
      const Offset(0.3, 0.55), // LCM
      const Offset(0.5, 0.6), // CDM
      const Offset(0.7, 0.55), // RCM
      const Offset(0.85, 0.5), // RM
      const Offset(0.5, 0.15), // ST
    ],
    '4-1-4-1': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.5, 0.65), // CDM
      const Offset(0.15, 0.45), // LM
      const Offset(0.35, 0.5), // LCM
      const Offset(0.65, 0.5), // RCM
      const Offset(0.85, 0.45), // RM
      const Offset(0.5, 0.15), // ST
    ],
    '4-2-2-2 (Brazil)': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.4, 0.6), // CDM1
      const Offset(0.6, 0.6), // CDM2
      const Offset(0.25, 0.35), // LAM
      const Offset(0.75, 0.35), // RAM
      const Offset(0.35, 0.15), // ST1
      const Offset(0.65, 0.15), // ST2
    ],
    '3-2-2-3': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.25, 0.8), // LCB
      const Offset(0.5, 0.85), // CB
      const Offset(0.75, 0.8), // RCB
      const Offset(0.4, 0.6), // CDM1
      const Offset(0.6, 0.6), // CDM2
      const Offset(0.3, 0.4), // CAM1
      const Offset(0.7, 0.4), // CAM2
      const Offset(0.2, 0.15), // LW
      const Offset(0.5, 0.1), // ST
      const Offset(0.8, 0.15), // RW
    ],
    '3-3-1-3': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.25, 0.8), // LCB
      const Offset(0.5, 0.85), // CB
      const Offset(0.75, 0.8), // RCB
      const Offset(0.2, 0.6), // LM
      const Offset(0.5, 0.65), // CM
      const Offset(0.8, 0.6), // RM
      const Offset(0.5, 0.4), // CAM
      const Offset(0.2, 0.15), // LW
      const Offset(0.5, 0.1), // ST
      const Offset(0.8, 0.15), // RW
    ],
    '4-4-2 Diamond': [
      const Offset(0.5, 0.9), // GK
      const Offset(0.15, 0.75), // LB
      const Offset(0.35, 0.8), // LCB
      const Offset(0.65, 0.8), // RCB
      const Offset(0.85, 0.75), // RB
      const Offset(0.5, 0.65), // CDM
      const Offset(0.3, 0.5), // LCM
      const Offset(0.7, 0.5), // RCM
      const Offset(0.5, 0.35), // CAM
      const Offset(0.35, 0.15), // ST1
      const Offset(0.65, 0.15), // ST2
    ],
  };
}

class MatchDetailsScreen extends StatefulWidget {
  final Match match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  late Future<List<Player>> _playersFuture;
  late Future<List<model.Formation>> _formationsFuture;
  late Future<List<MatchLineup>> _lineupFuture;
  bool _isInitialSetupDone = false;

  // Maps a position index (0-10) to an assigned Player
  final Map<int, Player> _assignedPlayers = {};
  model.Formation? _selectedFormation;
  List<Offset> _currentFormationOffsets = [];

  @override
  void initState() {
    super.initState();
    _playersFuture =
        Provider.of<PlayerService>(context, listen: false).getPlayers();
    _formationsFuture =
        Provider.of<FormationService>(context, listen: false).getFormations();
    _lineupFuture = Provider.of<MatchLineupService>(context, listen: false)
        .getLineups(matchId: widget.match.id);
  }

  void _onFormationChanged(model.Formation? newFormation) {
    if (newFormation == null || newFormation.id == _selectedFormation?.id) {
      return; // Do nothing if the formation is the same or null
    }

    setState(() {
      _selectedFormation = newFormation;
      if (FormationPresets.presets.containsKey(newFormation.name)) {
        _currentFormationOffsets = FormationPresets.presets[newFormation.name]!;
      } else {
        _currentFormationOffsets = [];
      }
      // NOTE: This will naively remap players based on their index.
      // The user can then drag and drop to correct positions.
    });
  }

  void _setupInitialState(List<Player> allPlayers,
      List<model.Formation> formations, List<MatchLineup> savedLineups) {
    if (savedLineups.isEmpty) return;

    final formationId = savedLineups.first.formationId;
    final initialFormation =
        formations.firstWhereOrNull((f) => f.id == formationId);

    if (initialFormation != null) {
      _selectedFormation = initialFormation;
      _currentFormationOffsets =
          FormationPresets.presets[initialFormation.name] ?? [];

      for (final lineupEntry in savedLineups) {
        final player =
            allPlayers.firstWhereOrNull((p) => p.id == lineupEntry.playerId);
        if (player == null || lineupEntry.positionInFormation == null) continue;

        final posParts = lineupEntry.positionInFormation!.split(',');
        if (posParts.length != 2) continue;

        final offset =
            Offset(double.parse(posParts[0]), double.parse(posParts[1]));

        // Find the index of this offset in the formation preset
        final index = _currentFormationOffsets.indexWhere((presetOffset) =>
            (presetOffset.dx - offset.dx).abs() < 0.001 &&
            (presetOffset.dy - offset.dy).abs() < 0.001);

        if (index != -1) {
          _assignedPlayers[index] = player;
        }
      }
    }
    _isInitialSetupDone = true;
  }

  Future<void> _saveFormation() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_selectedFormation == null || _currentFormationOffsets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.pleaseSelectAValidFormation)),
      );
      return;
    }
    if (_assignedPlayers.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.pleaseAssign11Players)),
      );
      return;
    }

    final matchLineupService = Provider.of<MatchLineupService>(context, listen: false);
    final teamId = widget.match.homeTeamId;
    bool success = true;

    try {
      // 1. Delete existing lineups for this match and team
      final existingLineups = await matchLineupService.getLineups(matchId: widget.match.id);
      final lineupsToDelete = existingLineups.where((lu) => lu.teamId == teamId).toList();
      for (final lineup in lineupsToDelete) {
        await matchLineupService.deleteLineup(lineup.id);
      }

      // 2. Create new lineups
      for (int i = 0; i < _currentFormationOffsets.length; i++) {
        final player = _assignedPlayers[i];
        final position = _currentFormationOffsets[i];

        if (player == null) continue;

        final newMatchLineup = MatchLineup(
          id: '',
          matchId: widget.match.id,
          teamId: teamId,
          formationId: _selectedFormation!.id,
          isStarting: true,
          playerId: player.id,
          positionInFormation: '${position.dx.toStringAsFixed(4)},${position.dy.toStringAsFixed(4)}',
        );

        await matchLineupService.createLineup(newMatchLineup);
      }
    } catch (e) {
      success = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.failedToSaveFormation(e.toString())}')),
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.formationSavedSuccessfully)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.match.homeTeam} ${appLocalizations.vs} ${widget.match.awayTeam}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFormation,
            tooltip: appLocalizations.saveFormation,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_playersFuture, _formationsFuture, _lineupFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${appLocalizations.errorWithMessage(snapshot.error.toString())}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text(appLocalizations.noDataFound));
          }

          final allPlayers = snapshot.data![0] as List<Player>;
          final formations = snapshot.data![1] as List<model.Formation>;
          final savedLineups = snapshot.data![2] as List<MatchLineup>;

          if (!_isInitialSetupDone) {
            _setupInitialState(allPlayers, formations, savedLineups);
          }

          // Filter out players already on the field
          final availablePlayers = allPlayers
              .where((p) => !_assignedPlayers.containsValue(p))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<model.Formation>(
                  decoration:
                      InputDecoration(labelText: appLocalizations.selectFormation),
                  value: _selectedFormation,
                  onChanged: _onFormationChanged,
                  items: formations
                      .where(
                          (f) => FormationPresets.presets.containsKey(f.name))
                      .map<DropdownMenuItem<model.Formation>>((f) {
                    return DropdownMenuItem<model.Formation>(
                      value: f,
                      child: Text(f.name),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldSize =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    return Stack(
                      children: [
                        CustomPaint(
                          size: fieldSize,
                          painter: SoccerFieldPainter(
                            lineColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        // Render placeholders and assigned players
                        ...List.generate(_currentFormationOffsets.length,
                            (index) {
                          final position = _currentFormationOffsets[index];
                          final assignedPlayer = _assignedPlayers[index];
                          final pixelPosition = Offset(
                              position.dx * fieldSize.width,
                              position.dy * fieldSize.height);

                          return Positioned(
                            left: pixelPosition.dx - 25,
                            top: pixelPosition.dy - 25,
                            child: DragTarget<Player>(
                              builder: (context, candidateData, rejectedData) {
                                return assignedPlayer != null
                                    ? _buildPlayerMarker(assignedPlayer, () {
                                        setState(() {
                                          _assignedPlayers.remove(index);
                                        });
                                      })
                                    : _buildPlaceholder(index);
                              },
                              onWillAcceptWithDetails: (details) {
                                // Prevent dropping a GK on a non-GK spot and vice-versa
                                bool isGkSpot = index == 0;
                                bool isPlayerGk = details.data.position == 'GK';
                                return isGkSpot == isPlayerGk;
                              },
                              onAcceptWithDetails: (details) {
                                setState(() {
                                  // If player was already assigned elsewhere, remove old assignment
                                  _assignedPlayers.removeWhere((key, value) =>
                                      value.id == details.data.id);
                                  // Assign player to the new spot
                                  _assignedPlayers[index] = details.data;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              // Available players list
              Container(
                height: 100,
                color: Theme.of(context).cardColor,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, index) {
                    final player = availablePlayers[index];
                    final playerMarker = _buildDraggablePlayer(player);
                    return Draggable<Player>(
                      data: player,
                      feedback: Material(
                          color: Colors.transparent, child: playerMarker),
                      childWhenDragging:
                          Opacity(opacity: 0.3, child: playerMarker),
                      child: playerMarker,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerMarker(Player player, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: player.position == 'GK'
                  ? Colors.orange.shade700
                  : Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Center(
              child: Text(
                player.jerseyNumber?.toString() ?? '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2.0, color: Colors.black)]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(int index) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (index == 0 ? Colors.orange.shade900 : Colors.black)
            .withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white54, width: 1, style: BorderStyle.solid),
      ),
      child: Center(
        child: Icon(
          index == 0 ? Icons.pan_tool : Icons.add,
          color: Colors.white54,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDraggablePlayer(Player player) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: player.position == 'GK'
                ? Colors.orange.shade700
                : Theme.of(context).colorScheme.secondary,
            child: Text(player.jerseyNumber?.toString() ?? '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(player.name,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
