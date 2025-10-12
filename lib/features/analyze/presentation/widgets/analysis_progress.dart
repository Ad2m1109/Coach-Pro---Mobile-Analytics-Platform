import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';

class AnalysisProgressWidget extends StatelessWidget {
  final double uploadProgress;
  final double analysisProgress;

  const AnalysisProgressWidget({
    super.key,
    required this.uploadProgress,
    required this.analysisProgress,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Card(
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
                  style: Theme.of(context).textTheme.titleMedium,
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
          ],
        ),
      ),
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