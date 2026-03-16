import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/features/analyze/presentation/analysis_preview_screen.dart';
import 'package:frontend/features/analyze/presentation/widgets/segment_card.dart';
import 'package:provider/provider.dart';

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

  Widget _buildMiniTimeline(List<AnalysisSegment> segments) {
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'P${segment.segmentIndex + 1}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _analysisService = context.read<AnalysisService>();
    _analysisService.getAnalysisHistory();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Consumer<AnalysisService>(
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
            final isFailed = report.status.toUpperCase() == 'FAILED';
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
                              setState(() {
                                _expanded[report.id] = !expanded;
                              });
                              if (!_runSegments.containsKey(report.id) && !expanded) {
                                await _ensureSegments(report.id);
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
                      child: _buildMiniTimeline(segmentList),
                    ),
                    if (expanded) ...[
                      const Divider(),
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
                                onPlay: () {},
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
    );
  }
}
