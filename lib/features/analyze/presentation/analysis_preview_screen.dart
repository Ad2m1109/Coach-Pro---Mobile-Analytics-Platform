import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/features/analyze/presentation/widgets/premium_video_player.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/core/design_system/widgets/premium_app_bar.dart';

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
        }).catchError((e) {
          print('Video init error: $e');
        });
      }

      if (!mounted) return;
      setState(() {
        _segments = segments;
        _selected = segments.isNotEmpty ? 0 : -1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
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

    // Fixed item width for the horizontal list (card width 120 + 8 margin)
    const double itemWidth = 128.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Center the selected segment in the viewport
    final double targetOffset =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    _timelineScrollController.animateTo(
      targetOffset.clamp(0, _timelineScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: report.inputVideoName ?? 'Analysis Preview',
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

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceSubtle = onSurface.withOpacity(0.38);

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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: onSurface,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Live Intelligence Feed',
                style: TextStyle(
                  color: onSurfaceSubtle,
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
            color: theme.cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.radar,
                    size: 14,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TACTICAL STATUS BOARD',
                    style: TextStyle(
                      color: theme.primaryColor.withOpacity(0.7),
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
              const Divider(height: 12, color: Colors.transparent),
              _buildStatusReadout(
                'TEAM WIDTH',
                _getTagForCategory(tags, 'WIDTH'),
              ),
              const Divider(height: 12, color: Colors.transparent),
              _buildStatusReadout(
                'COMPACTNESS',
                _getTagForCategory(tags, 'COMPACTNESS'),
              ),
              const Divider(height: 12, color: Colors.transparent),
              _buildStatusReadout(
                'TRANSITION SPEED',
                _getTagForCategory(tags, 'SPEED'),
              ),
              const Divider(height: 12, color: Colors.transparent),
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
                  theme.primaryColor.withOpacity(0.1),
                  onSurface.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.15),
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
                    color: theme.primaryColor.withOpacity(0.05),
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
                      Text(
                        'STRATEGIC INTELLIGENCE BRIEFING',
                        style: TextStyle(
                          color: onSurface,
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
                        style: TextStyle(
                          height: 1.6,
                          fontSize: 13,
                          color: onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildBriefHeader('PROPOSED ADJUSTMENTS'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: onSurface.withOpacity(0.03),
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
                                style: TextStyle(
                                  height: 1.5,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface,
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

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceSubtle = onSurface.withOpacity(0.38);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: onSurfaceSubtle,
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
                  color: hasComment ? color : onSurfaceSubtle,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment,
                style: TextStyle(
                  color: hasComment ? onSurface.withOpacity(0.7) : onSurface.withOpacity(0.1),
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
          Icon(Icons.check_circle_outline, size: 12, color: onSurface.withOpacity(0.1)),
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
    final theme = Theme.of(context);
    final isSelected = _focusedTeam == teamKey;
    return GestureDetector(
      onTap: () => setState(() => _focusedTeam = teamKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.38),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Enhanced Timeline: Horizontal scrollable list of segment cards
  Widget _buildEnhancedTimeline() {
    final theme = Theme.of(context);
    if (_segments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No segments available for this analysis run yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'MATCH SEGMENTS',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${_segments.length} PHASES',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.38),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal scrollable segment list
        SizedBox(
          height: 105,
          child: ListView.builder(
            controller: _timelineScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _segments.length,
            itemBuilder: (context, index) {
              return _buildSegmentCard(index);
            },
          ),
        ),
        
        // Mini progress bar indicating overall video position
        if (_controller != null && _controller!.value.isInitialized)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).primaryColor,
                    bufferedColor: Colors.white12,
                    backgroundColor: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSegmentCard(int index) {
    final seg = _segments[index];
    final isSelected = index == _selected;
    final color = _severityColor(seg.severityLabel);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: () => _selectSegment(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.2) 
              : theme.cardColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : onSurface.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PHASE ${seg.segmentIndex + 1}',
              style: TextStyle(
                color: isSelected ? onSurface : onSurface.withOpacity(0.38),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(seg.startSec),
              style: TextStyle(
                color: isSelected ? onSurface : onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                seg.severityLabel.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
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
          _buildHeatmap(currentSeg),

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

  Widget _buildHeatmap(AnalysisSegment segment) {
    if (segment.heatmapPath == null || segment.heatmapPath!.isEmpty) {
      return const SizedBox.shrink();
    }

    final service = context.read<AnalysisService>();
    final heatmapUrl = service.getFileUrl(segment.heatmapPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBriefHeader('TACTICAL SNAPSHOT'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Image.network(
                  heatmapUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white10),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ZONE HEATMAP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
