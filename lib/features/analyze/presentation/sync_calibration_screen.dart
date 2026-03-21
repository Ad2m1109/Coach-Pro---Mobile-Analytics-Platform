import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/models/tracking_profile.dart';
import 'package:frontend/services/tracking_profile_service.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/widgets/custom_card.dart';

class SyncCalibrationScreen extends StatefulWidget {
  final String? matchId;

  const SyncCalibrationScreen({super.key, this.matchId});

  @override
  State<SyncCalibrationScreen> createState() => _SyncCalibrationScreenState();
}

class _SyncCalibrationScreenState extends State<SyncCalibrationScreen> {
  VideoPlayerController? _controller1;
  VideoPlayerController? _controller2;
  XFile? _video1;
  XFile? _video2;
  
  int _syncOffsetMs = 0; // Offset of video 2 relative to video 1

  @override
  void dispose() {
    _controller1?.dispose();
    _controller2?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(int index) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final controller = VideoPlayerController.file(File(video.path));
    await controller.initialize();
    
    setState(() {
      if (index == 1) {
        _video1 = video;
        _controller1 = controller;
      } else {
        _video2 = video;
        _controller2 = controller;
      }
    });
  }

  void _onSyncOffsetChanged(double value) {
    setState(() {
      _syncOffsetMs = value.toInt();
    });
    _synchronizeVideos();
  }

  void _synchronizeVideos() {
    if (_controller1 == null || _controller2 == null) return;
    
    final pos1 = _controller1!.value.position;
    final targetPos2 = Duration(milliseconds: pos1.inMilliseconds + _syncOffsetMs);
    
    if (targetPos2 >= Duration.zero && targetPos2 <= _controller2!.value.duration) {
      _controller2!.seekTo(targetPos2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Camera Sync'),
        actions: [
          if (_video1 != null && _video2 != null)
            TextButton.icon(
              onPressed: _saveSyncData,
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text('Save Sync', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                   Expanded(child: _buildVideoPlayer(1, _controller1, _video1)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildVideoPlayer(2, _controller2, _video2)),
                ],
              ),
            ),
            if (_controller1 != null && _controller2 != null) ...[
              const SizedBox(height: 24),
              _buildSyncControls(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(int index, VideoPlayerController? controller, XFile? video) {
    return CustomCard(
      child: Column(
        children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Camera $index', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: video == null 
                ? Center(
                    child: IconButton(
                      icon: const Icon(Icons.add_a_photo, size: 48),
                      onPressed: () => _pickVideo(index),
                    ),
                  )
                : Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                        AspectRatio(
                          aspectRatio: controller!.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                        VideoProgressIndicator(controller, allowScrubbing: true),
                    ],
                  ),
            ),
            if (video != null)
              IconButton(
                icon: Icon(controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  });
                },
              ),
        ],
      ),
    );
  }

  Widget _buildSyncControls() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Sync Offset (Cam 2 vs Cam 1)'),
                 Text('${_syncOffsetMs}ms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
               ],
             ),
             Slider(
               min: -10000,
               max: 10000,
               value: _syncOffsetMs.toDouble(),
               onChanged: _onSyncOffsetChanged,
             ),
             const Text('Align common events (like kickoff or a whistle)'),
          ],
        ),
      ),
    );
  }

  void _saveSyncData() async {
    final service = Provider.of<TrackingProfileService>(context, listen: false);
    
    try {
      final profile = TrackingProfile(
        matchId: widget.matchId,
        name: 'Multi-Cam Sync - ${DateTime.now().toLocal()}',
        cameras: [
          CameraConfig(
            label: 'Main Cam',
            videoSource: _video1!.path,
            syncOffsetMs: 0,
          ),
          CameraConfig(
            label: 'Side Cam',
            videoSource: _video2!.path,
            syncOffsetMs: _syncOffsetMs,
          ),
        ],
      );

      await service.createProfile(profile);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync profile saved successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save sync profile: $e')),
      );
    }
  }
}
