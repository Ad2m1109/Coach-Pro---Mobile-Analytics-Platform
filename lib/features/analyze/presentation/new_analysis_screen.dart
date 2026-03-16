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

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  static const _pagePadding = EdgeInsets.all(16);
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: 30,
    vertical: 15,
  );

  XFile? _videoFile;
  VideoPlayerController? _videoController;
  String? _lastVideoUrl;
  final ScrollController _segmentScrollController = ScrollController();
  final Map<String, GlobalKey> _segmentKeys = {};

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
    _segmentScrollController.dispose();
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
        final statusMessage = service.status.isEmpty
            ? (_videoFile != null
                ? appLocalizations.selected(_videoFile!.name)
                : appLocalizations.noVideoSelected)
            : service.status;

        return SingleChildScrollView(
          padding: _pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                appLocalizations.newAnalysis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              if (!isAnalyzing)
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: Text(appLocalizations.uploadVideo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: _buttonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    service.backendHealthy ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: service.backendHealthy ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    service.backendHealthy ? 'Analysis service healthy' : 'Analysis service unavailable',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: service.backendHealthy ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
              if (_videoFile != null && !isAnalyzing) ...[
                const SizedBox(height: 16),
                Text(
                  appLocalizations.selected(_videoFile!.name),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (isAnalyzing || service.analysisCompleted) ...[
                const SizedBox(height: 24),
                AnalysisProgressWidget(
                  uploadProgress: service.uploadProgress,
                  analysisProgress: service.analysisProgress,
                  liveStats: service.liveStats,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Segments processed: ${service.segments.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'LLM recommendations shown in each segment card',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (service.analysisCompleted) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      '✅ Analysis completed successfully.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (service.isAnalyzing) ...[
                  TextButton.icon(
                    onPressed: service.isCanceling ? null : service.cancelAnalysis,
                    icon: const Icon(Icons.stop, color: Colors.pink),
                    label: Text(
                      service.isCanceling ? 'Stopping...' : 'Stop Analysis',
                      style: const TextStyle(color: Colors.pink),
                    ),
                  ),
                ] else if (service.analysisCompleted) ...[
                  ElevatedButton.icon(
                    onPressed: service.isRetrying
                        ? null
                        : () async {
                            try {
                              await service.retryAnalysis(
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
                          },
                    icon: const Icon(Icons.refresh),
                    label: Text(service.isRetrying ? 'Retrying...' : 'Retry Analysis'),
                  ),
                ],
              ],
              
              const SizedBox(height: 32),
              
              if (isAnalyzing && service.originalVideoUrl != null) ...[
                _buildVideoPlayer(service.originalVideoUrl!),
                const SizedBox(height: 24),
                _buildSegmentsHeader(appLocalizations),
                _buildSegmentsList(service),
                const SizedBox(height: 32),
              ],

              if (!isAnalyzing && service.originalVideoUrl != null) ...[
                 _buildVideoPlayer(service.originalVideoUrl!),
                 const SizedBox(height: 24),
                 _buildSegmentsHeader(appLocalizations),
                 _buildSegmentsList(service),
                 const SizedBox(height: 32),
              ],

              if (!isAnalyzing)
                ElevatedButton(
                  onPressed: _uploadAndAnalyzeVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    appLocalizations.analyze,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
              
              if (isAnalyzing) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appLocalizations.liveNotes,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_comment, color: Colors.blue),
                      onPressed: () => _showAddLiveNoteDialog(appLocalizations),
                      tooltip: appLocalizations.addLiveReaction,
                    ),
                  ],
                ),
                _buildLiveNotesList(appLocalizations),
              ],
            ],
          ),
        );
      },
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

  Widget _buildPartTimeline(VideoAnalysisService service) {
    final sorted = [...service.segments];
    sorted.sort((a, b) => a.segmentIndex.compareTo(b.segmentIndex));
    if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }

    final processingSegment = sorted.firstWhere(
      (segment) {
        final s = segment.status.toUpperCase();
        return s == 'PROCESSING' || s == 'STREAMING' || s == 'RECEIVING';
      },
      orElse: () => sorted.last,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Part Timeline',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...sorted.map((segment) {
              final part = segment.segmentIndex + 1;
              String status = segment.status.toUpperCase();
              if (status.isEmpty) status = 'PENDING';
              IconData icon;
              Color iconColor;
              String label;
              switch (status) {
                case 'COMPLETED':
                  icon = Icons.check_circle;
                  iconColor = Colors.green;
                  label = 'COMPLETED';
                  break;
                case 'PROCESSING':
                case 'STREAMING':
                case 'RECEIVING':
                  icon = Icons.autorenew;
                  iconColor = Colors.orange;
                  label = 'PROCESSING';
                  break;
                case 'FAILED':
                  icon = Icons.error;
                  iconColor = Colors.red;
                  label = 'FAILED';
                  break;
                case 'QUEUED':
                case 'PENDING':
                default:
                  icon = Icons.hourglass_top;
                  iconColor = Colors.grey[700]!;
                  label = 'PENDING';
                  break;
              }

              final isActive = segment.id == processingSegment.id;
              final rowColor = isActive ? Colors.indigo.withOpacity(0.08) : Colors.transparent;

              return InkWell(
                onTap: () => _scrollToSegment(segment.id),
                child: Container(
                  color: rowColor,
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: iconColor),
                          const SizedBox(width: 8),
                          Text(
                            'Part $part',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.indigo[900] : null,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _scrollToSegment(String segmentId) {
    final key = _segmentKeys[segmentId];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  Widget _buildSegmentsHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  l10n.analysisSegments,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                ),
              ],
            ),
            if (context.read<VideoAnalysisService>().isAnalyzing)
              const Chip(
                avatar: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                label: Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.red,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentsList(VideoAnalysisService service) {
    final segments = service.segments;
    final isAnalyzing = service.isAnalyzing;
    
    // Simple heuristic for total segments: duration / window (default 60s)
    // We can refine this if needed, but for now, showing a generic "Processing" state.
    
    return Column(
      children: [
        _buildPartTimeline(service),
        if (isAnalyzing) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.indigo.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ListView.builder(
          controller: _segmentScrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          itemCount: segments.length + (isAnalyzing ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == segments.length) {
              return _buildSkeletonCard();
            }
            final segment = segments[index];
            _segmentKeys[segment.id] = _segmentKeys[segment.id] ?? GlobalKey();
            return Container(
              key: _segmentKeys[segment.id],
              child: SegmentCard(
                segment: segment,
                onPlay: () => _seekTo(segment.videoStartSec),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                dense: true,
                title: Text(note.content),
                subtitle: Text(
                  '${note.noteType.displayName} • ${DateFormat.Hm().format(note.createdAt)}',
                  style: const TextStyle(fontSize: 10),
                ),
                leading: const Icon(
                  Icons.bolt,
                  color: Colors.orange,
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
