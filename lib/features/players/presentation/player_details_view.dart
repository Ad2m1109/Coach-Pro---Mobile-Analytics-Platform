import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/widgets/custom_card.dart';

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
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    backgroundImage: backgroundImage,
                    child: backgroundImage == null
                        ? Text(
                            player.name.isNotEmpty ? player.name[0] : '?',
                            style: TextStyle(fontSize: 60, color: Theme.of(context).colorScheme.primary),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton.small(
                    onPressed: onEditImage,
                    child: const Icon(Icons.edit, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            player.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${player.position ?? appLocalizations.notAvailable} - #${player.jerseyNumber ?? appLocalizations.notAvailable}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          CustomCard(
            child: Column(
              children: [
                _buildDetailRow(context, Icons.calendar_today, appLocalizations.birthDate, player.birthDate != null ? DateFormat.yMd().format(player.birthDate!) : appLocalizations.notAvailable),
                const Divider(),
                _buildDetailRow(context, Icons.directions_walk, appLocalizations.dominantFoot, player.dominantFoot ?? appLocalizations.notAvailable),
                const Divider(),
                _buildDetailRow(context, Icons.height, appLocalizations.height, player.heightCm != null ? '${player.heightCm} cm' : appLocalizations.notAvailable),
                const Divider(),
                _buildDetailRow(context, Icons.scale, appLocalizations.weight, player.weightKg != null ? '${player.weightKg} kg' : appLocalizations.notAvailable),
                const Divider(),
                _buildDetailRow(context, Icons.flag, appLocalizations.nationality, player.nationality ?? appLocalizations.notAvailable),
                const Divider(),
                _buildDetailRow(context, Icons.attach_money, appLocalizations.marketValue, player.marketValue != null ? '\$${player.marketValue!.toStringAsFixed(2)}' : appLocalizations.notAvailable),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
