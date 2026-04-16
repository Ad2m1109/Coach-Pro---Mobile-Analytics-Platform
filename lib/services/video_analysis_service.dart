import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/analysis_segment.dart';

class VideoAnalysisService extends ChangeNotifier {
  final ApiClient _apiClient;
  
  bool _isAnalyzing = false;
  bool _analysisCompleted = false;
  double _uploadProgress = 0.0;
  double _analysisProgress = 0.0;
  String _status = '';
  String? _lastError;
  bool _backendHealthy = true;
  Map<String, dynamic> _liveStats = {};
  String? _currentMatchId;
  String? _analysisId;
  String? _originalVideoUrl;
  bool _isCanceling = false;
  bool _isRetrying = false;
  List<AnalysisSegment> _segments = [];
  StreamSubscription? _sseSubscription;
  
  bool get isAnalyzing => _isAnalyzing;
  bool get analysisCompleted => _analysisCompleted;
  bool get isCanceling => _isCanceling;
  bool get isRetrying => _isRetrying;
  bool get backendHealthy => _backendHealthy;
  double get uploadProgress => _uploadProgress;
  double get analysisProgress => _analysisProgress;
  String get status => _status;
  String? get lastError => _lastError;
  Map<String, dynamic> get liveStats => _liveStats;
  String? get currentMatchId => _currentMatchId;
  String? get analysisId => _analysisId;
  String? get originalVideoUrl => _originalVideoUrl;
  List<AnalysisSegment> get segments => _segments;

  VideoAnalysisService({required ApiClient apiClient}) : _apiClient = apiClient;

  void _updateState({
    bool? isAnalyzing,
    bool? analysisCompleted,
    double? uploadProgress,
    double? analysisProgress,
    String? status,
    String? error,
    Map<String, dynamic>? liveStats,
  }) {
    if (isAnalyzing != null) _isAnalyzing = isAnalyzing;
    if (analysisCompleted != null) _analysisCompleted = analysisCompleted;
    if (uploadProgress != null) _uploadProgress = uploadProgress;
    if (analysisProgress != null) _analysisProgress = analysisProgress;
    if (status != null) _status = status;
    if (error != null) _lastError = error;
    if (liveStats != null) _liveStats = liveStats;
    notifyListeners();
  }

  Future<void> uploadAndAnalyzeVideo({
    required XFile videoFile,
    XFile? videoFile2,
    required double detectionThreshold,
    required double ballThreshold,
    required int maxLostFrames,
    required bool enableReid,
    required String targetTeam,
    required int cameraCount,
    required String cameraType,
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
      _currentMatchId = null;

      final uri = Uri.parse('${_apiClient.baseUrl}/analyze_match');
      final request = http.MultipartRequest('POST', uri);
      final videoLength = await videoFile.length();

      request.fields['confidence_threshold'] = detectionThreshold.toString();
      request.fields['ball_confidence'] = ballThreshold.toString();
      request.fields['max_lost_frames'] = maxLostFrames.toString();
      request.fields['enable_reid'] = enableReid.toString();
      request.fields['target_team'] = targetTeam;
      request.fields['camera_count'] = cameraCount.toString();
      request.fields['camera_type'] = cameraType;

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
        trackedStream.cast<List<int>>(),
        videoLength,
        filename: videoFile.name,
      );
      request.files.add(multipartFile);

      if (videoFile2 != null) {
        final videoLength2 = await videoFile2.length();
        final multipartFile2 = http.MultipartFile(
          'file2',
          videoFile2.openRead().cast<List<int>>(),
          videoLength2,
          filename: videoFile2.name,
        );
        request.files.add(multipartFile2);
      }

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
        final analysisId = responseData['analysis_id'] ?? responseData['match_id'] ?? '';
        _analysisId = analysisId;
        _currentMatchId = responseData['match_id'] ?? analysisId;
        _originalVideoUrl = responseData['video_path'] != null 
            ? '${_apiClient.baseUrl}/analysis/files?path=${Uri.encodeQueryComponent(responseData['video_path'])}'
            : null;
        
        _segments = [];
        notifyListeners();

        if (analysisId.isNotEmpty) {
          _startSseListenerForAnalysis(analysisId);
        }

        await _runAnalysisStatusLoop(analysisId);
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
    
    _stopSseListener();
    _updateState(isAnalyzing: false);
  }

  Future<void> _runAnalysisStatusLoop(String analysisId) async {
    bool isComplete = false;
    while (!isComplete && _isAnalyzing) {
      await Future.delayed(const Duration(seconds: 1));

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
              liveStats: (statusData['live_stats'] as Map<String, dynamic>?) ?? _liveStats,
            );
          }

