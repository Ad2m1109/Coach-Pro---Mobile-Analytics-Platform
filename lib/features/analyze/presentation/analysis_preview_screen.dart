import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/features/analyze/presentation/widgets/premium_video_player.dart';
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

      final rawSegments = await analysisService.getSegmentsForAnalysis(
        widget.report.id,
      );
      final segments =
          rawSegments
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (item) =>
                    AnalysisSegment.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
            ..sort((a, b) => a.segmentIndex.compareTo(b.segmentIndex));

      // Pick a playable output (prefer preview if present).
      final outputs = widget.report.outputs ?? const <String, dynamic>{};
      final String? relativeVideoPath =
          (outputs['tracking_video_preview_path'] as String?) ??
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
    if (controller == null ||
        !controller.value.isInitialized ||
        _segments.isEmpty)
      return;

    final double position = controller.value.position.inSeconds.toDouble();

    // Check if current position is still within current segment to avoid unnecessary search
    if (_lastSyncedIndex != -1 &&
        _lastSyncedIndex < _segments.length &&
        position >= _segments[_lastSyncedIndex].startSec &&
        position <= _segments[_lastSyncedIndex].endSec) {
      return;
    }

    // Find new segment
    final int newIndex = _segments.indexWhere(
      (s) => position >= s.startSec && position <= s.endSec,
    );

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
    final double targetOffset =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

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
    final hasVideo = _controller != null && _initVideoFuture != null;

    return Column(
      children: [
        // 1. Video player (fixed at top)
        if (hasVideo)
          FutureBuilder<void>(
            future: _initVideoFuture,
            builder: (context, snap) {
              return PremiumVideoPlayer(controller: _controller!);
            },
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No preview video available for this run.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),

        // 2. Enhanced Timeline (fixed below video)
        _buildEnhancedTimeline(),

        // 3. Scrollable content area (chart + recommendations for current segment)
        Expanded(child: _buildSyncedSegmentContent()),
      ],
    );
  }

  Widget _buildTacticalCommandCenter(
    AnalysisSegment segment,
    Map<String, dynamic> teamData,
  ) {
    final bool hasNarrative = segment.segmentIndex % 3 == 0;
    final List<Map<String, dynamic>> tags = _focusedTeam == 'team_a'
        ? segment.teamATags
        : segment.teamBTags;

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
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
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
                  Icon(
                    Icons.radar,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
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
              _buildStatusReadout(
                'DEFENSIVE LINE',
                _getTagForCategory(tags, 'DEFENSIVE_LINE'),
              ),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout(
                'TEAM WIDTH',
                _getTagForCategory(tags, 'WIDTH'),
              ),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout(
                'COMPACTNESS',
                _getTagForCategory(tags, 'COMPACTNESS'),
              ),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout(
                'TRANSITION SPEED',
                _getTagForCategory(tags, 'SPEED'),
              ),
              const Divider(height: 12, color: Colors.white12),
              _buildStatusReadout(
                'PRESSING SYSTEM',
                _getTagForCategory(tags, 'PRESSING'),
              ),
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
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.amberAccent,
                        size: 16,
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI GEN',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        style: const TextStyle(
                          height: 1.6,
                          fontSize: 13,
                          color: Colors.white70,
                        ),
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
                            const Icon(
                              Icons.lightbulb,
                              size: 14,
                              color: Colors.amberAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                segment.recommendation?.trim().isNotEmpty ==
                                        true
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
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white10, size: 24),
                  const SizedBox(height: 12),
                  const Text(
                    'Awaiting next deep analysis cycle...\nDeep briefings occur every 3 match phases.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 11,
                      height: 1.4,
                    ),
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
    final String tagText = (tagData?['tag'] ?? 'STABLE SYSTEM')
        .toString()
        .toUpperCase();
    final String comment =
        tagData?['description'] ??
        'Monitoring... No significant feedback detected.';

    // Determine color based on tag severity or type
    Color color = Colors.white24;
    if (hasComment) {
      bool isWarning =
          tagText.contains('VULNERABLE') ||
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
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
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
          Icon(
            Icons.report_problem_outlined,
            size: 12,
            color: color.withOpacity(0.5),
          )
        else
          Icon(Icons.check_circle_outline, size: 12, color: Colors.white10),
      ],
    );
  }

  Map<String, dynamic>? _getTagForCategory(
    List<Map<String, dynamic>> tags,
    String category,
  ) {
    final patterns = {
      'DEFENSIVE_LINE': ['LINE', 'DEPTH', 'OFFSIDE'],
      'WIDTH': ['WIDTH', 'WIDE', 'STRETCHED'],
      'COMPACTNESS': ['COMPACT', 'GAPS', 'DISCONNECTED'],
      'SPEED': ['SPEED', 'TRANSITION', 'FAST', 'SLOW'],
      'PRESSING': ['PRESS', 'CLOSE', 'INTENSITY'],
    };

    final categoryPatterns = patterns[category] ?? [];
    try {
      return tags.firstWhere((tag) {
        final name = (tag['tag'] ?? '').toString().toUpperCase();
        return categoryPatterns.any((p) => name.contains(p));
      });
    } catch (_) {
      return null;
    }
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
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
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

  // Enhanced Timeline with visual progress bar and segment markers
  Widget _buildEnhancedTimeline() {
    if (_segments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No segments available for this analysis run yet.'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_segments.length} segments',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Visual timeline with segment markers
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Video progress bar (background)
                if (_controller != null && _controller!.value.isInitialized)
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: VideoProgressColors(
                        playedColor: Theme.of(context).primaryColor,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),

                // Segment markers
                ...List.generate(_segments.length, (i) {
                  final seg = _segments[i];
                  final isSelected = i == _selected;
                  final color = _severityColor(seg.severityLabel);

                  // Calculate position based on segment index (equal spacing)
                  final double position = i / _segments.length;

                  return Positioned(
                    left:
                        16 +
                        (MediaQuery.of(context).size.width - 32) * position,
                    top: 10,
                    child: GestureDetector(
                      onTap: () => _selectSegment(i),
                      child: Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                      ),
                    ),
                  );
                }),

                // Playback head (if video is available)
                if (_controller != null && _controller!.value.isInitialized)
                  AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, _) {
                      final position = _controller!.value.position.inSeconds
                          .toDouble();
                      final duration = _controller!.value.duration.inSeconds
                          .toDouble();
                      if (duration == 0) return const SizedBox.shrink();

                      final progress = position / duration;
                      return Positioned(
                        left:
                            16 +
                            (MediaQuery.of(context).size.width - 32) *
                                progress -
                            6,
                        top: 14,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Synced content area that updates with current segment
  Widget _buildSyncedSegmentContent() {
    if (_segments.isEmpty) return const SizedBox.shrink();

    final currentSeg = _segments[_selected.clamp(0, _segments.length - 1)];
    final Map<String, dynamic> analysis = currentSeg.analysisJson ?? const {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segment header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _severityColor(currentSeg.severityLabel),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_formatTime(currentSeg.startSec)} - ${_formatTime(currentSeg.endSec)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Segment ${currentSeg.segmentIndex + 1}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              // Team switcher
              _buildTeamSwitcher(),
            ],
          ),

          const SizedBox(height: 16),

          // Per-segment chart (5 tactical metrics)
          _buildSegmentMetricsChart(currentSeg),

          const SizedBox(height: 16),

          // Recommendations for current segment
          _buildTacticalCommandCenter(
            currentSeg,
            analysis[_focusedTeam] is Map
                ? Map<String, dynamic>.from(analysis[_focusedTeam])
                : const {},
          ),
        ],
      ),
    );
  }

  // Per-segment bar chart showing 5 tactical metrics
  Widget _buildSegmentMetricsChart(AnalysisSegment seg) {
    final analysis = seg.analysisJson ?? <String, dynamic>{};
    final teamData =
        (_focusedTeam == 'team_a' ? analysis['team_a'] : analysis['team_b']) ??
        <String, dynamic>{};

    final metrics = [
      _ChartData(
        'Def Line',
        (teamData['defensive_line'] ?? 0).toDouble(),
        Colors.red,
      ),
      _ChartData('Width', (teamData['width'] ?? 0).toDouble(), Colors.blue),
      _ChartData(
        'Compact',
        (teamData['compactness'] ?? 0).toDouble(),
        Colors.green,
      ),
      _ChartData(
        'Speed',
        (teamData['avg_speed'] ?? 0).toDouble(),
        Colors.orange,
      ),
      _ChartData(
        'Press',
        (teamData['pressing_intensity'] ?? 0).toDouble(),
        Colors.purple,
      ),
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team ${_focusedTeam == 'team_a' ? 'A' : 'B'} Metrics',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < metrics.length) {
                          return Text(
                            metrics[value.toInt()].label,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: metrics.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: e.value.color,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Chart data class for per-segment metrics
class _ChartData {
  final String label;
  final double value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
