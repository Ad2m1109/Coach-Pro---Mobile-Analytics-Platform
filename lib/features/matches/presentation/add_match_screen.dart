import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/services/match_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/event_service.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _opponentNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isHome = true;
  Event? _selectedEvent;
  bool _isLoading = false;
  late Future<List<Event>> _eventsFuture;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _eventsFuture = context.read<EventService>().getEvents();
  }

  @override
  void dispose() {
    _opponentNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveMatch() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_selectedEvent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.pleaseSelectAnEvent)),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final matchService = context.read<MatchService>();

      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      try {
        await matchService.createMatch(
          opponentName: _opponentNameController.text.trim(),
          date: finalDateTime,
          isHome: _isHome,
          eventId: _selectedEvent!.id,
        );
        _showMessage(appLocalizations.matchCreatedSuccessfully);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (e) {
        _showMessage(appLocalizations.failedToCreateMatch(e.toString()));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.addNewMatch),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _opponentNameController,
                decoration: InputDecoration(labelText: appLocalizations.opponentTeamName),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.pleaseEnterOpponentTeamName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text("${appLocalizations.date} ${DateFormat.yMd().format(_selectedDate)}"),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text(appLocalizations.selectDate),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text("${appLocalizations.time} ${_selectedTime.format(context)}"),
                  ),
                  TextButton(
                    onPressed: () => _selectTime(context),
                    child: Text(appLocalizations.selectTime),
                  ),
                ],
              ),
              SwitchListTile(
                title: Text(appLocalizations.homeGame),
                value: _isHome,
                onChanged: (bool value) {
                  setState(() {
                    _isHome = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Event>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('${appLocalizations.errorLoadingEvents} ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(appLocalizations.noEventsAvailable));
                  }

                  final events = snapshot.data!;
                  return DropdownButtonFormField<Event>(
                    decoration: InputDecoration(labelText: appLocalizations.event),
                    value: _selectedEvent,
                    onChanged: (Event? newValue) {
                      setState(() {
                        _selectedEvent = newValue;
                      });
                    },
                    items: events.map<DropdownMenuItem<Event>>((Event event) {
                      return DropdownMenuItem<Event>(
                        value: event,
                        child: Text(event.name),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return appLocalizations.pleaseSelectAnEvent;
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveMatch,
                      child: Text(appLocalizations.saveMatch),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
