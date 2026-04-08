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
  String _focusedTeam = 'team_a';

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
    final analysis = selectedSeg?.analysisJson ?? {};
    final teamData = analysis[_focusedTeam] ?? {};

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
          _buildTacticalHUD(selectedSeg, teamData),
        ],
      ],
    );
  }

  Widget _buildTacticalHUD(AnalysisSegment segment, Map<String, dynamic> teamData) {
    final defLine = teamData['defensive_line'] ?? 0.0;
    final width = teamData['width'] ?? 0.0;
    final compactness = teamData['compactness'] ?? 0.0;
    final avgSpeed = teamData['avg_speed'] ?? 0.0;
    final pressing = teamData['pressing_intensity'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Team Switcher
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                _buildTeamSwitcher(),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Metrics Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMetric(Icons.straighten, 'Def Line', '${defLine.toStringAsFixed(1)}m')),
                    Expanded(child: _buildMetric(Icons.swap_horizontal_circle, 'Width', '${width.toStringAsFixed(1)}m')),
                    Expanded(child: _buildMetric(Icons.compress, 'Compact', '${compactness.toStringAsFixed(1)}m')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMetric(Icons.speed, 'Avg Speed', '${avgSpeed.toStringAsFixed(1)} m/s')),
                    Expanded(child: _buildMetric(Icons.bolt, 'Pressing', '$pressing events')),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Recommendation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                    const SizedBox(width: 8),
                    const Text(
                      'AI TACTICAL ANALYSIS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'CASE DESCRIPTION',
                  style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  segment.tacticalNarrative,
                  style: const TextStyle(height: 1.5, fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  'STRATEGIC HINTS',
                  style: TextStyle(color: Colors.amberAccent.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  segment.recommendation?.trim().isNotEmpty == true
                      ? segment.recommendation!.trim()
                      : 'No tactical hints generated.',
                  style: const TextStyle(height: 1.5, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSwitcher() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTeamTab('team_a', 'TEAM A'),
          _buildTeamTab('team_b', 'TEAM B'),
        ],
      ),
    );
  }

  Widget _buildTeamTab(String teamKey, String label) {
    final bool isSelected = _focusedTeam == teamKey;
    return GestureDetector(
      onTap: () => setState(() => _focusedTeam = teamKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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

  Widget _buildMetric(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white38),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
