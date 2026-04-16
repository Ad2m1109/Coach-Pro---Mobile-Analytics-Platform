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
import 'package:frontend/features/analyze/presentation/widgets/attribute_evolution_chart.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/core/design_system/app_typography.dart';
import 'package:frontend/core/design_system/app_colors.dart';

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
  int _lastSyncedIndex = -1;

  VideoPlayerController? _controller;
  Future<void>? _initVideoFuture;
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.removeListener(_syncSegmentToVideo);
    _controller?.dispose();
    _timelineScrollController.dispose();
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
          (outputs['tracking_video_path'] as String?) ??
          widget.report.inputVideoPath;

      if (relativeVideoPath != null && relativeVideoPath.isNotEmpty) {
        final url = analysisService.streamUrl(relativeVideoPath);
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(url),
          httpHeaders: analysisService.fileHeaders(),
        );
        _initVideoFuture = _controller!.initialize().then((_) {
          _controller!.addListener(_syncSegmentToVideo);
        });
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
    
    // Update state first for immediate UI response
    setState(() {
      _selected = index;
      _lastSyncedIndex = index;
    });

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final seg = _segments[index];
    
    // Seek video - listener will trigger but _lastSyncedIndex guard will prevent double setState
    await controller.seekTo(Duration(seconds: seg.startSec.round()));
  }

  void _syncSegmentToVideo() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _segments.isEmpty) return;

    final double position = controller.value.position.inSeconds.toDouble();
    
    // Check if current position is still within current segment to avoid unnecessary search
    if (_lastSyncedIndex != -1 && 
        _lastSyncedIndex < _segments.length &&
        position >= _segments[_lastSyncedIndex].startSec && 
        position <= _segments[_lastSyncedIndex].endSec) {
      return;
    }

    // Find new segment
    final int newIndex = _segments.indexWhere((s) => position >= s.startSec && position <= s.endSec);

    if (newIndex != -1 && newIndex != _selected) {
      setState(() {
        _selected = newIndex;
        _lastSyncedIndex = newIndex;
      });
      _scrollToSegment(newIndex);
    }
  }

  void _scrollToSegment(int index) {
    if (!_timelineScrollController.hasClients) return;
    
    // Approximate item width (padding + content)
    const double itemWidth = 100.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    _timelineScrollController.animateTo(
      targetOffset.clamp(0, _timelineScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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
              controller: _timelineScrollController,
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
        
        AttributeEvolutionChart(
          segments: _segments,
          selectedIndex: _selected,
          onSeek: (secs) {
            final idx = _segments.indexWhere((s) => s.startSec == secs);
            if (idx != -1) _selectSegment(idx);
          },
        ),

        const SizedBox(height: 24),

        if (selectedSeg != null) ...[
          _buildTacticalCommandCenter(selectedSeg, teamData),
        ],
      ],
    );
  }

  Widget _buildTacticalCommandCenter(AnalysisSegment segment, Map<String, dynamic> teamData) {
    final bool hasNarrative = segment.segmentIndex % 3 == 0;
    final List<Map<String, dynamic>> tags = _focusedTeam == 'team_a' ? segment.teamATags : segment.teamBTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Team Selection
        Center(
          child: Column(
            children: [
              Text(
                'TACTICAL COMMAND CENTER',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Live Intelligence Feed',
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5),
              ),
              const SizedBox(height: 16),
              _buildTeamSwitcher(),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Tactical Status Board (5 Monitoring Channels)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
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
              _buildStatusReadout('PRESSING SYSTEM', _getTagForCategory(tags, 'PRESSING')),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Intelligence Report Card (Narrative)
        if (hasNarrative)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 12),
                      const Text(
                        'STRATEGIC INTELLIGENCE BRIEFING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('AI GEN', style: TextStyle(color: Colors.amberAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBriefHeader('CORE OBSERVATIONS'),
                      const SizedBox(height: 8),
                      Text(
                        segment.tacticalNarrative,
                        style: const TextStyle(height: 1.6, fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      _buildBriefHeader('PROPOSED ADJUSTMENTS'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb, size: 14, color: Colors.amberAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                segment.recommendation?.trim().isNotEmpty == true
                                    ? segment.recommendation!.trim()
                                    : 'Optimize defensive compactness to minimize vertical gaps.',
                                style: const TextStyle(
                                  height: 1.5,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05), style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white10, size: 24),
                  const SizedBox(height: 12),
                  const Text(
                    'Awaiting next deep analysis cycle...\nDeep briefings occur every 3 match phases.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBriefHeader(String title) {
    return Row(
      children: [
        Container(width: 2, height: 10, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.7),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusReadout(String label, Map<String, dynamic>? tagData) {
    final bool hasComment = tagData != null;
    final String tagText = (tagData?['tag'] ?? 'STABLE SYSTEM').toString().toUpperCase();
    final String comment = tagData?['description'] ?? 'Monitoring... No significant feedback detected.';
    
    // Determine color based on tag severity or type
    Color color = Colors.white24;
    if (hasComment) {
      bool isWarning = tagText.contains('VULNERABLE') || 
                       tagText.contains('STRETCHED') || 
                       tagText.contains('GAPS') ||
                       tagText.contains('FAIL');
      color = isWarning ? AppColors.secondary : AppColors.primary;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
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
                  color: hasComment ? color : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment,
                style: TextStyle(
                  color: hasComment ? Colors.white70 : Colors.white10,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (hasComment)
          Icon(Icons.report_problem_outlined, size: 12, color: color.withOpacity(0.5))
        else
          Icon(Icons.check_circle_outline, size: 12, color: Colors.white10),
      ],
    );
  }

  Map<String, dynamic>? _getTagForCategory(List<Map<String, dynamic>> tags, String category) {
    final patterns = {
      'DEFENSIVE_LINE': ['LINE', 'DEPTH', 'OFFSIDE'],
      'WIDTH': ['WIDTH', 'WIDE', 'STRETCHED'],
      'COMPACTNESS': ['COMPACT', 'GAPS', 'DISCONNECTED'],
      'SPEED': ['SPEED', 'TRANSITION', 'FAST', 'SLOW'],
      'PRESSING': ['PRESS', 'CLOSE', 'INTENSITY'],
    };
    
    final categoryPatterns = patterns[category] ?? [];
    try {
      return tags.firstWhere(
        (tag) {
          final name = (tag['tag'] ?? '').toString().toUpperCase();
          return categoryPatterns.any((p) => name.contains(p));
        },
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildTagChip(Map<String, dynamic> tagData) {
    final String tag = tagData['tag'] ?? 'UNKNOWN';
    final String description = tagData['description'] ?? '';

    bool isWarning = tag.contains('VULNERABLE') ||
        tag.contains('OVER-STRETCHED') ||
        tag.contains('DISCONNECTED') ||
        tag.contains('LOOSE') ||
        tag.contains('FAIL');
    
    Color color = isWarning ? AppColors.secondary : AppColors.primary;

    return Tooltip(
      message: description,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          tag,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTeamSwitcher() {
    return Container(
      width: 130, // Fixed width for equal tab sizing
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
}
