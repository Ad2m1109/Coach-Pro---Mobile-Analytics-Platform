import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
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
            Row(
              children: [
                const Text('Analysis Status: '),
                Chip(
                  label: Text(status),
                  backgroundColor: _statusColor(status).withOpacity(0.15),
                  side: BorderSide(color: _statusColor(status)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frames: ${outputs['total_frames'] ?? '-'}'),
                    Text(
                      'Players tracked: ${outputs['players_tracked'] ?? '-'}',
                    ),
                    Text('FPS: ${outputs['fps'] ?? '-'}'),
                    Text(
                      'Processing time (s): ${outputs['processing_time_seconds'] ?? '-'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Output files'),
                    const SizedBox(height: 8),
                    Text(
                      'Tracking video: ${outputs['tracking_video_path'] ?? '-'}',
                    ),
                    Text(
                      'Heatmap video: ${outputs['heatmap_video_path'] ?? '-'}',
                    ),
                    Text(
                      'Backline video: ${outputs['backline_video_path'] ?? '-'}',
                    ),
                    Text(
                      'Animation video: ${outputs['animation_video_path'] ?? '-'}',
                    ),
                    Text(
                      'Possession data: ${outputs['possession_analysis_path'] ?? '-'}',
                    ),
                    Text(
                      'Tracking JSON: ${outputs['tracking_json_path'] ?? '-'}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
