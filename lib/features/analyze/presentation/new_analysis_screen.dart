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
  bool _isLoading = false;
  String _statusMessage = '';
  double _uploadProgress = 0.0;
  double _analysisProgress = 0.0;
  Map<String, dynamic> _liveStats = {};

  Future<void> _pickVideo() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    setState(() {
      _videoFile = video;
      _uploadProgress = 0.0;
      _analysisProgress = 0.0;
      _statusMessage = _videoFile != null ? appLocalizations.selected(_videoFile!.name) : appLocalizations.noVideoSelected;
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

    setState(() {
      _isLoading = true;
      _statusMessage = appLocalizations.uploadingAndAnalyzingVideo;
    });

    try {
      final videoAnalysisService = Provider.of<VideoAnalysisService>(context, listen: false);

      videoAnalysisService.addListener(() {
        if (mounted) {
          setState(() {
            _uploadProgress = videoAnalysisService.uploadProgress;
            _analysisProgress = videoAnalysisService.analysisProgress;
            _statusMessage = videoAnalysisService.status;
            _liveStats = videoAnalysisService.liveStats;
          });
        }
      });

      await videoAnalysisService.uploadAndAnalyzeVideo(
        videoFile: _videoFile!,
        onComplete: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocalizations.videoAnalysisCompleted)),
          );
          setState(() {
            _isLoading = false;
            _statusMessage = appLocalizations.videoAnalysisCompleted;
          });
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocalizations.videoAnalysisFailed(error))),
          );
          setState(() {
            _isLoading = false;
            _statusMessage = appLocalizations.videoAnalysisFailed(error);
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = appLocalizations.errorWithMessage(e.toString());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.errorWithMessage(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            appLocalizations.newAnalysis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
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
            _statusMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_videoFile != null) ...[
            const SizedBox(height: 16),
            Text(
              appLocalizations.selected(_videoFile!.name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 24),
            AnalysisProgressWidget(
              uploadProgress: _uploadProgress,
              analysisProgress: _analysisProgress,
              liveStats: _liveStats,
            ),
          ],
          const SizedBox(height: 32),
          _isLoading
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
  }
}