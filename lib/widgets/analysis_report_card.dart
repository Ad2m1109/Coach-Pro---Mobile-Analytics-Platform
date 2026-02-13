import 'package:flutter/material.dart';
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
    final trackingVideo = outputs['tracking_video_path']?.toString();
    final heatmapVideo = outputs['heatmap_video_path']?.toString();
    final backlineVideo = outputs['backline_video_path']?.toString();
    final animationVideo = outputs['animation_video_path']?.toString();
    final possessionJson = outputs['possession_analysis_path']?.toString();
    final heatmapImage = outputs['heatmap_image_path']?.toString();
    final movementTrailImage = outputs['movement_trail_image_path']?.toString();
    final analysisService = Provider.of<AnalysisService>(context, listen: false);

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
                        url: analysisService.fileUrl(trackingVideo),
                        headers: analysisService.fileHeaders(),
                      ),
                    ),
                  if (heatmapVideo != null && heatmapVideo.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.play_circle,
                      label: 'Heatmap Video',
                      onPressed: () => _showVideoPreview(
                        context,
                        title: 'Heatmap Video',
                        url: analysisService.fileUrl(heatmapVideo),
                        headers: analysisService.fileHeaders(),
                      ),
                    ),
                  if (backlineVideo != null && backlineVideo.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.play_circle,
                      label: 'Backline Video',
                      onPressed: () => _showVideoPreview(
                        context,
                        title: 'Backline Video',
                        url: analysisService.fileUrl(backlineVideo),
                        headers: analysisService.fileHeaders(),
                      ),
                    ),
                  if (animationVideo != null && animationVideo.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.play_circle,
                      label: 'Animation Video',
                      onPressed: () => _showVideoPreview(
                        context,
                        title: 'Animation Video',
                        url: analysisService.fileUrl(animationVideo),
                        headers: analysisService.fileHeaders(),
                      ),
                    ),
                  if (heatmapImage != null && heatmapImage.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.image,
                      label: 'Heatmap Image',
                      onPressed: () => _showImagePreview(
                        context,
                        title: 'Heatmap Image',
                        url: analysisService.fileUrl(heatmapImage),
                        headers: analysisService.fileHeaders(),
                      ),
                    ),
                  if (movementTrailImage != null && movementTrailImage.isNotEmpty)
                    _PreviewButton(
                      icon: Icons.image,
                      label: 'Movement Trail',
                      onPressed: () => _showImagePreview(
                        context,
                        title: 'Movement Trail',
                        url: analysisService.fileUrl(movementTrailImage),
                        headers: analysisService.fileHeaders(),
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
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showVideoPreview(
    BuildContext context, {
    required String title,
    required String url,
    required Map<String, String> headers,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _VideoPreviewPlayer(title: title, url: url, headers: headers),
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
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain, headers: headers),
                ),
              ),
            ],
          ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Possession JSON', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      pretty,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
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

class _VideoPreviewPlayer extends StatefulWidget {
  final String title;
  final String url;
  final Map<String, String> headers;

  const _VideoPreviewPlayer({
    required this.title,
    required this.url,
    required this.headers,
  });

  @override
  State<_VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<_VideoPreviewPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers,
    )
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
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
        if (c == null || !c.value.isInitialized)
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
          ],
        ),
      ],
    );
  }
}
