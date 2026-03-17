import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

class SegmentCard extends StatelessWidget {
  final AnalysisSegment segment;
  final VoidCallback onPlay;

  const SegmentCard({
    super.key,
    required this.segment,
    required this.onPlay,
  });

  Color _getSeverityColor(BuildContext context, String label) {
    switch (label.toUpperCase()) {
      case 'CRITICAL':
        return Theme.of(context).colorScheme.error;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber;
      case 'LOW':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatTime(double seconds) {
    int m = (seconds / 60).floor();
    int s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(context, segment.severityLabel);
    
    return CustomCard(
      padding: EdgeInsets.zero,
      color: Theme.of(context).cardTheme.color,
      child: ExpansionTile(
        key: PageStorageKey(segment.id),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#${segment.segmentIndex + 1}',
              style: TextStyle(
                color: severityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${_formatTime(segment.startSec)} – ${_formatTime(segment.endSec)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                segment.severityLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            'Match Intensity: ${(segment.severityScore * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: AppSpacing.s),
                _buildMetricsGrid(context),
                const SizedBox(height: AppSpacing.m),
                _buildRecommendationBox(context),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_circle_filled, size: 20),
                    label: const Text(
                      'Jump to Segment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final analysis = segment.analysisJson ?? {};
    final posA = analysis['possession_team_a_pct'] ?? 50.0;
    final posB = analysis['possession_team_b_pct'] ?? 50.0;
    final gapsA = analysis['backline_gaps_team_a'] ?? 0;
    final gapsB = analysis['backline_gaps_team_b'] ?? 0;
    final entropy = analysis['zone_entropy'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            _buildTacticalBadge(
              Icons.trending_up, 
              posA > posB ? 'Dominance' : 'Parity', 
              Theme.of(context).colorScheme.primary
            ),
            const SizedBox(width: AppSpacing.s),
            if (gapsA > 0 || gapsB > 0)
              _buildTacticalBadge(Icons.security, 'Defense Alert', Colors.orange),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildMetricRow(
                context,
                Icons.pie_chart_rounded,
                'Possession Balance',
                '$posA% - $posB%',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
              _buildMetricRow(
                context,
                Icons.shield_outlined,
                'Defensive Alerts',
                'S1: $gapsA | S2: $gapsB',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
              _buildMetricRow(
                context,
                Icons.hub_outlined,
                'Tactical Entropy',
                entropy.toStringAsFixed(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9, 
              fontWeight: FontWeight.w900, 
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: AppSpacing.m),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationBox(BuildContext context) {
    final hasRec = segment.recommendation != null && segment.recommendation!.isNotEmpty;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasRec ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        boxShadow: hasRec ? [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        child: Stack(
          children: [
            if (hasRec)
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.psychology,
                  size: 100,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 20,
                        color: hasRec ? Colors.white : Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'AI TACTICAL ADVISORY',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.2,
                          color: hasRec ? Colors.white : Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    hasRec ? segment.recommendation! : 'Segment severity below LLM threshold. No advisory generated.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      fontStyle: hasRec ? FontStyle.normal : FontStyle.italic,
                      color: hasRec ? Colors.white.withOpacity(0.9) : Theme.of(context).hintColor,
                      fontWeight: hasRec ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
