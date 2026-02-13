import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class VideoUploadWidget extends StatefulWidget {
  final String matchId;
  final void Function(String jobId) onUploadStart;

  const VideoUploadWidget({
    super.key,
    required this.matchId,
    required this.onUploadStart,
  });

  @override
  State<VideoUploadWidget> createState() => _VideoUploadWidgetState();
}

class _VideoUploadWidgetState extends State<VideoUploadWidget> {
  XFile? _selectedVideo;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String _statusMessage = 'No video selected';
  http.Client? _uploadClient;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (!mounted) return;
    setState(() {
      _selectedVideo = video;
      _statusMessage = video == null
          ? 'No video selected'
          : 'Selected: ${video.name}';
    });
  }

  Future<void> _startUpload() async {
    if (_selectedVideo == null || _isUploading) return;

    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final uri = Uri.parse(
      '${apiClient.baseUrl}/matches/${widget.matchId}/analyze',
    );
    final request = http.MultipartRequest('POST', uri);
    final token = apiClient.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _statusMessage = 'Uploading video...';
      });

      final totalBytes = await _selectedVideo!.length();
      int uploadedBytes = 0;

      final Stream<Uint8List> trackedStream = _selectedVideo!
          .openRead()
          .transform(
        StreamTransformer<Uint8List, Uint8List>.fromHandlers(
          handleData: (Uint8List data, EventSink<Uint8List> sink) {
            uploadedBytes += data.length;
            if (mounted) {
              setState(() {
                _uploadProgress = totalBytes == 0
                    ? 0.0
                    : uploadedBytes / totalBytes;
                _statusMessage =
                    'Uploading ${(100 * _uploadProgress).toStringAsFixed(0)}%';
              });
            }
            sink.add(data);
          },
        ),
      );

      request.files.add(
        http.MultipartFile(
          'file',
          trackedStream,
          totalBytes,
          filename: _selectedVideo!.name,
        ),
      );
      request.fields['frame_limit'] = '330';
      request.fields['skip_json'] = 'false';

      _uploadClient = http.Client();
      final response = await _uploadClient!.send(request);
      final bodyBytes = await response.stream.toBytes();
      final body = utf8.decode(bodyBytes);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Upload failed (${response.statusCode}): $body');
      }

      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final jobId = parsed['job_id'] as String?;
      if (jobId == null || jobId.isEmpty) {
        throw Exception('Upload succeeded but no job_id returned');
      }

      if (!mounted) return;
      setState(() {
        _uploadProgress = 1.0;
        _statusMessage = 'Upload complete. Analysis queued.';
      });
      widget.onUploadStart(jobId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Upload error: $e';
      });
    } finally {
      _uploadClient?.close();
      _uploadClient = null;
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _cancelUpload() {
    _uploadClient?.close();
    _uploadClient = null;
    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _statusMessage = 'Upload cancelled';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Select Video'),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 8),
            Text(_statusMessage),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_selectedVideo == null || _isUploading)
                        ? null
                        : _startUpload,
                    child: const Text('Upload and Analyze'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isUploading ? _cancelUpload : null,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
