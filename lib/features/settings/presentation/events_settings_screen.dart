import 'package:flutter/material.dart';
import 'package:frontend/features/matches/presentation/add_event_screen.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/event_service.dart';
import 'package:provider/provider.dart';

class EventsSettingsScreen extends StatefulWidget {
  const EventsSettingsScreen({super.key});

  @override
  State<EventsSettingsScreen> createState() => _EventsSettingsScreenState();
}

class _EventsSettingsScreenState extends State<EventsSettingsScreen> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final eventService = Provider.of<EventService>(context, listen: false);
    setState(() {
      _eventsFuture = eventService.getEvents();
    });
  }

  Future<void> _showDeleteConfirmationDialog(String eventId, String eventName) async {
    final appLocalizations = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocalizations.confirmDeletion),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(appLocalizations.confirmDeleteEvent(eventName)),
                Text(appLocalizations.thisActionCannotBeUndone),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(appLocalizations.delete),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // Perform the deletion
                try {
                  await Provider.of<EventService>(context, listen: false).deleteEvent(eventId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.eventDeletedSuccessfully)),
                  );
                  _loadEvents(); // Refresh the list
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.failedToDeleteEvent(e.toString())}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEventScreen()),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.manageEvents),
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(appLocalizations.noEventsFound));
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(event.name, style: Theme.of(context).textTheme.titleLarge),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmationDialog(event.id, event.name),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        child: const Icon(Icons.add),
      ),
    );
  }
}
