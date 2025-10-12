import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/team_service.dart';

class TeamSettingsScreen extends StatefulWidget {
  const TeamSettingsScreen({super.key});

  @override
  State<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends State<TeamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<Team>> _teamsFuture; // Changed to List<Team>

  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _primaryColorController = TextEditingController();
  final TextEditingController _secondaryColorController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();

  Team? _selectedTeam; // To hold the team being edited/created

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  void _loadTeams() {
    final teamService = Provider.of<TeamService>(context, listen: false);
    _teamsFuture = teamService.getTeams();
    _teamsFuture.then((teams) {
      if (teams.isNotEmpty) {
        setState(() {
          _selectedTeam = teams.first; // Select the first team if available
          _populateControllers(_selectedTeam!); // Populate fields
        });
      }
    });
  }

  void _populateControllers(Team team) {
    _teamNameController.text = team.name;
    _primaryColorController.text = team.primaryColor ?? '';
    _secondaryColorController.text = team.secondaryColor ?? '';
    _logoUrlController.text = team.logoUrl ?? '';
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveTeamSettings() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final teamService = Provider.of<TeamService>(context, listen: false);

      final newTeamData = Team(
        id: _selectedTeam?.id ?? '', // Use existing ID or empty for new
        name: _teamNameController.text,
        primaryColor: _primaryColorController.text,
        secondaryColor: _secondaryColorController.text,
        logoUrl: _logoUrlController.text,
      );

      try {
        if (_selectedTeam == null) {
          // Create new team
          await teamService.createTeam(newTeamData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocalizations.teamCreatedSuccessfully)),
          );
        } else {
          // Update existing team
          // Note: TeamService.updateTeam is not yet implemented in backend/frontend
          // For now, we'll just show a message.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocalizations.teamUpdateNotImplemented)),
          );
        }
        _loadTeams(); // Reload teams after save/create
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocalizations.failedToSaveTeamSettings(e.toString())}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.teamSettings),
      ),
      body: FutureBuilder<List<Team>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // No teams found, show create new team form
            return _buildTeamForm(context, isCreating: true);
          }

          // Teams found, allow selection and editing
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<Team>(
                  decoration: InputDecoration(labelText: appLocalizations.selectTeam),
                  value: _selectedTeam,
                  onChanged: (Team? newValue) {
                    setState(() {
                      _selectedTeam = newValue;
                      if (newValue != null) {
                        _populateControllers(newValue);
                      }
                    });
                  },
                  items: snapshot.data!.map<DropdownMenuItem<Team>>((Team team) {
                    return DropdownMenuItem<Team>(
                      value: team,
                      child: Text(team.name),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: _buildTeamForm(context, isCreating: false), // Pass false as it's editing
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamForm(BuildContext context, {bool isCreating = false}) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            TextFormField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: appLocalizations.teamName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return appLocalizations.pleaseEnterTeamName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _primaryColorController,
              decoration: InputDecoration(
                labelText: appLocalizations.primaryColorHex,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return appLocalizations.pleaseEnterPrimaryColor;
                }
                if (!RegExp(r'^#([0-9A-Fa-f]{6})).hasMatch(value)) {
                  return appLocalizations.enterValidHexColor;
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _secondaryColorController,
              decoration: InputDecoration(
                labelText: appLocalizations.secondaryColorHex,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    !RegExp(r'^#([0-9A-Fa-f]{6})).hasMatch(value)) {
                  return appLocalizations.enterValidHexColor;
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _logoUrlController,
              decoration: InputDecoration(
                labelText: appLocalizations.logoUrl,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.isAbsolute) {
                    return appLocalizations.enterValidUrl;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _saveTeamSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Text(
                isCreating ? appLocalizations.createTeam : appLocalizations.saveChanges,
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}