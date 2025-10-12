import 'package:frontend/models/training_session.dart';
import 'package:frontend/services/api_client.dart';

class TrainingSessionService {
  final ApiClient _apiClient;

  TrainingSessionService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<TrainingSession>> getTrainingSessions() async {
    try {
      final responseData = await _apiClient.get('/training_sessions');
      final List<TrainingSession> sessions = (responseData as List)
          .map((item) => TrainingSession.fromJson(item as Map<String, dynamic>))
          .toList();
      return sessions;
    } catch (e) {
      print('Error fetching training sessions: $e');
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
      final responseData = await _apiClient.post('/training_sessions', data: data);
      return TrainingSession.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error creating training session: $e');
      throw Exception('Failed to create training session');
    }
  }

  Future<void> deleteTrainingSession(String id) async {
    try {
      await _apiClient.delete('/training_sessions/$id');
    } catch (e) {
      print('Error deleting training session: $e');
      throw Exception('Failed to delete training session');
    }
  }
}
