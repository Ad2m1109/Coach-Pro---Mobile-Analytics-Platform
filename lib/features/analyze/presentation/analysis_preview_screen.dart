import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:frontend/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

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
      appBar: AppBar(
        title: Text(report.inputVideoName ?? 'Analysis Preview'),
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
      padding: const EdgeInsets.all(16),
      children: [
        if (hasVideo)
          FutureBuilder<void>(
            future: _initVideoFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final controller = _controller!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                          setState(() {});
                        },
                        icon: Icon(
                          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                        ),
                      ),
                    ],
                  ),
                ],
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

        const SizedBox(height: 16),

        Text(
          report.message ?? 'Timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (_segments.isEmpty)
          const Text('No segments available for this analysis run yet.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_segments.length, (i) {
                final seg = _segments[i];
                final isSelected = i == _selected;
                final color = _severityColor(seg.severityLabel);
                final alertCount = _alertsForSegment(seg).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _selectSegment(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.20) : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? color : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'P${seg.segmentIndex + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : null),
                          ),
                          const SizedBox(width: 8),
                          Text('${_formatTime(seg.startSec)}-${_formatTime(seg.endSec)}'),
                          if (alertCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('A$alertCount', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

        const SizedBox(height: 16),

        if (selectedSeg != null) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _severityColor(selectedSeg.severityLabel),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Part ${selectedSeg.segmentIndex + 1}  (${_formatTime(selectedSeg.startSec)} - ${_formatTime(selectedSeg.endSec)})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(selectedSeg.severityLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedSeg.recommendation?.trim().isNotEmpty == true
                        ? selectedSeg.recommendation!.trim()
                        : 'No LLM recommendation for this part.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Events',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._alertsForSegment(selectedSeg).map((a) {
                    final t = a.matchTime;
                    final timeLabel = t != null ? _formatTime(t) : '--:--';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.bolt, color: a.severityColor),
                      title: Text('${a.decisionType} (${a.severityLabel})'),
                      subtitle: Text(timeLabel),
                    );
                  }),
                  if (_alertsForSegment(selectedSeg).isEmpty)
                    const Text('No events in this part.'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
