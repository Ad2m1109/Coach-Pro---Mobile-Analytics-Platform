import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/event_service.dart';
import 'package:frontend/models/event.dart';
import 'package:provider/provider.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final eventService = context.read<EventService>();
      final newEvent = EventCreate(name: _eventNameController.text.trim());

      try {
        await eventService.createEvent(newEvent);
        _showMessage(appLocalizations.eventCreatedSuccessfully);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (e) {
        _showMessage(appLocalizations.failedToCreateEvent(e.toString()));
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
        title: Text(appLocalizations.addNewEvent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: InputDecoration(labelText: appLocalizations.eventName),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.pleaseEnterAnEventName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveEvent,
                      child: Text(appLocalizations.saveEvent),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
