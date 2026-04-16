import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/match_service.dart';
import 'package:frontend/services/tactical_alert_service.dart';
import 'package:frontend/features/match_statistics/presentation/widgets/tactical_status_panel.dart';
import 'package:frontend/features/match_statistics/presentation/widgets/severity_timeline_table.dart';
import 'package:frontend/features/match_statistics/presentation/widgets/severity_line_chart.dart';
import 'package:frontend/features/match_statistics/presentation/widgets/tactical_trends_chart.dart';
import 'package:frontend/features/match_statistics/presentation/widgets/alert_counters_panel.dart';
import 'package:frontend/features/match_statistics/presentation/widgets/tactical_minimap.dart';
import 'package:frontend/features/analyze/presentation/widgets/attribute_evolution_chart.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class TacticalDashboardPage extends StatefulWidget {
  final Match match;

  const TacticalDashboardPage({
    super.key,
    required this.match,
  });

  @override
  State<TacticalDashboardPage> createState() => _TacticalDashboardPageState();
}

class _TacticalDashboardPageState extends State<TacticalDashboardPage> {
  VideoPlayerController? _videoController;
  bool _videoLoading = true;
  bool _settingAnchor = false;
  int? _videoAnchorSeconds;
  String? _videoError;
  String? _selectedDecisionId;
  List<AnalysisSegment> _segments = [];
  int _selectedSegmentIndex = -1;
  String _focusedTeam = 'team_a'; // Track which team is focused in the Status Board

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TacticalAlertService>(context, listen: false).initForMatch(widget.match.id);
      _loadAnchorAndVideo();
    });
  }

  @override
  void dispose() {
    _videoController?.removeListener(_syncChartToVideo);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadAnchorAndVideo() async {
    try {
      final matchService = context.read<MatchService>();
      final updatedMatch = await matchService.getMatchById(widget.match.id);
      if (!mounted) return;
      setState(() {
        _videoAnchorSeconds = updatedMatch.videoAnchorSeconds;
      });
    } catch (_) {
      // Keep null anchor; tactical flow should still work.
    }

    try {
      final apiClient = context.read<ApiClient>();
      final analysisService = context.read<AnalysisService>();
      final dynamic analysis = await apiClient.get('/matches/${widget.match.id}/analysis');
      final Map<String, dynamic> outputs =
          analysis is Map<String, dynamic> && analysis['outputs'] is Map<String, dynamic>
              ? analysis['outputs'] as Map<String, dynamic>
              : const {};

      final String? relativeVideoPath = (outputs['tracking_video_preview_path'] as String?) ??
          (outputs['tracking_video_path'] as String?) ??
          outputs['input_video_path']?.toString();

      if (relativeVideoPath != null && relativeVideoPath.isNotEmpty) {
        await _initializeVideo(
          streamUrl: analysisService.streamUrl(relativeVideoPath),
          fallbackUrl: analysisService.fileUrl(relativeVideoPath),
          headers: analysisService.fileHeaders(),
        );
      } else {
        setState(() {
          _videoLoading = false;
          _videoError = 'No tracking video available yet.';
        });
      }

      // Load segments for the chart
      final rawSegments = await analysisService.getSegmentsForMatch(widget.match.id);
      final segmentsList = rawSegments
          .whereType<Map<String, dynamic>>()
          .map(AnalysisSegment.fromJson)
          .toList()
        ..sort((a, b) => a.segmentIndex.compareTo(b.segmentIndex));

      if (mounted) {
        setState(() {
          _segments = segmentsList;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoError = 'Failed to load match analysis data.';
      });
    }
  }

  Future<void> _initializeVideo({
    required String streamUrl,
    required String fallbackUrl,
    required Map<String, String> headers,
  }) async {
    Future<bool> tryInit(String url) async {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers,
      );
      try {
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return false;
        }
        _videoController?.dispose();
        _videoController = controller;
        return true;
      } catch (_) {
        await controller.dispose();
        return false;
      }
    }

    final streamOk = await tryInit(streamUrl);
    if (!streamOk) {
      final fallbackOk = await tryInit(fallbackUrl);
      if (!fallbackOk) {
        if (!mounted) return;
        setState(() {
          _videoLoading = false;
          _videoError = 'Video player failed to initialize.';
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _videoLoading = false;
      _videoError = null;
    });
    _videoController!.addListener(_syncChartToVideo);
  }

  Future<void> _setMatchAnchor() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (_videoAnchorSeconds != null || _settingAnchor) {
      return;
    }

    final int seconds = controller.value.position.inSeconds;
    setState(() {
      _settingAnchor = true;
    });
    try {
      final matchService = context.read<MatchService>();
      final int anchor = await matchService.setVideoAnchor(
        widget.match.id,
        videoAnchorSeconds: seconds,
      );
      if (!mounted) return;
      setState(() {
        _videoAnchorSeconds = anchor;
      });
      _showMessage('Match synced successfully.');
    } catch (e) {
      _showMessage('Failed to set match anchor.');
    }
  }

  void _syncChartToVideo() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized || _segments.isEmpty) return;

    final double position = controller.value.position.inSeconds.toDouble();
    final int newIndex = _segments.indexWhere((s) => position >= s.startSec && position <= s.endSec);

    if (newIndex != -1 && newIndex != _selectedSegmentIndex) {
      if (mounted) {
        setState(() {
          _selectedSegmentIndex = newIndex;
        });
      }
    }
  }


  Future<void> _onTimelineAlertTap(TacticalAlert alert) async {
    if (mounted) {
      setState(() {
        _selectedDecisionId = _selectedDecisionId == alert.decisionId ? null : alert.decisionId;
      });
    }

    if (_selectedDecisionId == null) {
      return;
    }

    if (_videoAnchorSeconds == null) {
      _showMessage('Video not synced yet.');
      return;
    }

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      _showMessage('Video player is not ready.');
      return;
    }

    if (alert.matchTime == null) {
      _showMessage('This alert has no match time.');
      return;
    }

    final int target = _videoAnchorSeconds! + alert.matchTime!.round();
    final int videoDuration = controller.value.duration.inSeconds;

    int seekSeconds = target < 0 ? 0 : target;
    if (videoDuration > 0) {
      final int safeTarget = seekSeconds > videoDuration ? videoDuration - 1 : seekSeconds;
      seekSeconds = safeTarget < 0 ? 0 : safeTarget;
    }

    await controller.seekTo(Duration(seconds: seekSeconds));
    if (mounted) {
      setState(() {});
    }
  }

  String _formatAnchor(int seconds) {
    final int mm = seconds ~/ 60;
    final int ss = seconds % 60;
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _buildTacticalCommandCenter(AnalysisSegment segment) {
    final List<Map<String, dynamic>> rawTags = _focusedTeam == 'team_a' ? segment.teamATags : segment.teamBTags;
    // Map them to TacticalTag model
    final List<TacticalTag> tags = rawTags.map((json) => TacticalTag.fromJson(json)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'TACTICAL COMMAND CENTER',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'Match Report Intelligence Feed',
            style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          _buildTeamSwitcher(),
          const SizedBox(height: 24),
          
          // Tactical Status Board
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.radar, size: 14, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'TACTICAL STATUS BOARD',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusReadout('DEFENSIVE LINE', _getTagForCategory(tags, 'DEFENSIVE_LINE')),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout('TEAM WIDTH', _getTagForCategory(tags, 'WIDTH')),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout('COMPACTNESS', _getTagForCategory(tags, 'COMPACTNESS')),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout('TRANSITION SPEED', _getTagForCategory(tags, 'SPEED')),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout('PRESSING', _getTagForCategory(tags, 'PRESSING')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSwitcher() {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTeamTab('team_a', 'TEAM A')),
          Expanded(child: _buildTeamTab('team_b', 'TEAM B')),
        ],
      ),
    );
  }

  Widget _buildTeamTab(String teamKey, String label) {
    final bool isSelected = _focusedTeam == teamKey;
    return GestureDetector(
      onTap: () => setState(() => _focusedTeam = teamKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
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
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusReadout(String label, TacticalTag? tag) {
    final bool hasComment = tag != null;
    final String tagText = (tag?.tag ?? 'Stable System').toUpperCase();
    final String description = tag?.description ?? 'Monitoring structural variables...';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tagText,
                  style: TextStyle(
                    color: hasComment ? Theme.of(context).primaryColor : Colors.white12,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: hasComment ? Colors.white70 : Colors.white10,
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TacticalTag? _getTagForCategory(List<TacticalTag> tags, String category) {
    final patterns = {
      'DEFENSIVE_LINE': ['LINE', 'DEPTH', 'OFFSIDE'],
      'WIDTH': ['WIDTH', 'WIDE', 'STRETCHED'],
      'COMPACTNESS': ['COMPACT', 'GAPS', 'DISCONNECTED'],
      'SPEED': ['SPEED', 'TRANSITION', 'FAST', 'SLOW'],
      'PRESSING': ['PRESS', 'CLOSE', 'INTENSITY'],
    };

    final keywords = patterns[category] ?? [];
    for (final tag in tags) {
      final upperTag = tag.tag.toUpperCase();
      if (keywords.any((kw) => upperTag.contains(kw))) {
        return tag;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticalAlertService>(
      builder: (context, alertService, child) {
        final TacticalAlert? selectedAlert = _selectedDecisionId == null
            ? null
            : alertService.history.cast<TacticalAlert?>().firstWhere(
                  (a) => a?.decisionId == _selectedDecisionId,
                  orElse: () => null,
                );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.m),
              _VideoSyncPanel(
                videoController: _videoController,
                isLoading: _videoLoading,
                error: _videoError,
                videoAnchorSeconds: _videoAnchorSeconds,
                settingAnchor: _settingAnchor,
                onSetAnchor: _setMatchAnchor,
                formatAnchor: _formatAnchor,
              ),
              const SizedBox(height: AppSpacing.m),
              
              // New Tactical Command Center Integration
              if (_selectedSegmentIndex != -1 && _segments.isNotEmpty)
                _buildTacticalCommandCenter(_segments[_selectedSegmentIndex])
              else
                TacticalStatusPanel(
                  isConnected: alertService.isConnected,
                  lastAlert: alertService.history.isNotEmpty ? alertService.history.last : null,
                ),
                
              const SizedBox(height: AppSpacing.m),
              AlertCountersPanel(alerts: alertService.history),
              const SizedBox(height: AppSpacing.m),
              if (alertService.flowAnalyses.isNotEmpty) ...[
                _GameFlowNarrative(analysis: alertService.flowAnalyses.last),
                const SizedBox(height: AppSpacing.m),
              ],
              _DecisionMetricsPanel(metrics: alertService.decisionMetrics),
              const SizedBox(height: AppSpacing.m),
              AttributeEvolutionChart(
                segments: _segments,
                selectedIndex: _selectedSegmentIndex,
                onSeek: (secs) {
                  if (_videoAnchorSeconds == null) {
                    _showMessage('Sync video first to use chart navigation.');
                    return;
                  }
                  final controller = _videoController;
                  if (controller != null && controller.value.isInitialized) {
                    final int target = _videoAnchorSeconds! + secs.round();
                    controller.seekTo(Duration(seconds: target < 0 ? 0 : target));
                  }
                },
              ),
              const SizedBox(height: AppSpacing.m),
              SeverityLineChart(alerts: alertService.history),
              const SizedBox(height: AppSpacing.m),
              const Text(
                'Tactical Event Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.s),
              if (selectedAlert != null) ...[
                const Text(
                  'Tactical Minimap',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.s),
                RepaintBoundary(
                  child: TacticalMinimap(
                    players: selectedAlert.players ?? const [],
                    ball: selectedAlert.ball,
                    zone: selectedAlert.zone,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
                  ),
                  child: const Text('Select an alert to visualize tactical layout.'),
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              SeverityTimelineTable(
                alerts: alertService.history,
                onAlertTap: _onTimelineAlertTap,
                selectedDecisionId: _selectedDecisionId,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoSyncPanel extends StatelessWidget {
  final VideoPlayerController? videoController;
  final bool isLoading;
  final String? error;
  final int? videoAnchorSeconds;
  final bool settingAnchor;
  final VoidCallback onSetAnchor;
  final String Function(int seconds) formatAnchor;

  const _VideoSyncPanel({
    required this.videoController,
    required this.isLoading,
    required this.error,
    required this.videoAnchorSeconds,
    required this.settingAnchor,
    required this.onSetAnchor,
    required this.formatAnchor,
  });

  @override
  Widget build(BuildContext context) {
    final controller = videoController;
    final bool ready = controller != null && controller.value.isInitialized;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Anchor Sync',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!ready)
            Text(error ?? 'Video unavailable')
          else ...[
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    if (controller.value.isPlaying) {
                      await controller.pause();
                    } else {
                      await controller.play();
                    }
                  },
                  icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                if (videoAnchorSeconds == null)
                  ElevatedButton.icon(
                    onPressed: settingAnchor ? null : onSetAnchor,
                    icon: const Icon(Icons.play_circle_fill),
                    label: Text(settingAnchor ? 'Syncing...' : 'Start Match'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusS),
                    ),
                    child: Text(
                      'Match Synced ✅  Anchor: ${formatAnchor(videoAnchorSeconds!)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class _DecisionMetricsPanel extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const _DecisionMetricsPanel({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> summary = (metrics['summary'] is Map<String, dynamic>)
        ? metrics['summary'] as Map<String, dynamic>
        : const {};

    final double accuracy = ((summary['effectiveness_rate'] as num?)?.toDouble() ?? 0.0) * 100.0;
    final double override = ((summary['dismissal_rate'] as num?)?.toDouble() ?? 0.0) * 100.0;

    return Row(
      children: [
        _MetricCard(label: 'Decision Accuracy %', value: '${accuracy.toStringAsFixed(1)}%'),
        const SizedBox(width: AppSpacing.s),
        _MetricCard(label: 'Coach Override %', value: '${override.toStringAsFixed(1)}%'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _GameFlowNarrative extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const _GameFlowNarrative({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final momentum = analysis['momentum'] ?? 'Neutral';
    final narrative = analysis['analysis'] ?? 'No flow analysis yet.';
    final recommendation = analysis['recommendation'] ?? 'Maintain current structure.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STRATEGIC GAME FLOW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  momentum.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            narrative,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  'ADJUSTMENT: $recommendation',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
