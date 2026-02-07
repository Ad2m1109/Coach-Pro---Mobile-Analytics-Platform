import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/training_session.dart';
import 'package:frontend/services/training_session_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late Future<List<TrainingSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrainingSessions();
  }

  void _loadTrainingSessions() {
    final trainingSessionService =
        Provider.of<TrainingSessionService>(context, listen: false);
    _sessionsFuture = trainingSessionService.getTrainingSessions();
  }

  Future<void> _deleteTrainingSession(String id) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      await Provider.of<TrainingSessionService>(context, listen: false).deleteTrainingSession(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.trainingSessionCreatedSuccessfully)),
      );
      _loadTrainingSessions(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.failedToCreateSession(e.toString())}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final canEdit = authService.hasPermission('edit');
    return FutureBuilder<List<TrainingSession>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(appLocalizations.noTrainingSessionsFound));
        }

        final sessions = snapshot.data!;
        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final isPast = session.date.isBefore(DateTime.now());
            
            final Widget card = Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isPast ? Colors.grey.withOpacity(0.5) : Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(
                    session.icon,
                    color: isPast ? Colors.white54 : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    session.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          decoration: isPast ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  subtitle: Text(
                    '${session.date.day}/${session.date.month}/${session.date.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Text(
                    session.focus,
                    style: TextStyle(
                      color: isPast ? Colors.white54 : Theme.of(context).colorScheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );

            if (!canEdit) return card;

            return Dismissible(
              key: ValueKey(session.id),
              direction: DismissDirection.startToEnd,
              onDismissed: (direction) {
                _deleteTrainingSession(session.id);
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: card,
            );
          },
        );
      },
    );
  }
}
