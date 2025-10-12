import 'package:frontend/models/reunion.dart';
import 'package:frontend/services/api_client.dart';

class ReunionService {
  final ApiClient _apiClient;

  ReunionService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Reunion>> getReunions() async {
    try {
      final responseData = await _apiClient.get('/reunions');
      final List<Reunion> reunions = (responseData as List)
          .map((item) => Reunion.fromJson(item as Map<String, dynamic>))
          .toList();
      return reunions;
    } catch (e) {
      print('Error fetching reunions: $e');
      throw Exception('Failed to load reunions');
    }
  }

  Future<Reunion> createReunion(Reunion reunion) async {
    try {
      final data = {
        'title': reunion.title,
        'date': reunion.date.toIso8601String(),
        'location': reunion.location,
        'icon_name': reunion.iconName,
      };
      final responseData = await _apiClient.post('/reunions', data: data);
      return Reunion.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error creating reunion: $e');
      throw Exception('Failed to create reunion');
    }
  }

  Future<void> deleteReunion(String id) async {
    try {
      await _apiClient.delete('/reunions/$id');
    } catch (e) {
      print('Error deleting reunion: $e');
      throw Exception('Failed to delete reunion');
    }
  }
}
