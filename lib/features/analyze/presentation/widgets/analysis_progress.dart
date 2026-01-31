import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';

class AnalysisProgressWidget extends StatelessWidget {
  final double uploadProgress;
  final double analysisProgress;
  final Map<String, dynamic>? liveStats;

  const AnalysisProgressWidget({
    super.key,
    required this.uploadProgress,
    required this.analysisProgress,
    this.liveStats,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_file, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.videoAnalysisProgress,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProgressSection(
              context: context,
              title: appLocalizations.uploadVideo,
              progress: uploadProgress,
              icon: Icons.upload_file,
            ),
            const SizedBox(height: 16),
            _buildProgressSection(
              context: context,
              title: appLocalizations.analyze,
              progress: analysisProgress,
              icon: Icons.analytics,
            ),
            if (liveStats != null && liveStats!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildLiveStats(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 20, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              "Live Player Metrics",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: liveStats!.length,
            itemBuilder: (context, index) {
              final playerId = liveStats!.keys.elementAt(index);
              final stats = liveStats![playerId];
              final distance = stats['distance'] ?? 0.0;
              
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Player #$playerId",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${distance}m",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    Text(
                      "Distance",
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection({
    required BuildContext context,
    required String title,
    required double progress,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}