          final status = (statusData['status'] as String? ?? '').toUpperCase();
          switch (status) {
            case 'COMPLETED':
              isComplete = true;
              _updateState(
                analysisCompleted: true,
                analysisProgress: 1.0,
                status: 'Analysis complete',
              );
              break;
            case 'FAILED':
              throw Exception(statusData['message'] ?? statusData['error'] ?? 'Analysis failed');
            case 'QUEUED':
            case 'PENDING':
              _updateState(status: 'Analysis queued...');
              break;
            case 'PROCESSING':
            case 'STREAMING':
            case 'RECEIVING':
              _updateState(status: 'Analyzing video...');
              break;
            default:
              break;
          }
        } else {
          throw Exception('Failed to get analysis status: ${response.statusCode}');
        }
      } catch (e) {
        if (!_isAnalyzing) break;
        debugPrint('Error polling analysis status: $e');
        _backendHealthy = false;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  void _startSseListenerForAnalysis(String analysisId) async {
    _stopSseListener();

    final uri = Uri.parse(
      '${_apiClient.baseUrl}/analysis/$analysisId/segments/stream',
    );

    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers.addAll(await _apiClient.getAuthHeaders());

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        debugPrint('SSE Connection failed: ${response.statusCode}');
        return;
      }

      _sseSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          try {
            final payload = json.decode(data);
            if (payload['type'] == 'segment' || payload['status'] == 'SEGMENT_DONE') {
              final segment = AnalysisSegment.fromJson(payload);
              _segments.insert(0, segment); // Newest first
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error parsing SSE segment: $e');
          }
        } else if (line.startsWith('event: done')) {
          _updateState(
            analysisCompleted: true,
            status: 'Analysis complete',
          );
          _stopSseListener();
        }
      }, onError: (e) {
        debugPrint('SSE Error: $e');
        _stopSseListener();
      }, onDone: () {
        _stopSseListener();
      });
    } catch (e) {
      debugPrint('Error starting SSE: $e');
    }
  }

  void _stopSseListener() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
  }

  Future<void> fetchMatchSegments(String matchId) async {
    try {
      final response = await _apiClient.get('/matches/$matchId/segments');
      if (response != null && response['segments'] != null) {
        _segments = (response['segments'] as List)
            .map((s) => AnalysisSegment.fromJson(s))
            .toList()
            .reversed // Newest first
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching segments: $e');
    }
  }

  Future<void> cancelAnalysis() async {
    if (_analysisId == null || _analysisId!.isEmpty) {
      _updateState(status: 'No analysis to cancel.');
      return;
    }

    _isCanceling = true;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/analysis/${_analysisId!}/cancel',
        data: {},
      );
      if (response != null && response['status'] == 'cancelled') {
        _updateState(
          isAnalyzing: false,
          status: 'Analysis cancelled',
          analysisCompleted: false,
        );
      } else {
        _updateState(status: 'Cancel request failed.');
      }
    } catch (e) {
      _updateState(status: 'Cancel failed: ${e.toString()}');
    } finally {
      _isCanceling = false;
      notifyListeners();
    }
  }

  Future<void> retryAnalysis({required VoidCallback onComplete, required void Function(String) onError}) async {
    if (_analysisId == null || _analysisId!.isEmpty) {
      onError('No previous analysis to retry.');
      return;
    }

    _isRetrying = true;
    _updateState(
      isAnalyzing: true,
      analysisCompleted: false,
      analysisProgress: 0.0,
      status: 'Retrying analysis...',
      liveStats: {},
    );

    try {
      final response = await _apiClient.post('/analysis/${_analysisId!}/retry', data: {});
      if (response == null || response['analysis_id'] == null) {
        throw Exception('Retry response missing analysis_id');
      }

      final newAnalysisId = response['analysis_id'] as String;
      final matchId = response['match_id'] as String? ?? _currentMatchId;
      _analysisId = newAnalysisId;
      _currentMatchId = matchId;
      _segments = [];
      notifyListeners();

      _startSseListenerForAnalysis(newAnalysisId);

      await _runAnalysisStatusLoop(newAnalysisId);
      if (_analysisCompleted) onComplete();
    } catch (e) {
      final errorMsg = e.toString();
      _updateState(
        isAnalyzing: false,
        status: 'Retry failed: $errorMsg',
      );
      onError(errorMsg);
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }
}
