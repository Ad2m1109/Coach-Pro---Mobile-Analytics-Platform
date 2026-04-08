import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

class SegmentCard extends StatefulWidget {
  final AnalysisSegment segment;
  final VoidCallback onPlay;

  const SegmentCard({
    super.key,
    required this.segment,
    required this.onPlay,
  });

  @override
  State<SegmentCard> createState() => _SegmentCardState();
}

class _SegmentCardState extends State<SegmentCard> {
  String _focusedTeam = 'team_a';

  Color _getSeverityColor(BuildContext context, String label) {
    switch (label.toUpperCase()) {
      case 'CRITICAL':
        return Color(0xFFE53935);
      case 'HIGH':
        return Color(0xFFFB8C00);
      case 'MEDIUM':
        return Color(0xFFFFB300);
      case 'LOW':
      default:
        return Color(0xFF1E88E5);
    }
  }

  String _formatTime(double seconds) {
    int m = (seconds / 60).floor();
    int s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Determine color based on focused team's severity if available
    final analysis = widget.segment.analysisJson ?? {};
    final teamData = analysis[_focusedTeam] ?? {};
    final teamLabel = teamData['severity_label'] ?? widget.segment.severityLabel;
    final severityColor = _getSeverityColor(context, teamLabel);
    
    return CustomCard(
      padding: EdgeInsets.zero,
      color: Theme.of(context).cardTheme.color,
      child: ExpansionTile(
        key: PageStorageKey(widget.segment.id),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#${widget.segment.segmentIndex + 1}',
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
                '${_formatTime(widget.segment.startSec)} – ${_formatTime(widget.segment.endSec)}',
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
                teamLabel,
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
            'Team ${_focusedTeam == 'team_a' ? 'A' : 'B'} Health: ${(teamData['severity_score'] ?? widget.segment.severityScore * 100).toStringAsFixed(1)}%',
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
                _buildMetricsGrid(context, teamData),
                const SizedBox(height: AppSpacing.m),
                _buildRecommendationBox(context),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: widget.onPlay,
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

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> teamData) {
    // The 5 Deterministic Tactical Variables
    final defLine = teamData['defensive_line'] ?? 0.0;
    final width = teamData['width'] ?? 0.0;
    final compactness = teamData['compactness'] ?? 0.0;
    final avgSpeed = teamData['avg_speed'] ?? 0.0;
    final pressing = teamData['pressing_intensity'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TACTICAL TELEMETRY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 1.1,
                  ),
            ),
            _buildTeamSwitcher(),
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
                Icons.straighten,
                'Defensive Line',
                '${defLine.toStringAsFixed(1)}m',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
              _buildMetricRow(
                context,
                Icons.swap_horizontal_circle_outlined,
                'Team Width',
                '${width.toStringAsFixed(1)}m',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
              _buildMetricRow(
                context,
                Icons.compress,
                'Compactness',
                '${compactness.toStringAsFixed(1)}m',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
              _buildMetricRow(
                context,
                Icons.speed,
                'Average Speed',
                '${avgSpeed.toStringAsFixed(2)} m/s',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
              _buildMetricRow(
                context,
                Icons.bolt,
                'Pressing Intensity',
                '$pressing actions',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSwitcher() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTeamTab('team_a', 'TEAM A'),
          _buildTeamTab('team_b', 'TEAM B'),
        ],
      ),
    );
  }

  Widget _buildTeamTab(String teamKey, String label) {
    bool isSelected = _focusedTeam == teamKey;
    return GestureDetector(
      onTap: () => setState(() => _focusedTeam = teamKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    final hasRec = widget.segment.recommendation != null && widget.segment.recommendation!.isNotEmpty;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasRec ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusL),
        border: Border.all(color: hasRec ? Colors.transparent : Colors.white10),
        boxShadow: hasRec ? [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusL),
        child: Stack(
          children: [
            if (hasRec)
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  Icons.psychology_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: hasRec ? Colors.white : Colors.white38,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'ELITE TACTICAL ADVISORY',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          color: hasRec ? Colors.white : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    hasRec ? widget.segment.recommendation! : 'Segment severity below LLM threshold. Monitoring phase...',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      fontStyle: hasRec ? FontStyle.normal : FontStyle.italic,
                      color: hasRec ? Colors.white : Colors.white38,
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
