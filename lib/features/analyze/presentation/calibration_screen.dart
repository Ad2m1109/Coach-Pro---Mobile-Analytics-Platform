import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/services/tracking_profile_service.dart';
import 'package:frontend/models/tracking_profile.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/widgets/custom_card.dart';

class CalibrationScreen extends StatefulWidget {
  final String? matchId;

  const CalibrationScreen({super.key, this.matchId});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  final List<CalibrationPoint> _points = [];
  final List<ROICoordinate> _roiPoints = [];
  Offset? _tempPixelPoint;
  bool _isRoiMode = false;
  
  // Standard pitch dimensions (FIFA)
  final double pitchWidthM = 105.0;
  final double pitchHeightM = 68.0;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final controller = VideoPlayerController.file(File(video.path));
    await controller.initialize();
    
    setState(() {
      _videoFile = video;
      _videoController = controller;
      _points.clear();
    });
  }

  void _handleVideoTap(TapUpDetails details) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPos = details.localPosition;
    
    if (_isRoiMode) {
      setState(() {
        _roiPoints.add(ROICoordinate(
          x: localPos.dx / box.size.width,
          y: localPos.dy / box.size.height,
        ));
      });
      return;
    }

    setState(() {
      _tempPixelPoint = localPos;
    });

    _showPointMappingDialog(localPos);
  }

  void _showPointMappingDialog(Offset pixelPos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Point to Pitch'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              const Text('Click on the top-down pitch to define the location:'),
              const SizedBox(height: 16),
              Expanded(
                child: PitchPicker(
                  onPointSelected: (pitchPos) {
                    setState(() {
                      _points.add(CalibrationPoint(
                        u: pixelPos.dx,
                        v: pixelPos.dy,
                        x: pitchPos.dx * pitchWidthM,
                        y: pitchPos.dy * pitchHeightM,
                      ));
                      _tempPixelPoint = null;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pitch Calibration'),
        actions: [
          if (_points.length >= 4)
            TextButton.icon(
              onPressed: _saveCalibration,
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text('Save Calibration', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
      body: _videoController == null
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomCard(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTapUp: _handleVideoTap,
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                          CustomPaint(
                            painter: CalibrationPainter(
                              points: _points, 
                              roiPoints: _roiPoints,
                              tempPoint: _tempPixelPoint,
                              isRoiMode: _isRoiMode,
                            ),
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: Container(),
                            ),
                          ),
                          _buildVideoControls(),
                          _buildModeToggle(),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _isRoiMode ? _buildRoiList() : _buildPointsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildModeToggle() {
    return Positioned(
      top: 16,
      right: 16,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Points'), icon: Icon(Icons.ads_click)),
          ButtonSegment(value: true, label: Text('ROI Mask'), icon: Icon(Icons.polyline)),
        ],
        selected: {_isRoiMode},
        onSelectionChanged: (set) => setState(() => _isRoiMode = set.first),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No video selected for calibration'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.add),
            label: const Text('Select Reference Video'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black45,
        child: Row(
          children: [
            IconButton(
              icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: () => setState(() => _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play()),
            ),
            Expanded(
              child: VideoProgressIndicator(_videoController!, allowScrubbing: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _points.length,
      itemBuilder: (context, index) {
        final p = _points[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('Pixel: (${p.u.toStringAsFixed(0)}, ${p.v.toStringAsFixed(0)})'),
          subtitle: Text('Pitch: ${p.x.toStringAsFixed(1)}m, ${p.y.toStringAsFixed(1)}m'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => setState(() => _points.removeAt(index)),
          ),
        );
      },
    );
  }

  Widget _buildRoiList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ROI Polygon (${_roiPoints.length} points)', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_roiPoints.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _roiPoints.clear()),
                  icon: const Icon(Icons.clear_all, color: Colors.red),
                  label: const Text('Clear ROI', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text('Tap on the video to draw a polygon masking area.\nThe engine will ignore detections outside this zone.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _saveCalibration() async {
    final service = Provider.of<TrackingProfileService>(context, listen: false);
    
    try {
      final profile = TrackingProfile(
        matchId: widget.matchId,
        name: 'Manual Setup - ${DateTime.now().toLocal()}',
        cameras: [
          CameraConfig(
            label: 'Main Cam',
            videoSource: _videoFile!.path,
            calibration: _points,
            roi: _roiPoints.isNotEmpty ? [ROIZone(points: _roiPoints, label: 'Main ROI')] : [],
          ),
        ],
      );

      await service.createProfile(profile);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibration saved successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save calibration: $e')),
      );
    }
  }
}

class CalibrationPainter extends CustomPainter {
  final List<CalibrationPoint> points;
  final List<ROICoordinate> roiPoints;
  final Offset? tempPoint;
  final bool isRoiMode;

  CalibrationPainter({
    required this.points, 
    required this.roiPoints,
    this.tempPoint,
    this.isRoiMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintPoints(canvas, size);
    _paintRoi(canvas, size);
  }

  void _paintPoints(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRoiMode ? Colors.red.withOpacity(0.3) : Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points.length; i++) {
        final p = points[i];
        canvas.drawCircle(Offset(p.u, p.v), 6, paint);
        
        if (!isRoiMode) {
          textPainter.text = TextSpan(
            text: '${i + 1}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(p.u - 4, p.v - 8));
        }
    }

    if (tempPoint != null && !isRoiMode) {
      canvas.drawCircle(tempPoint!, 8, Paint()..color = Colors.yellow.withOpacity(0.5));
    }
  }

  void _paintRoi(Canvas canvas, Size size) {
    if (roiPoints.isEmpty) return;

    final paint = Paint()
      ..color = isRoiMode ? Colors.blue.withOpacity(0.5) : Colors.blue.withOpacity(0.2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < roiPoints.length; i++) {
      final p = roiPoints[i];
      final pos = Offset(p.x * size.width, p.y * size.height);
      if (i == 0) {
        path.moveTo(pos.dx, pos.dy);
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
      
      // Draw point
      canvas.drawCircle(pos, 4, Paint()..color = Colors.blue);
    }

    if (roiPoints.length > 2) {
      path.close();
      canvas.drawPath(path, fillPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PitchPicker extends StatelessWidget {
  final Function(Offset) onPointSelected;

  const PitchPicker({super.key, required this.onPointSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPos = details.localPosition;
        onPointSelected(Offset(localPos.dx / box.size.width, localPos.dy / box.size.height));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CustomPaint(
          painter: PitchTemplatePainter(),
        ),
      ),
    );
  }
}

class PitchTemplatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Pitch Outline
    canvas.drawRect(Offset.zero & size, paint);
    
    // Halfway Line
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    
    // Center Circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height * 0.15, paint);
    
    // Penalty Areas (Simplified)
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.25, size.width * 0.15, size.height * 0.5), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.85, size.height * 0.25, size.width * 0.15, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
