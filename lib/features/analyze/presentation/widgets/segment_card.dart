import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_segment.dart';

class SegmentCard extends StatelessWidget {
  final AnalysisSegment segment;
  final VoidCallback onPlay;

  const SegmentCard({
    super.key,
    required this.segment,
    required this.onPlay,
  });

  Color _getSeverityColor(String label) {
    switch (label.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber;
      case 'LOW':
      default:
        return Colors.green;
    }
  }

  String _formatTime(double seconds) {
    int m = (seconds / 60).floor();
    int s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(segment.severityLabel);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withOpacity(0.3), width: 1),
      ),
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
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Match Intensity: ${(segment.severityScore * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                _buildMetricsGrid(),
                const SizedBox(height: 16),
                _buildRecommendationBox(context),
                const SizedBox(height: 20),
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
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildMetricsGrid() {
    final analysis = segment.analysisJson ?? {};
    final posA = analysis['possession_team_a_pct'] ?? 50.0;
    final posB = analysis['possession_team_b_pct'] ?? 50.0;
    final gapsA = analysis['backline_gaps_team_a'] ?? 0;
    final gapsB = analysis['backline_gaps_team_b'] ?? 0;
    final entropy = analysis['zone_entropy'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildMetricRow(
            Icons.pie_chart_rounded,
            'Possession Balance',
            '${posA}% - ${posB}%',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _buildMetricRow(
            Icons.shield_outlined,
            'Defensive Alerts',
            'S1: $gapsA | S2: $gapsB',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _buildMetricRow(
            Icons.hub_outlined,
            'Tactical Entropy',
            entropy.toStringAsFixed(3),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey[400]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.blueGrey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasRec ? Colors.blue[50]!.withOpacity(0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasRec ? Colors.blue[200]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 20,
                color: hasRec ? Colors.blue[700] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'AI Tactical Advisory',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: hasRec ? Colors.blue[900] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasRec ? segment.recommendation! : 'Segment severity below LLM threshold. No advisory generated.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontStyle: hasRec ? FontStyle.normal : FontStyle.italic,
              color: hasRec ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
