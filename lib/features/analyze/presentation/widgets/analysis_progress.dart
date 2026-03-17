import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

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
    final stats = liveStats ?? const <String, dynamic>{};
    return CustomCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_file, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.s),
              Text(
                appLocalizations.videoAnalysisProgress,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildProgressSection(
            context: context,
            title: appLocalizations.uploadVideo,
            progress: _clampProgress(uploadProgress),
            icon: Icons.upload_file,
          ),
          const SizedBox(height: AppSpacing.m),
          _buildProgressSection(
            context: context,
            title: appLocalizations.analyze,
            progress: _clampProgress(analysisProgress),
            icon: Icons.analytics,
          ),
          if (stats.isNotEmpty) ...[
            const Divider(height: AppSpacing.xl),
            _buildLiveStats(context, stats),
          ],
        ],
      ),
    );
  }

  double _clampProgress(double progress) {
    if (progress.isNaN) return 0;
    return progress.clamp(0, 1);
  }

  Widget _buildLiveStats(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt, size: 18, color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              "Live Tactical Hub",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
            const Spacer(),
            Text(
              "${stats.length} Active",
              style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final playerId = stats.keys.elementAt(index);
              final playerStats = stats[playerId] as Map<String, dynamic>? ?? {};
              final distance = (playerStats['distance'] as num?)?.toDouble() ?? 0.0;
              
              // Determine team color (heuristic or from data if available)
              final isTeamA = int.tryParse(playerId.toString()) != null && int.parse(playerId.toString()) % 2 == 0;
              final teamColor = isTeamA ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;

              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: AppSpacing.s),
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
                  border: Border.all(color: teamColor.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: (distance % 100) / 100, // Just for visual effect
                            strokeWidth: 3,
                            backgroundColor: teamColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(teamColor),
                          ),
                        ),
                        Text(
                          "#$playerId",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: teamColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      '${distance.toStringAsFixed(1)}m',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'DISTANCE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        letterSpacing: 1,
                      ),
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
