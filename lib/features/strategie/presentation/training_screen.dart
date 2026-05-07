import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/training_session.dart';
import 'package:frontend/services/training_session_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/features/strategie/presentation/add_training_session_screen.dart';

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

  Widget _buildEmptyState(AppLocalizations appLocalizations, bool canEdit) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 72,
              color: AppColors.textGreyLight.withOpacity(0.4),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              appLocalizations.noTrainingSessionsFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textGreyLight,
                  ),
              textAlign: TextAlign.center,
            ),
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.l),
              OutlinedButton.icon(
                onPressed: _navigateAndRefresh,
                icon: const Icon(Icons.add),
                label: Text(appLocalizations.addTrainingSession ?? 'Add Session'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateAndRefresh() async {
    Widget? screenToPush;
    screenToPush = const AddTrainingSessionScreen();

    if (screenToPush != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screenToPush!),
      );

      if (result == true) {
        _loadTrainingSessions();
      }
    }
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
    final canEdit = authService.canManageTrainingSessions;
    return FutureBuilder<List<TrainingSession>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(appLocalizations, canEdit);
        }

        final sessions = snapshot.data!;
        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final isPast = session.date.isBefore(DateTime.now());
            
            final Widget card = CustomCard(
              padding: EdgeInsets.zero,
              color: isPast ? AppColors.greyLight.withOpacity(0.5) : null,
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
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(appLocalizations.confirmDeletion),
                    content: Text(appLocalizations.thisActionCannotBeUndone),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(appLocalizations.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(appLocalizations.delete),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                _deleteTrainingSession(session.id);
              },
              background: Container(
                color: AppColors.error,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
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
