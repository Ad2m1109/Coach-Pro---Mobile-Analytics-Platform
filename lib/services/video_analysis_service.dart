import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class VideoAnalysisService extends ChangeNotifier {
  final ApiClient _apiClient;
  
  bool _isAnalyzing = false;
  double _uploadProgress = 0.0;
  double _analysisProgress = 0.0;
  String _status = '';
  String? _lastError;
  Map<String, dynamic> _liveStats = {};
  
  bool get isAnalyzing => _isAnalyzing;
  double get uploadProgress => _uploadProgress;
  double get analysisProgress => _analysisProgress;
  String get status => _status;
  String? get lastError => _lastError;
  Map<String, dynamic> get liveStats => _liveStats;

  VideoAnalysisService({required ApiClient apiClient}) : _apiClient = apiClient;

  void _updateState({
    bool? isAnalyzing,
    double? uploadProgress,
    double? analysisProgress,
    String? status,
    String? error,
    Map<String, dynamic>? liveStats,
  }) {
    if (isAnalyzing != null) _isAnalyzing = isAnalyzing;
    if (uploadProgress != null) _uploadProgress = uploadProgress;
    if (analysisProgress != null) _analysisProgress = analysisProgress;
    if (status != null) _status = status;
    if (error != null) _lastError = error;
    if (liveStats != null) _liveStats = liveStats;
    notifyListeners();
  }

  Future<void> uploadAndAnalyzeVideo({
    required XFile videoFile,
    required VoidCallback onComplete,
    required void Function(String) onError,
  }) async {
    try {
      _updateState(
        isAnalyzing: true,
        uploadProgress: 0.0,
        analysisProgress: 0.0,
        status: 'Preparing video upload...',
        liveStats: {},
      );

      final uri = Uri.parse('${_apiClient.baseUrl}/analyze_match');
      final request = http.MultipartRequest('POST', uri);
      final videoLength = await videoFile.length();

      // Add authentication headers
      final authHeaders = await _apiClient.getAuthHeaders();
      request.headers.addAll(authHeaders);

      // Wrap the video stream to track upload progress
      int uploadedBytes = 0;
      final totalBytes = videoLength;
      
      final trackedStream = videoFile.openRead().transform(
        StreamTransformer<Uint8List, Uint8List>.fromHandlers(
          handleData: (data, sink) {
            uploadedBytes += data.length;
            final progress = uploadedBytes / totalBytes.toDouble();
            _updateState(
              uploadProgress: progress,
              status: 'Uploading video: ${(progress * 100).toStringAsFixed(1)}%',
            );
            sink.add(data);
          },
        ),
      );

      final multipartFile = http.MultipartFile(
        'file',
        trackedStream,
        videoLength,
        filename: videoFile.name,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      
      // Collect response body
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = utf8.decode(responseBytes);

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 202) {
        _updateState(
          uploadProgress: 1.0,
          status: 'Upload complete! Initializing analysis...',
        );

        final responseData = json.decode(responseBody);
        
        // Start polling for analysis status
        bool isComplete = false;
        final analysisId = responseData['analysis_id'] ?? responseData['match_id'] ?? '';
        
        while (!isComplete && _isAnalyzing) {
          await Future.delayed(const Duration(seconds: 1)); // Faster polling for real-time
          
          try {
            final response = await http.get(
              Uri.parse('${_apiClient.baseUrl}/analysis_status/$analysisId'),
              headers: await _apiClient.getAuthHeaders(),
            );

            if (response.statusCode == 200) {
              final statusData = json.decode(response.body);
              
              if (statusData['progress'] != null) {
                final progress = (statusData['progress'] as num).toDouble();
                _updateState(
                  analysisProgress: progress,
                  status: 'Analyzing video: ${(progress * 100).toStringAsFixed(1)}%',
                  liveStats: statusData['live_stats'] as Map<String, dynamic>?,
                );
              }

              final status = statusData['status'] as String? ?? '';
              switch (status.toUpperCase()) {
                case 'COMPLETED':
                  isComplete = true;
                  _updateState(
                    analysisProgress: 1.0,
                    status: 'Analysis complete',
                  );
                  onComplete();
                  break;
                case 'FAILED':
                  throw Exception(statusData['message'] ?? statusData['error'] ?? 'Analysis failed');
                case 'QUEUED':
                  _updateState(status: 'Analysis queued...');
                  break;
                case 'PROCESSING':
                case 'STREAMING':
                case 'RECEIVING':
                  // Standardized to PROCESSING, but keeping some legacy for safety
                  break;
                default:
                  // Carry on polling for unknown but active statuses
                  break;
              }
            } else {
              throw Exception('Failed to get analysis status: ${response.statusCode}');
            }
          } catch (e) {
            print('Error polling analysis status: $e');
            if (!_isAnalyzing) break;
            await Future.delayed(const Duration(seconds: 3));
          }
        }
      } else {
        throw Exception('Upload failed with status code: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      final error = e.toString();
      _updateState(
        isAnalyzing: false,
        status: 'Error: $error',
        error: error,
      );
      onError(error);
      return;
    }
    
    _updateState(isAnalyzing: false);
  }

  void cancelAnalysis() {
    _updateState(
      isAnalyzing: false,
      status: 'Analysis cancelled',
    );
  }
}