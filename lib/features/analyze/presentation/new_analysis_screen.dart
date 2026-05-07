import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/video_analysis_service.dart';
import 'package:frontend/features/analyze/presentation/widgets/analysis_progress.dart';
import 'package:frontend/features/analyze/presentation/widgets/segment_card.dart';
import 'package:frontend/services/note_service.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/features/analyze/presentation/widgets/analysis_timeline.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/models/match_note.dart';
import 'package:frontend/widgets/common_widgets.dart';
import 'package:frontend/core/design_system/widgets/premium_app_bar.dart';

class _LiveChartMetric {
  final String label;
  final double value;
  final Color color;
  _LiveChartMetric(this.label, this.value, this.color);
}

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {

  XFile? _videoFile;
  XFile? _videoFile2;
  VideoPlayerController? _videoController;
  String? _lastVideoUrl;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _segmentKeys = {};
  bool _showMiniPlayer = false;
  String? _activeSegmentId;

  double _detectionThreshold = 0.5;
  double _ballThreshold = 0.3;
  int _maxLostFrames = 15;
  bool _enableReid = false;
  
  String _targetTeam = "Both";
  int _cameraCount = 1;
  String _cameraType = "TV";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    // Show mini player when main video player area is scrolled away (roughly > 300px)
    final threshold = 400.0;
    if (_scrollController.offset > threshold && !_showMiniPlayer) {
      setState(() => _showMiniPlayer = true);
    } else if (_scrollController.offset <= threshold && _showMiniPlayer) {
      setState(() => _showMiniPlayer = false);
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (!mounted) return;
    setState(() => _videoFile = video);
  }

  Future<void> _pickVideo2() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (!mounted) return;
    setState(() => _videoFile2 = video);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Analysis'),
        content: const Text('Are you sure you want to cancel the current analysis? Progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = context.read<VideoAnalysisService>();
      await service.cancelAnalysis();
      _showMessage('Analysis cancelled');
    }
  }

  Future<void> _uploadAndAnalyzeVideo() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_videoFile == null) {
      _showMessage(appLocalizations.selectVideoFirst);
      return;
    }
    if (_cameraCount == 2 && _videoFile2 == null) {
      _showMessage("Please select the second camera source before proceeding.");
      return;
    }

    try {
      final videoAnalysisService = context.read<VideoAnalysisService>();

      await videoAnalysisService.uploadAndAnalyzeVideo(
        videoFile: _videoFile!,
        videoFile2: _videoFile2,
        detectionThreshold: _detectionThreshold,
        ballThreshold: _ballThreshold,
        maxLostFrames: _maxLostFrames,
        enableReid: _enableReid,
        targetTeam: _targetTeam,
        cameraCount: _cameraCount,
        cameraType: _cameraType,
        onComplete: () {
          _showMessage(appLocalizations.videoAnalysisCompleted);
        },
        onError: (error) {
          _showMessage(appLocalizations.videoAnalysisFailed(error));
        },
      );
    } catch (e) {
      _showMessage(appLocalizations.errorWithMessage(e.toString()));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializePlayer(String url) {
    if (_lastVideoUrl == url) return;
    _lastVideoUrl = url;
    
    _videoController?.dispose();
    final analysisService = context.read<AnalysisService>();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: analysisService.fileHeaders(),
    )
      ..initialize().then((_) {
        setState(() {});
      });
  }

  void _seekTo(double seconds) {
    _videoController?.seekTo(Duration(milliseconds: (seconds * 1000).toInt()));
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Consumer<VideoAnalysisService>(
      builder: (context, service, child) {
        final isAnalyzing = service.isAnalyzing;
        
        return Stack(
          children: [
            Container(color: Theme.of(context).scaffoldBackgroundColor),
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: PremiumAppBar(
                    title: appLocalizations.newAnalysis,
                    actions: [
                      if (isAnalyzing)
                        IconButton(
                          onPressed: () => _showCancelDialog(),
                          icon: const Icon(Icons.cancel_outlined),
                          tooltip: 'Cancel Analysis',
                        ),
                      IconButton(
                        icon: Icon(Icons.help_outline,
                            color: Theme.of(context).colorScheme.primary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                // Show video player - tracking video during analysis, original otherwise
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        // Video player first
                        if (service.trackingVideoUrl != null)
                          _buildVideoPlayer(service.trackingVideoUrl!)
                        else if (service.originalVideoUrl != null)
                          _buildVideoPlayer(service.originalVideoUrl!),
                        // Progress bar (only when tracking video not yet available during analysis)
                        if (isAnalyzing && service.trackingVideoUrl == null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.m),
                            child: AnalysisProgressWidget(
                              uploadProgress: service.uploadProgress,
                              analysisProgress: service.analysisProgress,
                              liveStats: service.liveStats,
                            ),
                          ),
                        
                        // LIVE TACTICAL FEED (Real-time segment results)
                        if (isAnalyzing || service.segments.isNotEmpty)
                          _buildLiveTacticalFeed(service),

                        // Control section (only when not analyzing and no results yet)
                        if (!isAnalyzing && service.segments.isEmpty) ...[
                          const SizedBox(height: AppSpacing.m),
                          CustomCard(
                            child: _buildControlSection(service, appLocalizations),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Removed duplicate segment list slivers as they are now in the Feed

                // Always show progress during analysis
                if (isAnalyzing)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        children: [
                          _buildHealthMonitor(service),
                          const SizedBox(height: AppSpacing.m),
                          _buildLiveStatsChart(service.liveStats),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            
            if (_showMiniPlayer && (service.trackingVideoUrl ?? service.originalVideoUrl) != null)
              _buildFloatingMiniPlayer(service.trackingVideoUrl ?? service.originalVideoUrl!),
          ],
        );
      },
    );
  }



  Widget _buildControlSection(VideoAnalysisService service, AppLocalizations l10n) {
    return Column(
      children: [
        if (!service.isAnalyzing)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _videoFile != null ? 'READY TO ANALYZE' : 'SELECT SOURCE${_cameraCount == 2 ? " 1" : ""}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _videoFile != null ? _videoFile!.name : 'No video selected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  IconButton.filledTonal(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (_cameraCount == 2) ...[
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _videoFile2 != null ? 'SOURCE 2 READY' : 'SELECT SOURCE 2',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _videoFile2 != null ? _videoFile2!.name : 'No video selected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    IconButton.filledTonal(
                      onPressed: _pickVideo2,
                      icon: const Icon(Icons.video_library),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: service.isAnalyzing ? null : _uploadAndAnalyzeVideo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM)),
            ),
            child: service.isAnalyzing 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    const SizedBox(width: AppSpacing.s),
                    Text('ANALYSIS IN PROGRESS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                )
              : Text('START TACTICAL ANALYSIS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
        if (_videoFile != null && !service.isAnalyzing) ...[
          const SizedBox(height: AppSpacing.m),
          _buildCameraConfig(),
        ],
        const SizedBox(height: AppSpacing.m),
        _buildEngineSettings(),
        if (service.isAnalyzing) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: service.cancelAnalysis,
            icon: const Icon(Icons.stop_circle_outlined, size: 18, color: Colors.red),
            label: const Text('ABORT PROCESS', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildEngineSettings() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'ANALYSIS CONFIGURATION',
              color: AppColors.info,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'AI Target Focus',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "Both", label: Text("Both")),
                ButtonSegment(value: "Team A", label: Text("Team A")),
                ButtonSegment(value: "Team B", label: Text("Team B")),
              ],
              selected: {_targetTeam},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _targetTeam = newSelection.first;
                });
              },
            ),
            const SizedBox(height: AppSpacing.m),
            const SectionHeader(
              title: 'ENGINE TUNING',
              color: AppColors.info,
            ),
            const SizedBox(height: AppSpacing.s),
            _buildSliderRow(
              label: 'General Detection Threshold',
              value: _detectionThreshold,
              onChanged: (v) => setState(() => _detectionThreshold = v),
              min: 0.1,
              max: 0.9,
            ),
            _buildSliderRow(
              label: 'Ball-Specific Confidence',
              value: _ballThreshold,
              onChanged: (v) => setState(() => _ballThreshold = v),
              min: 0.05,
              max: 0.8,
            ),
            _buildSliderRow(
              label: 'Track Persistence (frames)',
              value: _maxLostFrames.toDouble(),
              onChanged: (v) => setState(() => _maxLostFrames = v.toInt()),
              min: 5,
              max: 60,
              isInteger: true,
            ),
            const Divider(height: AppSpacing.l),
            SwitchListTile(
              title: Text(
                'Enable Player Re-Identification',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Use deep learning models (BoT-SORT/OsNet) to maintain player IDs despite severe occlusions. Slower but more accurate.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGreyLight),
              ),
              value: _enableReid,
              onChanged: (val) {
                setState(() => _enableReid = val);
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_enableReid)
               Padding(
                 padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
                 child: Row(
                   children: [
                     Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                     const SizedBox(width: AppSpacing.xs),
                     Expanded(child: Text(
                       "Requires significantly more GPU memory.",
                       style: TextStyle(color: AppColors.warning, fontSize: 12),
                     )),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraConfig() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'CAMERA CONFIGURATION',
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Number of Cameras',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text("1 Camera")),
                ButtonSegment(value: 2, label: Text("2 Cameras")),
              ],
              selected: {_cameraCount},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _cameraCount = newSelection.first;
                });
              },
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Camera Type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "Fixed", label: Text("Fixed Camera")),
                ButtonSegment(value: "TV", label: Text("TV / Moving Camera")),
              ],
              selected: {_cameraType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _cameraType = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMonitor(VideoAnalysisService service) {
    if (service.liveStats == null) return const SizedBox.shrink();

    final trackingRate = double.tryParse((service.liveStats!['players_detected'] ?? '0').toString()) ?? 0;
    final bool isHealthy = trackingRate > 10;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'SYSTEM HEALTH',
              color: AppColors.info,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isHealthy ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isHealthy ? Icons.check_circle : Icons.warning_amber,
                           color: isHealthy ? AppColors.success : AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(isHealthy ? 'OPTIMAL' : 'LOW VISIBILITY',
                           style: Theme.of(context).textTheme.labelSmall?.copyWith(
                             color: isHealthy ? AppColors.success : AppColors.warning,
                             fontWeight: FontWeight.bold,
                           )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            LinearProgressIndicator(
              value: isHealthy ? 1.0 : 0.4,
              backgroundColor: AppColors.greyLight.withOpacity(0.2),
              color: isHealthy ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Confidence: ${isHealthy ? "High" : "Degraded"} (Players: ${trackingRate.toInt()})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGreyLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    bool isInteger = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(isInteger ? value.toInt().toString() : value.toStringAsFixed(2),
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.info)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: isInteger ? (max - min).toInt() : 20,
        ),
      ],
    );
  }

  Widget _buildFloatingMiniPlayer(String url) {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 10,
      child: GestureDetector(
        onTap: () {
           _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 160,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  VideoPlayer(_videoController!),
                  Container(color: Colors.black26),
                  const Center(child: Icon(Icons.fullscreen, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveNotesSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.liveNotes,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            IconButton(
              icon: Icon(Icons.add_comment, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _showAddLiveNoteDialog(l10n),
            ),
          ],
        ),
        _buildLiveNotesList(l10n),
      ],
    );
  }

  Widget _buildVideoPlayer(String url) {
    _initializePlayer(url);
    
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildLiveTacticalFeed(VideoAnalysisService service) {
    final segments = service.segments;
    final total = service.totalSegments;
    final currentCount = segments.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'LIVE TACTICAL FEED',
                  color: AppColors.primary,
                ),
                Text(
                  service.isAnalyzing ? 'Processing Real-time Intelligence' : 'Match Analysis Results',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGreyLight),
                ),
              ],
            ),
            if (service.isAnalyzing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SEGMENT ${currentCount + 1}${total > 0 ? "/$total" : ""}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        
        // Horizontal Timeline if segments exist
        if (segments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: AnalysisTimeline(
              segments: segments,
              activeSegmentId: _activeSegmentId,
              isAnalyzing: service.isAnalyzing,
              onSegmentTap: (segment) {
                setState(() => _activeSegmentId = segment.id);
                _scrollToSegment(segment.id);
                _seekTo(segment.videoStartSec);
              },
            ),
          ),

        // The Results List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: service.isAnalyzing && total > currentCount ? total : currentCount,
          itemBuilder: (context, index) {
            // Newest segments at the top (reverse of chronological if we want streaming feel)
            // Actually, segments are already inserted at 0 in service.
            
            if (index < currentCount) {
              final segment = segments[index];
              _segmentKeys[segment.id] = _segmentKeys[segment.id] ?? GlobalKey();
              return Container(
                key: _segmentKeys[segment.id],
                padding: const EdgeInsets.only(bottom: 12),
                child: SegmentCard(
                  segment: segment,
                  onPlay: () {
                    setState(() => _activeSegmentId = segment.id);
                    _seekTo(segment.videoStartSec);
                  },
                ),
              );
            } else if (service.isAnalyzing) {
              // Show placeholders for future segments
              return _buildSegmentPlaceholder(index);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSegmentPlaceholder(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'AWAITING',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSegment(String segmentId) {
    _scrollController.animateTo(
      _scrollController.offset + 100, // Minimal move to trigger mini-player logic or generic scroll
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    final key = _segmentKeys[segmentId];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2, // Focus it near the top but below the sticky header
    );
  }


  Widget _buildSkeletonCard() {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusS),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusS),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatsChart(Map<String, dynamic> liveStats) {
    final stats = liveStats ?? {};
    if (stats.isEmpty) {
      return CustomCard(
        child: Column(
          children: [
            Icon(Icons.analytics, size: 40, color: Theme.of(context).hintColor),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Waiting for tactical data...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textGreyLight),
            ),
          ],
        ),
      );
    }

    // Calculate aggregates for the 5 tactical metrics
    double totalDefLine = 0, totalWidth = 0, totalCompact = 0, totalSpeed = 0;
    int pressingCount = 0, playerCount = 0;
    for (var rawStats in stats.values) {
      if (rawStats is! Map) continue;
      final s = Map<String, dynamic>.from(rawStats);
      totalDefLine += (s['defensive_line'] as num?)?.toDouble() ?? 0;
      totalWidth += (s['width'] as num?)?.toDouble() ?? 0;
      totalCompact += (s['compactness'] as num?)?.toDouble() ?? 0;
      totalSpeed += (s['avg_speed'] as num?)?.toDouble() ?? 0;
      pressingCount += (s['pressing_intensity'] as num?)?.toInt() ?? 0;
      playerCount++;
    }

    if (playerCount == 0) {
      return CustomCard(
        child: Center(
          child: Text(
            'Processing player tracking...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textGreyLight),
          ),
        ),
      );
    }

    final avgDefLine = totalDefLine / playerCount;
    final avgWidth = totalWidth / playerCount;
    final avgCompact = totalCompact / playerCount;
    final avgSpeed = totalSpeed / playerCount;

    final metrics = [
      _LiveChartMetric('Def Line', avgDefLine, AppColors.error),
      _LiveChartMetric('Width', avgWidth, AppColors.info),
      _LiveChartMetric('Compact', avgCompact, AppColors.success),
      _LiveChartMetric('Speed', avgSpeed, AppColors.warning),
      _LiveChartMetric('Press', pressingCount.toDouble(), AppColors.secondary),
    ];

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.s),
              Text(
                'LIVE TACTICAL METRICS',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < metrics.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              metrics[value.toInt()].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: metrics.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: e.value.color,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNotesList(AppLocalizations appLocalizations) {
    final videoAnalysisService = context.read<VideoAnalysisService>();
    final matchId = videoAnalysisService.currentMatchId;

    if (matchId == null) return const SizedBox();

    return FutureBuilder<List<MatchNote>>(
      future: context.read<NoteService>().getMatchNotes(matchId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              appLocalizations.noNotesAvailable,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          );
        }
        final notes = snapshot.data!
            .where((n) => n.noteType == NoteType.liveReaction)
            .toList();
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return CustomCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.s),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(note.content),
                subtitle: Text(
                  '${note.noteType.displayName} • ${DateFormat.Hm().format(note.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
                leading: Icon(
                  Icons.bolt,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddLiveNoteDialog(AppLocalizations appLocalizations) async {
    final videoAnalysisService = context.read<VideoAnalysisService>();
    final matchId = videoAnalysisService.currentMatchId;
    if (matchId == null) return;

    final contentController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appLocalizations.addLiveReaction),
        content: TextField(
          controller: contentController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: appLocalizations.enterNoteContent,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appLocalizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (contentController.text.trim().isEmpty) return;

              final noteService = context.read<NoteService>();
              try {
                final newNote = MatchNote(
                  id: '',
                  matchId: matchId,
                  userId: '',
                  content: contentController.text.trim(),
                  noteType: NoteType.liveReaction,
                  videoTimestamp: 0.0,
                  createdAt: DateTime.now(),
                );
                await noteService.createNote(newNote);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                setState(() {});
              } catch (e) {
                _showMessage(appLocalizations.failedToCreateNote(e.toString()));
              }
            },
            child: Text(appLocalizations.saveNote),
          ),
        ],
      ),
    );
    contentController.dispose();
  }
}

class _SliverTimelineDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTimelineDelegate({required this.child});

  @override
  double get minExtent => 120;
  @override
  double get maxExtent => 120;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverTimelineDelegate oldDelegate) {
    return false;
  }
}
