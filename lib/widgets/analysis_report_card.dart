import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class AnalysisReportCard extends StatelessWidget {
  final AnalysisReport report;

  const AnalysisReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final outputs = report.outputs ?? const <String, dynamic>{};
    final trackingVideo = _outputValue(outputs, 'tracking_video_path');
    final heatmapVideo = _outputValue(outputs, 'heatmap_video_path');
    final backlineVideo = _outputValue(outputs, 'backline_video_path');
    final animationVideo = _outputValue(outputs, 'animation_video_path');
    final trackingPreview = _outputValue(outputs, 'tracking_video_preview_path');
    final heatmapPreview = _outputValue(outputs, 'heatmap_video_preview_path');
    final backlinePreview = _outputValue(outputs, 'backline_video_preview_path');
    final animationPreview = _outputValue(outputs, 'animation_video_preview_path');
    final possessionJson = _outputValue(outputs, 'possession_analysis_path');
    final heatmapImage = _outputValue(outputs, 'heatmap_image_path');
    final movementTrailImage = _outputValue(outputs, 'movement_trail_image_path');
    final allPlayersGridImage = _outputValue(
      outputs,
      'all_players_grid_image_path',
    );
    final possessionChartImage = _outputValue(
      outputs,
      'possession_chart_image_path',
    );
    final analysisService = context.read<AnalysisService>();
    final headers = analysisService.fileHeaders();

    Color statusColor;
    switch (report.status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = Colors.green;
        break;
      case 'PROCESSING':
        statusColor = Colors.blue;
        break;
      case 'FAILED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.inputVideoName ?? 'Demo Analysis',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(report.status),
                  backgroundColor: statusColor.withOpacity(0.12),
                  side: BorderSide(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Progress: ${(report.progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (report.message != null && report.message!.isNotEmpty)
              Text(report.message!, style: Theme.of(context).textTheme.bodySmall),
            if (report.submittedAt != null)
              Text(
                'Submitted: ${report.submittedAt}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (outputs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (trackingVideo != null && trackingVideo.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.play_circle,
                      label: 'Tracking Video',
                      onPressed: () => _showVideoPreview(
                        context,
                        title: 'Tracking Video',
                        streamUrl: analysisService.streamUrl(
                          trackingPreview ?? trackingVideo,
                        ),
                        fallbackUrl: analysisService.fileUrl(trackingVideo),
                        headers: headers,
                      ),
                    ),
                  if (heatmapVideo != null && heatmapVideo.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.play_circle,
                      label: 'Heatmap Video',
                      onPressed: () => _showVideoPreview(
                        context,
                        title: 'Heatmap Video',
                        streamUrl: analysisService.streamUrl(heatmapPreview ?? heatmapVideo),
                        fallbackUrl: analysisService.fileUrl(heatmapVideo),
                        headers: headers,
                      ),
                    ),
                  if (backlineVideo != null && backlineVideo.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.play_circle,
                      label: 'Backline Video',
                      onPressed: () => _showVideoPreview(
                        context,
                        title: 'Backline Video',
                        streamUrl: analysisService.streamUrl(backlinePreview ?? backlineVideo),
                        fallbackUrl: analysisService.fileUrl(backlineVideo),
                        headers: headers,
                      ),
                    ),
                  if (animationVideo != null && animationVideo.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.play_circle,
                      label: 'Animation Video',
                      onPressed: () => _showVideoPreview(
                        context,
                        title: 'Animation Video',
                        streamUrl: analysisService.streamUrl(animationPreview ?? animationVideo),
                        fallbackUrl: analysisService.fileUrl(animationVideo),
                        headers: headers,
                      ),
                    ),
                  if (possessionJson != null && possessionJson.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.data_object,
                      label: 'Possession JSON',
                      onPressed: () => _showJsonPreview(
                        context,
                        path: possessionJson,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (heatmapImage != null && heatmapImage.isNotEmpty)
                    _ImageThumb(
                      label: 'Heatmap',
                      url: analysisService.fileUrl(heatmapImage),
                      headers: headers,
                      onTap: () => _showImagePreview(
                        context,
                        title: 'Heatmap Image',
                        url: analysisService.fileUrl(heatmapImage),
                        headers: headers,
                      ),
                    ),
                  if (movementTrailImage != null && movementTrailImage.isNotEmpty)
                    _ImageThumb(
                      label: 'Movement Trail',
                      url: analysisService.fileUrl(movementTrailImage),
                      headers: headers,
                      onTap: () => _showImagePreview(
                        context,
                        title: 'Movement Trail',
                        url: analysisService.fileUrl(movementTrailImage),
                        headers: headers,
                      ),
                    ),
                  if (allPlayersGridImage != null && allPlayersGridImage.isNotEmpty)
                    _ImageThumb(
                      label: 'Players Grid',
                      url: analysisService.fileUrl(allPlayersGridImage),
                      headers: headers,
                      onTap: () => _showImagePreview(
                        context,
                        title: 'All Players Grid',
                        url: analysisService.fileUrl(allPlayersGridImage),
                        headers: headers,
                      ),
                    ),
                  if (possessionChartImage != null && possessionChartImage.isNotEmpty)
                    _ImageThumb(
                      label: 'Possession Chart',
                      url: analysisService.fileUrl(possessionChartImage),
                      headers: headers,
                      onTap: () => _showImagePreview(
                        context,
                        title: 'Possession Chart',
                        url: analysisService.fileUrl(possessionChartImage),
                        headers: headers,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _outputValue(Map<String, dynamic> outputs, String key) {
    return outputs[key]?.toString();
  }

  Future<void> _showVideoPreview(
    BuildContext context, {
    required String title,
    required String streamUrl,
    required String fallbackUrl,
    required Map<String, String> headers,
  }) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPage(
          title: title,
          streamUrl: streamUrl,
          fallbackUrl: fallbackUrl,
          headers: headers,
        ),
      ),
    );
  }

  Future<void> _showImagePreview(
    BuildContext context, {
    required String title,
    required String url,
    required Map<String, String> headers,
  }) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenImagePage(
          title: title,
          url: url,
          headers: headers,
        ),
      ),
    );
  }

  Future<void> _showJsonPreview(
    BuildContext context, {
    required String path,
  }) async {
    final analysisService = Provider.of<AnalysisService>(context, listen: false);
    final data = await analysisService.fetchJsonPreview(path);
    final pretty = analysisService.prettyJson(data);

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _JsonSummaryView(data: data, rawJson: pretty),
          ),
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PreviewButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final String label;
  final String url;
  final Map<String, String> headers;
  final VoidCallback onTap;

  const _ImageThumb({
    required this.label,
    required this.url,
    required this.headers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                headers: headers,
                height: 72,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _JsonSummaryView extends StatelessWidget {
  final dynamic data;
  final String rawJson;

  const _JsonSummaryView({
    required this.data,
    required this.rawJson,
  });

  @override
  Widget build(BuildContext context) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final stats = (map['statistics'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final possession = (map['possession_percentage'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final events = (map['events'] as List?)?.cast<dynamic>() ?? <dynamic>[];

    String asPct(dynamic value) => value is num ? '${value.toStringAsFixed(1)}%' : '-';
    String asNum(dynamic value) => value is num ? value.toString() : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Possession Summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip(label: 'Team A', value: asPct(possession['team_a'])),
            _MetricChip(label: 'Team B', value: asPct(possession['team_b'])),
            _MetricChip(label: 'Ball Detection', value: asPct(stats['ball_detection_rate'])),
            _MetricChip(label: 'Events', value: asNum(stats['total_events'])),
            _MetricChip(label: 'Interceptions', value: asNum(stats['interceptions'])),
            _MetricChip(label: 'Tackles', value: asNum(stats['tackles'])),
          ],
        ),
        const SizedBox(height: 10),
        Text('Key Events', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            children: [
              ...events.take(8).map((event) {
                final e = event is Map ? event.cast<String, dynamic>() : <String, dynamic>{};
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${e['event_type'] ?? '-'}: ${e['from_team'] ?? '-'} -> ${e['to_team'] ?? '-'}'),
                  subtitle: Text('t=${e['timestamp'] ?? '-'}s  distance=${e['distance'] ?? '-'}'),
                );
              }),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Raw JSON'),
                children: [
                  SelectableText(
                    rawJson,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      ),
      child: Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _VideoPreviewPlayer extends StatefulWidget {
  final String title;
  final String streamUrl;
  final String fallbackUrl;
  final Map<String, String> headers;

  const _VideoPreviewPlayer({
    required this.title,
    required this.streamUrl,
    required this.fallbackUrl,
    required this.headers,
  });

  @override
  State<_VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _FullscreenVideoPage extends StatelessWidget {
  final String title;
  final String streamUrl;
  final String fallbackUrl;
  final Map<String, String> headers;

  const _FullscreenVideoPage({
    required this.title,
    required this.streamUrl,
    required this.fallbackUrl,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _VideoPreviewPlayer(
            title: title,
            streamUrl: streamUrl,
            fallbackUrl: fallbackUrl,
            headers: headers,
          ),
        ),
      ),
    );
  }
}

class _FullscreenImagePage extends StatelessWidget {
  final String title;
  final String url;
  final Map<String, String> headers;

  const _FullscreenImagePage({
    required this.title,
    required this.url,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: Image.network(
                url,
                headers: headers,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPreviewPlayerState extends State<_VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _usedFallback = false;

  @override
  void initState() {
    super.initState();
    _initializeWithUrl(widget.streamUrl);
  }

  Future<void> _initializeWithUrl(String url) async {
    _controller?.dispose();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: widget.headers,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      await controller.dispose();
      if (!_usedFallback) {
        _usedFallback = true;
        await _initializeWithUrl(widget.fallbackUrl);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_error != null)
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Video preview failed.\n$_error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          )
        else if (c == null || !c.value.isInitialized)
          const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
        else
          AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (c == null) return;
                if (c.value.isPlaying) {
                  c.pause();
                } else {
                  c.play();
                }
                setState(() {});
              },
              icon: Icon(c?.value.isPlaying == true ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              onPressed: () {
                c?.seekTo(Duration.zero);
              },
              icon: const Icon(Icons.replay),
            ),
            const Spacer(),
            IconButton(
              onPressed: (c == null || !c.value.isInitialized)
                  ? null
                  : () async {
                      final currentPosition = c.value.position;
                      final wasPlaying = c.value.isPlaying;
                      if (wasPlaying) {
                        await c.pause();
                      }
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ImmersiveVideoPage(
                            title: widget.title,
                            streamUrl: widget.streamUrl,
                            fallbackUrl: widget.fallbackUrl,
                            headers: widget.headers,
                            initialPosition: currentPosition,
                            autoPlay: wasPlaying,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.fullscreen),
              tooltip: 'Fullscreen',
            ),
          ],
        ),
      ],
    );
  }
}

class _ImmersiveVideoPage extends StatefulWidget {
  final String title;
  final String streamUrl;
  final String fallbackUrl;
  final Map<String, String> headers;
  final Duration initialPosition;
  final bool autoPlay;

  const _ImmersiveVideoPage({
    required this.title,
    required this.streamUrl,
    required this.fallbackUrl,
    required this.headers,
    required this.initialPosition,
    required this.autoPlay,
  });

  @override
  State<_ImmersiveVideoPage> createState() => _ImmersiveVideoPageState();
}

class _ImmersiveVideoPageState extends State<_ImmersiveVideoPage> {
  VideoPlayerController? _controller;
  String? _error;
  bool _usedFallback = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeWithUrl(widget.streamUrl);
  }

  Future<void> _initializeWithUrl(String url) async {
    _controller?.dispose();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: widget.headers,
    );

    try {
      await controller.initialize();
      await controller.seekTo(widget.initialPosition);
      if (widget.autoPlay) {
        await controller.play();
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      await controller.dispose();
      if (!_usedFallback) {
        _usedFallback = true;
        await _initializeWithUrl(widget.fallbackUrl);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Video preview failed.\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : (c == null || !c.value.isInitialized)
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                        onTap: () async {
                          if (c.value.isPlaying) {
                            await c.pause();
                          } else {
                            await c.play();
                          }
                          if (mounted) setState(() {});
                        },
                        child: AspectRatio(
                          aspectRatio: c.value.aspectRatio,
                          child: VideoPlayer(c),
                        ),
                      ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}
