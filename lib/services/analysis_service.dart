import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/services/api_client.dart'; // Import the new ApiClient

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
    notifyListeners();

    try {
      final dynamic responseData = await _apiClient.get('/analysis_reports');
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
}
