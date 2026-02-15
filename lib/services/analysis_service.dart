import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/services/api_client.dart'; // Import the new ApiClient
import 'dart:convert';

class AnalysisService with ChangeNotifier {
  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;
  List<AnalysisReport> _reports = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AnalysisReport> get reports => _reports;

  AnalysisService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> getAnalysisHistory() async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final dynamic responseData = await _apiClient.get('/analysis_history');
      _reports = (responseData as List)
          .map((item) => AnalysisReport.fromJson(item as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = 'API Error: ${e.message}';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String fileUrl(String relativePath) {
    final encodedPath = Uri.encodeQueryComponent(relativePath);
    final token = _apiClient.token;
    final encodedToken = token != null ? Uri.encodeQueryComponent(token) : '';
    return '${_apiClient.baseUrl}/analysis/files?path=$encodedPath&access_token=$encodedToken';
  }

  String streamUrl(String relativePath) {
    final encodedPath = Uri.encodeQueryComponent(relativePath);
    final token = _apiClient.token;
    final encodedToken = token != null ? Uri.encodeQueryComponent(token) : '';
    return '${_apiClient.baseUrl}/analysis/stream?path=$encodedPath&access_token=$encodedToken';
  }

  Map<String, String> fileHeaders() {
    final token = _apiClient.token;
    if (token == null || token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  Future<dynamic> fetchJsonPreview(String relativePath) async {
    final encodedPath = Uri.encodeQueryComponent(relativePath);
    final token = _apiClient.token;
    final encodedToken = token != null ? Uri.encodeQueryComponent(token) : '';
    return _apiClient.get('/analysis/files/json?path=$encodedPath&access_token=$encodedToken');
  }

  String prettyJson(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<void> deleteAnalysisRun(String analysisId) async {
    await _apiClient.delete('/analysis_history/$analysisId');
    _reports.removeWhere((r) => r.id == analysisId);
    notifyListeners();
  }
}
