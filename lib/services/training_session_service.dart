import 'package:flutter/foundation.dart';
import 'package:frontend/models/training_session.dart';
import 'package:frontend/services/api_client.dart';

class TrainingSessionService {
  final ApiClient _apiClient;

  TrainingSessionService({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<List<TrainingSession>> getTrainingSessions() async {
    try {
      final responseData = await _apiClient.get('/training_sessions');
      if (responseData is List) {
        return responseData
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (item) =>
                  TrainingSession.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching training sessions: $e');
      throw Exception('Failed to load training sessions');
    }
  }

  Future<TrainingSession> createTrainingSession(TrainingSession session) async {
    try {
      final data = {
        'title': session.title,
        'date': session.date.toIso8601String(),
        'focus': session.focus,
        'icon_name': session.iconName,
      };
      final responseData = await _apiClient.post(
        '/training_sessions',
        data: data,
      );
      if (responseData is Map) {
        return TrainingSession.fromJson(
          Map<String, dynamic>.from(responseData),
        );
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('Error creating training session: $e');
      throw Exception('Failed to create training session');
    }
  }

  Future<void> deleteTrainingSession(String id) async {
    try {
      await _apiClient.delete('/training_sessions/$id');
    } catch (e) {
      debugPrint('Error deleting training session: $e');
      throw Exception('Failed to delete training session');
    }
  }
}
