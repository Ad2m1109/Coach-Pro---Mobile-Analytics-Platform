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
import 'package:frontend/features/match_statistics/presentation/widgets/alert_counters_panel.dart';
import 'package:frontend/features/match_statistics/presentation/widgets/tactical_minimap.dart';
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

      final String? previewPath = outputs['tracking_video_preview_path']?.toString();
      final String? videoPath = outputs['tracking_video_path']?.toString();
      final String? chosenPath = (previewPath != null && previewPath.isNotEmpty)
          ? previewPath
          : ((videoPath != null && videoPath.isNotEmpty) ? videoPath : null);

      if (chosenPath == null) {
        if (!mounted) return;
        setState(() {
          _videoLoading = false;
          _videoError = 'No tracking video available yet.';
        });
        return;
      }

      await _initializeVideo(
        streamUrl: analysisService.streamUrl(chosenPath),
        fallbackUrl: analysisService.fileUrl(chosenPath),
        headers: analysisService.fileHeaders(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoError = 'Failed to load tracking video.';
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
    } finally {
      if (mounted) {
        setState(() {
          _settingAnchor = false;
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
              TacticalStatusPanel(
                isConnected: alertService.isConnected,
                lastAlert: alertService.history.isNotEmpty ? alertService.history.last : null,
              ),
              const SizedBox(height: AppSpacing.m),
              AlertCountersPanel(alerts: alertService.history),
              const SizedBox(height: AppSpacing.m),
              _DecisionMetricsPanel(metrics: alertService.decisionMetrics),
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
