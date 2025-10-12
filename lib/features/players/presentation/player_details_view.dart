import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlayerDetailsView extends StatelessWidget {
  final Player player;
  final VoidCallback onEditImage;

  const PlayerDetailsView({super.key, required this.player, required this.onEditImage});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final String? imageUrl = player.imageUrl;
    ImageProvider? backgroundImage;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        backgroundImage = NetworkImage(imageUrl);
      } else {
        backgroundImage = NetworkImage('${apiClient.baseUrl.replaceAll('/api', '')}$imageUrl');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: backgroundImage,
                  child: backgroundImage == null
                      ? Text(
                          player.name.isNotEmpty ? player.name[0] : '?',
                          style: const TextStyle(fontSize: 60, color: Colors.white),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).cardColor,
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
                      onPressed: onEditImage,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            player.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 28,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${player.position ?? appLocalizations.notAvailable} - #${player.jerseyNumber ?? appLocalizations.notAvailable}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary),
                    title: Text(appLocalizations.birthDate, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(player.birthDate != null ? DateFormat.yMd().format(player.birthDate!) : appLocalizations.notAvailable, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.directions_walk, color: Theme.of(context).colorScheme.secondary),
                    title: Text(appLocalizations.dominantFoot, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(player.dominantFoot ?? appLocalizations.notAvailable, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.height, color: Theme.of(context).colorScheme.secondary),
                    title: Text(appLocalizations.height, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(player.heightCm != null ? '${player.heightCm} cm' : appLocalizations.notAvailable, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.scale, color: Theme.of(context).colorScheme.secondary),
                    title: Text(appLocalizations.weight, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(player.weightKg != null ? '${player.weightKg} kg' : appLocalizations.notAvailable, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.flag, color: Theme.of(context).colorScheme.secondary),
                    title: Text(appLocalizations.nationality, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(player.nationality ?? appLocalizations.notAvailable, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.secondary),
                    title: Text(appLocalizations.marketValue, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(player.marketValue != null ? '\${player.marketValue!.toStringAsFixed(2)}' : appLocalizations.notAvailable, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
