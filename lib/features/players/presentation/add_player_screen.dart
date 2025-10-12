import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/services/player_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:frontend/services/team_service.dart'; // New import

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _marketValueController = TextEditingController(); // New controller

  String? _selectedPosition;
  String? _selectedDominantFoot;
  DateTime? _selectedBirthDate;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyNumberController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _imageUrlController.dispose();
    _marketValueController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _savePlayer() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final playerService = Provider.of<PlayerService>(context, listen: false);
      final teamService = Provider.of<TeamService>(context, listen: false); // Get TeamService

      // Fetch the user's team ID
      String? userTeamId;
      try {
        final userTeams = await teamService.getTeams();
        if (userTeams.isNotEmpty) {
          userTeamId = userTeams.first.id;
        } else {
          throw Exception(appLocalizations.noTeamFoundForUser);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocalizations.failedToGetUserTeam(e.toString())}')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final newPlayer = Player(
        id: '', // Backend generates ID
        teamId: userTeamId, // Pass the user's team ID
        name: _nameController.text,
        jerseyNumber: int.tryParse(_jerseyNumberController.text),
        position: _selectedPosition,
        birthDate: _selectedBirthDate,
        dominantFoot: _selectedDominantFoot,
        heightCm: int.tryParse(_heightController.text),
        weightKg: int.tryParse(_weightController.text),
        imageUrl: _imageUrlController.text,
        marketValue: double.tryParse(_marketValueController.text), // New field
      );

      try {
        await playerService.createPlayer(newPlayer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.playerCreatedSuccessfully)),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocalizations.failedToCreatePlayer(e.toString())}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.addNewPlayer),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: appLocalizations.playerName),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.pleaseEnterPlayerName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jerseyNumberController,
                decoration: InputDecoration(labelText: appLocalizations.jerseyNumber),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                decoration: InputDecoration(labelText: appLocalizations.position),
                items: <String>['GK', 'DEF', 'MID', 'FWD']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPosition = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedBirthDate == null
                          ? appLocalizations.birthDateSelectDate
                          : '${appLocalizations.birthDate} ${DateFormat.yMd().format(_selectedBirthDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectBirthDate(context),
                    child: Text(appLocalizations.selectDate),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDominantFoot,
                decoration: InputDecoration(labelText: appLocalizations.dominantFoot),
                items: <String>[appLocalizations.left, appLocalizations.right]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDominantFoot = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(labelText: appLocalizations.heightCm),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: appLocalizations.weightKg),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: appLocalizations.imageUrl),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marketValueController,
                decoration: InputDecoration(labelText: appLocalizations.marketValue),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _savePlayer,
                      child: Text(appLocalizations.savePlayer),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
