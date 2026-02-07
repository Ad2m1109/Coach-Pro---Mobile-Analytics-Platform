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
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/models/match_note.dart';
import 'package:frontend/services/note_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:intl/intl.dart';

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

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  late Future<List<Player>> _playersFuture;
  late Future<List<model.Formation>> _formationsFuture;
  late Future<List<MatchLineup>> _lineupFuture;
  late Future<List<MatchNote>> _notesFuture;
  late TabController _tabController;
  bool _isInitialSetupDone = false;

  final Map<int, Player> _assignedPlayers = {};
  model.Formation? _selectedFormation;
  List<Offset> _currentFormationOffsets = [];

  @override
  void initState() {
    super.initState();
    _playersFuture = Provider.of<PlayerService>(context, listen: false).getPlayers();
    _formationsFuture = Provider.of<FormationService>(context, listen: false).getFormations();
    _lineupFuture = Provider.of<MatchLineupService>(context, listen: false).getLineups(matchId: widget.match.id);
    _notesFuture = Provider.of<NoteService>(context, listen: false).getMatchNotes(widget.match.id);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = Provider.of<NoteService>(context, listen: false).getMatchNotes(widget.match.id);
    });
  }

  Future<void> _deleteNote(String id) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      await Provider.of<NoteService>(context, listen: false).deleteNote(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.noteCreatedSuccessfully)), // Note: Using created successfully as a placeholder, might need a generic success string
      );
      _refreshNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.failedToCreateNote(e.toString())}')),
      );
    }
  }

  void _onFormationChanged(model.Formation? newFormation) {
    if (newFormation == null || newFormation.id == _selectedFormation?.id) {
      return;
    }

    setState(() {
      _selectedFormation = newFormation;
      if (FormationPresets.presets.containsKey(newFormation.name)) {
        _currentFormationOffsets = FormationPresets.presets[newFormation.name]!;
      } else {
        _currentFormationOffsets = [];
      }
    });
  }

  void _setupInitialState(List<Player> allPlayers, List<model.Formation> formations, List<MatchLineup> savedLineups) {
    if (savedLineups.isEmpty) return;

    final formationId = savedLineups.first.formationId;
    final initialFormation = formations.firstWhereOrNull((f) => f.id == formationId);

    if (initialFormation != null) {
      _selectedFormation = initialFormation;
      _currentFormationOffsets = FormationPresets.presets[initialFormation.name] ?? [];

      for (final lineupEntry in savedLineups) {
        final player = allPlayers.firstWhereOrNull((p) => p.id == lineupEntry.playerId);
        if (player == null || lineupEntry.positionInFormation == null) continue;

        final posParts = lineupEntry.positionInFormation!.split(',');
        if (posParts.length != 2) continue;

        final offset = Offset(double.parse(posParts[0]), double.parse(posParts[1]));

        final index = _currentFormationOffsets.indexWhere((presetOffset) => (presetOffset.dx - offset.dx).abs() < 0.001 && (presetOffset.dy - offset.dy).abs() < 0.001);

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
      final existingLineups = await matchLineupService.getLineups(matchId: widget.match.id);
      final lineupsToDelete = existingLineups.where((lu) => lu.teamId == teamId).toList();
      for (final lineup in lineupsToDelete) {
        await matchLineupService.deleteLineup(lineup.id);
      }

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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: appLocalizations.lineups),
            Tab(text: appLocalizations.tacticalNotes),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFormation,
            tooltip: appLocalizations.saveFormation,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormationTab(appLocalizations),
          _buildNotesTab(appLocalizations),
        ],
      ),
    );
  }

  Widget _buildFormationTab(AppLocalizations appLocalizations) {
    return FutureBuilder<List<dynamic>>(
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

          final availablePlayers = allPlayers.where((p) => !_assignedPlayers.containsValue(p)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: DropdownButtonFormField<model.Formation>(
                  decoration: InputDecoration(
                    labelText: appLocalizations.selectFormation,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                  ),
                  value: _selectedFormation,
                  onChanged: _onFormationChanged,
                  items: formations.where((f) => FormationPresets.presets.containsKey(f.name)).map<DropdownMenuItem<model.Formation>>((f) {
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
                    final fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return Stack(
                      children: [
                        CustomPaint(
                          size: fieldSize,
                          painter: SoccerFieldPainter(
                            lineColor: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        ...List.generate(_currentFormationOffsets.length, (index) {
                          final position = _currentFormationOffsets[index];
                          final assignedPlayer = _assignedPlayers[index];
                          final pixelPosition = Offset(position.dx * fieldSize.width, position.dy * fieldSize.height);

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
                                bool isGkSpot = index == 0;
                                bool isPlayerGk = details.data.position == 'GK';
                                return isGkSpot == isPlayerGk;
                              },
                              onAcceptWithDetails: (details) {
                                setState(() {
                                  _assignedPlayers.removeWhere((key, value) => value.id == details.data.id);
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
              Container(
                height: 110,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, index) {
                    final player = availablePlayers[index];
                    final playerMarker = _buildDraggablePlayer(player);
                    return Draggable<Player>(
                      data: player,
                      feedback: Material(color: Colors.transparent, child: playerMarker),
                      childWhenDragging: Opacity(opacity: 0.3, child: playerMarker),
                      child: playerMarker,
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _buildNotesTab(AppLocalizations appLocalizations) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<MatchNote>>(
            future: _notesFuture,
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
                  return Dismissible(
                    key: ValueKey(note.id),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      _deleteNote(note.id);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: CustomCard(
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
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  note.noteType.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: ElevatedButton.icon(
            onPressed: () => _showAddNoteDialog(appLocalizations),
            icon: const Icon(Icons.add_comment),
            label: Text(appLocalizations.addNote),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddNoteDialog(AppLocalizations appLocalizations) async {
    final contentController = TextEditingController();
    NoteType selectedType = NoteType.tactical;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(appLocalizations.addNote),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<NoteType>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: appLocalizations.noteType),
                    items: NoteType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: appLocalizations.enterNoteContent,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.isEmpty) return;
                    
                    final noteService = Provider.of<NoteService>(context, listen: false);
                    try {
                      final newNoteSource = MatchNote(
                        id: '',
                        matchId: widget.match.id,
                        userId: '', // Set by backend
                        content: contentController.text,
                        noteType: selectedType,
                        videoTimestamp: 0.0,
                        createdAt: DateTime.now(),
                      );
                      await noteService.createNote(newNoteSource);
                      if (mounted) {
                        Navigator.pop(context);
                        _refreshNotes();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalizations.noteCreatedSuccessfully)),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appLocalizations.failedToCreateNote(e.toString()))),
                        );
                      }
                    }
                  },
                  child: Text(appLocalizations.saveNote),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerMarker(Player player, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: player.position == 'GK' ? Colors.orange.shade700 : Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                player.jerseyNumber?.toString() ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              player.name,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(int index) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (index == 0 ? Colors.orange.shade900 : Colors.black).withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 2, style: BorderStyle.solid),
      ),
      child: Center(
        child: Icon(
          index == 0 ? Icons.pan_tool : Icons.add,
          color: Colors.white54,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDraggablePlayer(Player player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: player.position == 'GK' ? Colors.orange.shade700 : Theme.of(context).colorScheme.secondary,
            child: Text(
              player.jerseyNumber?.toString() ?? '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              player.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
