import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:frontend/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/features/analyze/presentation/widgets/premium_video_player.dart';
import 'package:frontend/features/analyze/presentation/widgets/analysis_timeline.dart';
import 'package:frontend/features/analyze/presentation/widgets/segment_card.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/core/design_system/app_typography.dart';

class AnalysisPreviewScreen extends StatefulWidget {
  final AnalysisReport report;

  const AnalysisPreviewScreen({super.key, required this.report});

  @override
  State<AnalysisPreviewScreen> createState() => _AnalysisPreviewScreenState();
}

class _AnalysisPreviewScreenState extends State<AnalysisPreviewScreen> {
  bool _loading = true;
  String? _error;

  List<AnalysisSegment> _segments = [];
  int _selected = 0;

  List<TacticalAlert> _alerts = [];

  VideoPlayerController? _controller;
  Future<void>? _initVideoFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Read dependencies before any await to avoid using BuildContext across async gaps.
      final analysisService = context.read<AnalysisService>();
      final ApiClient apiClient = context.read<ApiClient>();

      final rawSegments = await analysisService.getSegmentsForAnalysis(widget.report.id);
      final segments = rawSegments
          .whereType<Map<String, dynamic>>()
          .map(AnalysisSegment.fromJson)
          .toList()
        ..sort((a, b) => a.segmentIndex.compareTo(b.segmentIndex));

      // Tactical alerts are served by the classic backend (8000) ApiClient.
      final matchId = widget.report.matchId;
      List<TacticalAlert> alerts = [];
      if (matchId != null && matchId.isNotEmpty) {
        try {
          final data = await apiClient.get('/matches/$matchId/alerts');
          if (data is List) {
            alerts = data
                .whereType<Map<String, dynamic>>()
                .map(TacticalAlert.fromJson)
                .toList();
          }
        } catch (_) {
          alerts = [];
        }
      }

      // Pick a playable output (prefer preview if present).
      final outputs = widget.report.outputs ?? const <String, dynamic>{};
      final String? relativeVideoPath = (outputs['tracking_video_preview_path'] as String?) ??
          (outputs['tracking_video_path'] as String?);

      if (relativeVideoPath != null && relativeVideoPath.isNotEmpty) {
        final url = analysisService.streamUrl(relativeVideoPath);
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(url),
          httpHeaders: analysisService.fileHeaders(),
        );
        _initVideoFuture = _controller!.initialize();
      }

      if (!mounted) return;
      setState(() {
        _segments = segments;
        _alerts = alerts;
        _selected = segments.isNotEmpty ? 0 : 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Color _severityColor(String label) {
    switch (label.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
      case 'MODERATE':
        return Colors.amber;
      case 'LOW':
      default:
        return Colors.green;
    }
  }

  List<TacticalAlert> _alertsForSegment(AnalysisSegment seg) {
    final start = seg.startSec;
    final end = seg.endSec;
    return _alerts
        .where((a) => a.matchTime != null && a.matchTime! >= start && a.matchTime! <= end)
        .toList()
      ..sort((a, b) => (a.matchTime ?? 0).compareTo(b.matchTime ?? 0));
  }

  Future<void> _selectSegment(int index) async {
    if (index < 0 || index >= _segments.length) return;
    setState(() => _selected = index);

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final seg = _segments[index];
    await controller.seekTo(Duration(seconds: seg.startSec.round()));
  }


  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(report.inputVideoName ?? 'Analysis Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final report = widget.report;
    final hasVideo = _controller != null && _initVideoFuture != null;

    final AnalysisSegment? selectedSeg =
        _segments.isNotEmpty ? _segments[_selected.clamp(0, _segments.length - 1)] : null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (hasVideo)
          FutureBuilder<void>(
            future: _initVideoFuture,
            builder: (context, snap) {
              return PremiumVideoPlayer(
                controller: _controller!,
              );
            },
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No preview video available for this run.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tactical Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
            ),
            Text(
              '${_segments.length} Parts',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_segments.isEmpty)
          const Text('No segments available for this analysis run yet.')
        else
          SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _segments.length,
              itemBuilder: (context, i) {
                final seg = _segments[i];
                final isSelected = i == _selected;
                final color = _severityColor(seg.severityLabel);
                final alertCount = _alertsForSegment(seg).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => _selectSegment(i),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : Theme.of(context).cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'P${seg.segmentIndex + 1}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          if (alertCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$alertCount',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        if (selectedSeg != null) ...[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: Theme.of(context).primaryColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Tactical Masterclass',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _severityColor(selectedSeg.severityLabel).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              selectedSeg.severityLabel,
                              style: TextStyle(
                                color: _severityColor(selectedSeg.severityLabel),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedSeg.recommendation?.trim().isNotEmpty == true
                            ? selectedSeg.recommendation!.trim()
                            : 'No tactical insights generated for this phase.',
                        style: const TextStyle(height: 1.5, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                if (_alertsForSegment(selectedSeg).isNotEmpty) ...[
                  const Divider(color: Colors.white10, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SITUATION DATA',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                        ),
                        const SizedBox(height: 12),
                        ..._alertsForSegment(selectedSeg).map((a) {
                          final t = a.matchTime;
                          final timeLabel = t != null ? _formatTime(t) : '--:--';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.analytics_outlined, color: a.severityColor, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.decisionType,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Timestamp: $timeLabel',
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
