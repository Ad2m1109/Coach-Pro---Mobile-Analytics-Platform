import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/video_analysis_service.dart';
import 'package:frontend/features/analyze/presentation/widgets/analysis_progress.dart';

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  XFile? _videoFile;

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    setState(() {
      _videoFile = video;
    });
  }

  Future<void> _uploadAndAnalyzeVideo() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.selectVideoFirst)),
      );
      return;
    }

    try {
      final videoAnalysisService = Provider.of<VideoAnalysisService>(context, listen: false);

      await videoAnalysisService.uploadAndAnalyzeVideo(
        videoFile: _videoFile!,
        onComplete: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(appLocalizations.videoAnalysisCompleted)),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(appLocalizations.videoAnalysisFailed(error))),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.errorWithMessage(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Consumer<VideoAnalysisService>(
      builder: (context, service, child) {
        final isAnalyzing = service.isAnalyzing;
        final statusMessage = service.status.isEmpty 
          ? (_videoFile != null ? appLocalizations.selected(_videoFile!.name) : appLocalizations.noVideoSelected)
          : service.status;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  onPressed: () {
                    service.cancelAnalysis();
                  },
                  icon: const Icon(Icons.stop, color: Colors.pink),
                  label: const Text("Stop Analysis", style: TextStyle(color: Colors.pink)),
                ),
              ],
              const SizedBox(height: 32),
              isAnalyzing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _uploadAndAnalyzeVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        appLocalizations.analyze,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}