import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:provider/provider.dart';

class AnalysisResultsWidget extends StatelessWidget {
  final String matchId;

  const AnalysisResultsWidget({super.key, required this.matchId});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PROCESSING':
      case 'PENDING':
        return Colors.blue;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    return FutureBuilder<dynamic>(
      future: apiClient.get('/matches/$matchId/analysis'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load analysis: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No analysis data'));
        }

        final data = snapshot.data as Map<String, dynamic>;
        final status = (data['status'] ?? 'NO_ANALYSIS').toString();
        final outputs =
            (data['outputs'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

        if (status == 'NO_ANALYSIS') {
          return const Center(
            child: Text('No analysis results available yet.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context, status),
            const SizedBox(height: 16),
            if (outputs.containsKey('tactical_advisory_path'))
              _TacticalAdvisorySection(
                advisoryPath: outputs['tactical_advisory_path'],
              ),
            const SizedBox(height: 16),
            _buildTechnicalMetrics(context, outputs),
            const SizedBox(height: 16),
            _buildOutputFilesList(context, outputs),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Report',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Match ID: $matchId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Chip(
          label: Text(status),
          backgroundColor: _statusColor(status).withOpacity(0.15),
          side: BorderSide(color: _statusColor(status)),
        ),
      ],
    );
  }

  Widget _buildTechnicalMetrics(BuildContext context, Map<String, dynamic> outputs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_suggest, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Technical Execution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _buildStatItem('Frames', outputs['total_frames']?.toString() ?? '-'),
                _buildStatItem('Players', outputs['players_tracked']?.toString() ?? '-'),
                _buildStatItem('FPS', outputs['fps']?.toString() ?? '-'),
                _buildStatItem('Compute Time', '${outputs['processing_time_seconds'] ?? '-'}s'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOutputFilesList(BuildContext context, Map<String, dynamic> outputs) {
    return ExpansionTile(
      title: const Text('Generated Assets & Raw Data'),
      leading: const Icon(Icons.folder_open),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildFileLink(context, 'Tracking Video', outputs['tracking_video_path']),
        _buildFileLink(context, 'Heatmap Visualization', outputs['heatmap_video_path']),
        _buildFileLink(context, 'Backline Analysis', outputs['backline_video_path']),
        _buildFileLink(context, 'Live Animation', outputs['animation_video_path']),
        _buildFileLink(context, 'Possession JSON', outputs['possession_analysis_path']),
        _buildFileLink(context, 'Raw Metadata', outputs['tracking_json_path']),
      ],
    );
  }

  Widget _buildFileLink(BuildContext context, String label, String? path) {
    if (path == null) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file_outlined, size: 18),
      title: Text(label),
      subtitle: Text(path, style: const TextStyle(fontSize: 10)),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () {
        // Handle file open/preview
      },
    );
  }
}

class _TacticalAdvisorySection extends StatelessWidget {
  final String advisoryPath;

  const _TacticalAdvisorySection({required this.advisoryPath});

  @override
  Widget build(BuildContext context) {
    final analysisService = Provider.of<AnalysisService>(context, listen: false);
    return FutureBuilder<dynamic>(
      future: analysisService.fetchJsonPreview(advisoryPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data as Map<String, dynamic>;
        final advisories = (data['advisories'] as List?) ?? [];
        if (advisories.isEmpty) return const SizedBox.shrink();

        // Show the latest advisory (or wrap in a carousel if multiple)
        final latest = advisories.last as Map<String, dynamic>;
        final output = (latest['advisor_output'] as Map?) ?? {};
        final metrics = (latest['decision_metrics'] as Map?) ?? {};
        final issues = (metrics['detected_issues'] as List?) ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ).createShader(bounds),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Tactical Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.blue.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInsightHeader(context, output['confidence'] ?? (output['confidence_level'] ?? 0.0)),
                    const Divider(height: 32),
                    _buildSectionTitle('## Situation Analysis'),
                    const SizedBox(height: 8),
                    Text(
                      output['analysis'] ?? 'No analysis available.',
                      style: const TextStyle(height: 1.5),
                    ),
                    if (issues.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildIssuesList(issues),
                    ],
                    const SizedBox(height: 24),
                    _buildRecommendationCard(context, output['recommendation'] ?? ''),
                    const SizedBox(height: 20),
                    _buildImpactBox(context, output['impact'] ?? (output['expected_impact'] ?? '')),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightHeader(BuildContext context, dynamic confidence) {
    final conf = (confidence as num).toDouble();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STRATEGIC ADVISORY',
                style: TextStyle(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Powered by Phi-3 Tactical Engine',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        _buildConfidenceBadge(conf),
      ],
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 14, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}% Conf.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.replaceAll('## ', '').toUpperCase(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 11,
        color: Colors.black54,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildIssuesList(List issues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CRITICAL OBSERVATIONS',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 8),
        ...issues.map((issue) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.toString(),
                  style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String recommendation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'TACTICAL RECOMMENDATION',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBox(BuildContext context, String impact) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPECTED IMPACT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 2),
                Text(
                  impact,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
