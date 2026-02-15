import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/video_analysis_service.dart';
import 'package:frontend/features/analyze/presentation/widgets/analysis_progress.dart';
import 'package:frontend/models/match_note.dart';
import 'package:frontend/services/note_service.dart';
import 'package:intl/intl.dart';

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
              if (isAnalyzing) ...[
                const SizedBox(height: 24),
                AnalysisProgressWidget(
                  uploadProgress: service.uploadProgress,
                  analysisProgress: service.analysisProgress,
                  liveStats: service.liveStats,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: service.cancelAnalysis,
                  icon: const Icon(Icons.stop, color: Colors.pink),
                  label: const Text(
                    'Stop Analysis',
                    style: TextStyle(color: Colors.pink),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              isAnalyzing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
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
                const SizedBox(height: 8),
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
