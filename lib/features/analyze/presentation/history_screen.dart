import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/features/analyze/presentation/analysis_preview_screen.dart';
import 'package:frontend/features/analyze/presentation/widgets/segment_card.dart';
import 'package:frontend/features/analyze/presentation/widgets/premium_video_player.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final AnalysisService _analysisService;
  final Map<String, bool> _expanded = {};
  final Map<String, List<AnalysisSegment>> _runSegments = {};
  final Map<String, bool> _segmentsLoading = {};
  final Map<String, VideoPlayerController?> _controllers = {};
  final Map<String, Future<void>?> _initFutures = {};
  final Map<String, int> _selectedSegmentIndices = {};
  final Map<String, String> _selectedTeams = {};
  Future<void> _deleteRun(String id) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      await _analysisService.deleteAnalysisRun(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analysis item deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.errorWithMessage(e.toString()))),
      );
    }
  }

  Future<void> _ensureSegments(String reportId) async {
    if (_runSegments.containsKey(reportId)) return;
    _segmentsLoading[reportId] = true;
    setState(() {});

    final raw = await _analysisService.getSegmentsForAnalysis(reportId);
    final segments = raw.map((e) {
      if (e is Map<String, dynamic>) {
        return AnalysisSegment.fromJson(e);
      }
      return null;
    }).whereType<AnalysisSegment>().toList();

    _runSegments[reportId] = segments;
    _segmentsLoading[reportId] = false;
    setState(() {});
  }

  Widget _buildMiniTimeline(String reportId, List<AnalysisSegment> segments) {
    if (segments.isEmpty) {
      return const Text('No part timeline available yet.');
    }
    final sorted = [...segments]..sort((a, b) => a.segmentIndex.compareTo(b.segmentIndex));
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: sorted.map((segment) {
        final status = segment.status.toUpperCase();
        Color color;
        if (status == 'COMPLETED') {
          color = Colors.green;
        } else if (status == 'FAILED') {
          color = Colors.red;
        } else if (status == 'PROCESSING' || status == 'STREAMING' || status == 'RECEIVING') {
          color = Colors.orange;
        } else {
          color = Colors.grey;
        }
        return GestureDetector(
          onTap: () async {
            setState(() {
              _selectedSegmentIndices[reportId] = sorted.indexOf(segment);
            });
            final controller = _controllers[reportId];
            if (controller != null && controller.value.isInitialized) {
              await controller.seekTo(Duration(seconds: segment.startSec.round()));
              controller.play();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(_selectedSegmentIndices[reportId] == sorted.indexOf(segment) ? 0.4 : 0.15),
              border: Border.all(color: color, width: _selectedSegmentIndices[reportId] == sorted.indexOf(segment) ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'P${segment.segmentIndex + 1}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFocusedTelemetry(String reportId, AnalysisSegment segment) {
    final analysis = segment.analysisJson ?? {};
    final selectedTeam = _selectedTeams[reportId] ?? 'team_a';
    final teamData = analysis[selectedTeam] ?? {};
    
    final defLine = teamData['defensive_line'] ?? 0.0;
    final width = teamData['width'] ?? 0.0;
    final compactness = teamData['compactness'] ?? 0.0;
    final avgSpeed = teamData['avg_speed'] ?? 0.0;
    final pressing = teamData['pressing_intensity'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology, color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TACTICAL MASTERCLASS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        'Segment #${segment.segmentIndex + 1} • Analytics HUD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTeamSelector(reportId, selectedTeam),
                const SizedBox(width: 12),
                _buildSeverityBadge(segment.severityLabel),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // 5 Variables Grid
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DETERMINISTIC METRICS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildEliteMetric(Icons.straighten, 'Def Line', '${defLine.toStringAsFixed(1)}m')),
                    Expanded(child: _buildEliteMetric(Icons.swap_horizontal_circle, 'Width', '${width.toStringAsFixed(1)}m')),
                    Expanded(child: _buildEliteMetric(Icons.compress, 'Compact', '${compactness.toStringAsFixed(1)}m')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildEliteMetric(Icons.speed, 'Avg Speed', '${avgSpeed.toStringAsFixed(1)} m/s')),
                    Expanded(child: _buildEliteMetric(Icons.bolt, 'Pressing', '$pressing actions')),
                  ],
                ),
              ],
            ),
          ),

          if (segment.recommendation != null && segment.recommendation!.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 1),
            // AI Recommendation
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'ELITE STRATEGIC ADVISORY',
                        style: TextStyle(
                          color: Colors.amberAccent.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TACTICAL CASE DESCRIPTION',
                    style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    segment.tacticalNarrative,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'STRATEGIC HINTS',
                    style: TextStyle(color: Colors.amberAccent.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    segment.recommendation!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSelector(String reportId, String selectedTeam) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTeamTab(reportId, 'team_a', 'TEAM A', selectedTeam == 'team_a'),
          _buildTeamTab(reportId, 'team_b', 'TEAM B', selectedTeam == 'team_b'),
        ],
      ),
    );
  }

  Widget _buildTeamTab(String reportId, String teamKey, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTeams[reportId] = teamKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent.withOpacity(0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEliteMetric(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBadge(String label) {
    Color color;
    switch (label.toUpperCase()) {
      case 'CRITICAL': color = Colors.red; break;
      case 'HIGH': color = Colors.orange; break;
      case 'MEDIUM': color = Colors.amber; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _analysisService = context.read<AnalysisService>();
    _analysisService.getAnalysisHistory();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(appLocalizations.history),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AnalysisService>(
      builder: (context, analysisService, child) {
        if (analysisService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (analysisService.errorMessage != null) {
          return Center(
            child: Text(
              appLocalizations.errorWithMessage(analysisService.errorMessage!),
            ),
          );
        }
        if (analysisService.reports.isEmpty) {
          return Center(child: Text(appLocalizations.noAnalysisHistoryFound));
        }

        final reports = analysisService.reports;
        return ListView.builder(
          itemCount: reports.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final report = reports[index];
            final expanded = _expanded[report.id] ?? false;
            final segmentList = _runSegments[report.id] ?? [];
            final highSeverityCount = segmentList.where((s) => s.severityLabel.toUpperCase() == 'HIGH' || s.severityLabel.toUpperCase() == 'CRITICAL').length;
            final segmentCount = segmentList.length;

            return Dismissible(
              key: ValueKey(report.id),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(appLocalizations.confirmDeletion),
                    content: Text(appLocalizations.thisActionCannotBeUndone),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(appLocalizations.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(appLocalizations.delete),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => _deleteRun(report.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(report.inputVideoName ?? 'Analysis ${report.id.substring(0, 6)}'),
                      subtitle: Text(
                        'Created: ${report.submittedAt != null ? report.submittedAt!.toLocal().toString().split('.')[0] : 'unknown'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(report.status.toUpperCase()),
                            backgroundColor: report.status.toUpperCase() == 'COMPLETED'
                                ? Colors.green[100]
                                : report.status.toUpperCase() == 'FAILED'
                                    ? Colors.red[100]
                                    : Colors.orange[100],
                          ),
                          IconButton(
                            tooltip: expanded ? 'Collapse' : 'Expand',
                            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                            onPressed: () async {
                              final wasExpanded = expanded;
                              setState(() {
                                _expanded[report.id] = !wasExpanded;
                              });

                              if (!wasExpanded) {
                                // Expanding
                                await _ensureSegments(report.id);
                                final videoUrl = report.outputs?['output_video'] ?? 
                                               report.outputs?['original_video'];
                                if (videoUrl != null && _controllers[report.id] == null) {
                                  final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
                                  _controllers[report.id] = controller;
                                  _initFutures[report.id] = controller.initialize().then((_) => setState(() {}));
                                }
                              } else {
                                // Collapsing - optionally dispose or keep for performance
                                // We'll keep it for now but pause
                                _controllers[report.id]?.pause();
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnalysisPreviewScreen(report: report),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('Segments: ${report.outputs?['segments_count'] ?? segmentCount}'),
                          const SizedBox(width: 16),
                          Text('High Alerts: $highSeverityCount'),
                          const Spacer(),
                          Text('Progress: ${(report.progress * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildMiniTimeline(report.id, segmentList),
                    ),
                    if (expanded) ...[
                      const Divider(),
                      if (_controllers[report.id] != null) 
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              PremiumVideoPlayer(
                                controller: _controllers[report.id]!,
                                autoPlay: false,
                              ),
                              const SizedBox(height: 16),
                              if (segmentList.isNotEmpty)
                                _buildFocusedTelemetry(
                                  report.id,
                                  segmentList[_selectedSegmentIndices[report.id] ?? 0],
                                ),
                            ],
                          ),
                        ),
                      if (_segmentsLoading[report.id] ?? false)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (segmentList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No segment details available yet.'),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Column(
                            children: segmentList.map((segment) {
                              return SegmentCard(
                                segment: segment,
                                onPlay: () async {
                                  setState(() {
                                    _selectedSegmentIndices[report.id] = segmentList.indexOf(segment);
                                  });
                                  final controller = _controllers[report.id];
                                  if (controller != null && controller.value.isInitialized) {
                                    await controller.seekTo(Duration(seconds: segment.startSec.round()));
                                    controller.play();
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
    );
  }
}
