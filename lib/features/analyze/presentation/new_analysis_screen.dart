import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/video_analysis_service.dart';
import 'package:frontend/features/analyze/presentation/widgets/analysis_progress.dart';
import 'package:frontend/features/analyze/presentation/widgets/segment_card.dart';
import 'package:frontend/models/match_note.dart';
import 'package:frontend/services/note_service.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:frontend/features/analyze/presentation/widgets/analysis_timeline.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/features/analyze/presentation/calibration_screen.dart';
import 'package:frontend/features/analyze/presentation/sync_calibration_screen.dart';

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {

  XFile? _videoFile;
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _uploadAndAnalyzeVideo() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_videoFile == null) {
      _showMessage(appLocalizations.selectVideoFirst);
      return;
    }

    try {
      final videoAnalysisService = context.read<VideoAnalysisService>();

      await videoAnalysisService.uploadAndAnalyzeVideo(
        videoFile: _videoFile!,
        detectionThreshold: _detectionThreshold,
        ballThreshold: _ballThreshold,
        maxLostFrames: _maxLostFrames,
        enableReid: _enableReid,
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
                _buildSliverAppBar(appLocalizations),
                
                if (!isAnalyzing)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        children: [
                          CustomCard(
                            child: _buildControlSection(service, appLocalizations),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          if (service.originalVideoUrl != null)
                            _buildVideoPlayer(service.originalVideoUrl!),
                        ],
                      ),
                    ),
                  ),

                if (service.segments.isNotEmpty || isAnalyzing)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTimelineDelegate(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                        child: AnalysisTimeline(
                          segments: service.segments,
                          activeSegmentId: _activeSegmentId,
                          isAnalyzing: isAnalyzing,
                          onSegmentTap: (segment) {
                            setState(() => _activeSegmentId = segment.id);
                            _scrollToSegment(segment.id);
                            _seekTo(segment.videoStartSec);
                          },
                        ),
                      ),
                    ),
                  ),

                if (isAnalyzing || service.analysisCompleted)
                  SliverToBoxAdapter(
                    child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: AnalysisProgressWidget(
                      uploadProgress: service.uploadProgress,
                      analysisProgress: service.analysisProgress,
                      liveStats: service.liveStats,
                    ),
                  ),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == service.segments.length) {
                          return isAnalyzing ? _buildSkeletonCard() : const SizedBox.shrink();
                        }
                        final segment = service.segments[index];
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
                      },
                      childCount: service.segments.length + (isAnalyzing ? 1 : 0),
                    ),
                  ),
                ),

                if (isAnalyzing)
                  SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: _buildLiveNotesSection(appLocalizations),
                  ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            
            if (_showMiniPlayer && service.originalVideoUrl != null)
              _buildFloatingMiniPlayer(service.originalVideoUrl!),
          ],
        );
      },
    );
  }

  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Text(
        l10n.newAnalysis,
        style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
          onPressed: () {},
        ),
      ],
    );
  }


  Widget _buildControlSection(VideoAnalysisService service, AppLocalizations l10n) {
    return Column(
      children: [
        if (!service.isAnalyzing)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _videoFile != null ? 'READY TO ANALYZE' : 'SELECT SOURCE',
                      style: TextStyle(
                        fontSize: 10,
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: AppSpacing.s),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalibrationScreen(matchId: service.currentMatchId),
                ),
              );
            },
            icon: const Icon(Icons.architecture),
            label: const Text('CALIBRATE PITCH PRECISION'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM)),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        _buildEngineSettings(),
        if (_videoFile != null && !service.isAnalyzing) ...[
          const SizedBox(height: AppSpacing.s),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SyncCalibrationScreen(matchId: service.currentMatchId),
                ),
              );
            },
            icon: const Icon(Icons.sync),
            label: const Text('SYNC MULTI-CAMERA SOURCES'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM)),
              side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ENGINE TUNING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: Colors.blue)),
            const SizedBox(height: 16),
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
            const Divider(height: 32),
            SwitchListTile(
              title: const Text('Enable Player Re-Identification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Use deep learning models (BoT-SORT/OsNet) to maintain player IDs despite severe occlusions. Slower but more accurate.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _enableReid,
              onChanged: (val) {
                setState(() => _enableReid = val);
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_enableReid)
               const Padding(
                 padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                 child: Row(
                   children: [
                     Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                     SizedBox(width: 8),
                     Expanded(child: Text("Requires significantly more GPU memory.", style: TextStyle(color: Colors.orange, fontSize: 12))),
                   ],
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMonitor(VideoAnalysisService service) {
    if (service.liveStats == null) return const SizedBox.shrink();
    
    // Determine health status based on tracking rate
    final trackingRate = double.tryParse((service.liveStats!['players_detected'] ?? '0').toString()) ?? 0;
    final bool isHealthy = trackingRate > 10; // Simple heuristic

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('SYSTEM HEALTH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: Colors.blue)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHealthy ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(isHealthy ? Icons.check_circle : Icons.warning_amber, 
                           color: isHealthy ? Colors.green : Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(isHealthy ? 'OPTIMAL' : 'LOW VISIBILITY', 
                           style: TextStyle(color: isHealthy ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: isHealthy ? 1.0 : 0.4,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: isHealthy ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            Text('Confidence: ${isHealthy ? "High" : "Degraded"} (Players: ${trackingRate.toInt()})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(isInteger ? value.toInt().toString() : value.toStringAsFixed(2), 
                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
