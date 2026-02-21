import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/reunion.dart';
import 'package:frontend/services/reunion_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';

class ReunionsScreen extends StatefulWidget {
  const ReunionsScreen({super.key});

  @override
  State<ReunionsScreen> createState() => _ReunionsScreenState();
}

class _ReunionsScreenState extends State<ReunionsScreen> {
  late Future<List<Reunion>> _reunionsFuture;

  @override
  void initState() {
    super.initState();
    _loadReunions();
  }

  void _loadReunions() {
    final reunionService = Provider.of<ReunionService>(context, listen: false);
    setState(() {
      _reunionsFuture = reunionService.getReunions();
    });
  }

  Future<void> _deleteReunion(String id) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      await Provider.of<ReunionService>(context, listen: false).deleteReunion(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.reunionCreatedSuccessfully)),
      );
      _loadReunions(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.failedToCreateReunion(e.toString())}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final canEdit = authService.canManageReunions;
    return FutureBuilder<List<Reunion>>(
      future: _reunionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(appLocalizations.noReunionsFound));
        }

        final reunions = snapshot.data!;
        return ListView.builder(
          itemCount: reunions.length,
          itemBuilder: (context, index) {
            final reunion = reunions[index];
            final isPast = reunion.date.isBefore(DateTime.now());
            
            final Widget card = Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isPast ? Colors.grey.withOpacity(0.5) : Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(
                    reunion.icon,
                    color: isPast ? Colors.white54 : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    reunion.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          decoration: isPast ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  subtitle: Text(
                    '${reunion.date.day}/${reunion.date.month}/${reunion.date.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Text(
                    reunion.location,
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
              key: ValueKey(reunion.id),
              direction: DismissDirection.startToEnd,
              onDismissed: (direction) {
                _deleteReunion(reunion.id);
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
