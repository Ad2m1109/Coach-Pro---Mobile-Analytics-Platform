import 'package:frontend/services/api_client.dart';

/// Response from the /assistant/query endpoint.
class AssistantResponse {
  final String answer;
  final String status;

  AssistantResponse({required this.answer, required this.status});

  bool get isAnalysisMode => status == 'analysis_mode';

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'ok';

    // When in analysis_mode, the text comes from 'message'; otherwise from 'answer'.
    final text = status == 'analysis_mode'
        ? (json['message'] as String? ?? 'Assistant is currently unavailable.')
        : (json['answer'] as String? ?? '');

    return AssistantResponse(answer: text, status: status);
  }
}

/// Service responsible for communicating with the AI assistant backend.
class AssistantService {
  final ApiClient _apiClient;

  AssistantService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Sends a [question] to the backend and returns the parsed response.
  Future<AssistantResponse> query(String question) async {
    try {
      final data = await _apiClient.post(
        '/assistant/query',
        data: {'question': question},
      );
      return AssistantResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to reach the assistant: $e');
    }
  }
}
